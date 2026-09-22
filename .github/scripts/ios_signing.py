"""Install reusable App Store signing assets without logging credential contents."""

import base64
import datetime
import fnmatch
import hashlib
import json
import os
import plistlib
import re
import secrets
import shlex
import shutil
import subprocess
import sys
import uuid
from pathlib import Path

from mask_credentials import mask_commands


class SigningError(Exception):
    """A static message that is safe to show in Actions logs."""


def security(arguments, failure):
    try:
        result = subprocess.run(
            ["security", *map(str, arguments)], capture_output=True, check=False
        )
    except OSError:
        raise SigningError(failure) from None
    if result.returncode:
        # security errors can include passwords, certificate names or file data.
        raise SigningError(failure)
    return result.stdout


def decode_secret(name):
    try:
        value = base64.b64decode("".join(os.environ[name].split()), validate=True)
    except (KeyError, ValueError):
        raise SigningError(f"{name} must contain valid base64.") from None
    if not value:
        raise SigningError(f"{name} must not be empty.")
    return value


def permits(allowance, requested):
    allowances = allowance if isinstance(allowance, list) else [allowance]
    requests = requested if isinstance(requested, list) else [requested]
    return all(
        any(
            isinstance(value, str)
            and isinstance(pattern, str)
            and fnmatch.fnmatchcase(value, pattern)
            for pattern in allowances
        )
        for value in requests
    )


def validate_profile(profile, bundle, team, required_entitlements):
    try:
        profile_uuid = profile["UUID"]
        if str(uuid.UUID(profile_uuid)) != profile_uuid.lower():
            raise ValueError
        entitlements = profile["Entitlements"]
        prefixes = profile["ApplicationIdentifierPrefix"]
        expiration = profile["ExpirationDate"]
        if expiration.tzinfo is None:
            expiration = expiration.replace(tzinfo=datetime.timezone.utc)
        valid = (
            isinstance(prefixes, list)
            and entitlements["application-identifier"]
            in [f"{prefix}.{bundle}" for prefix in prefixes]
            and isinstance(profile["TeamIdentifier"], list)
            and team in profile["TeamIdentifier"]
            and entitlements["com.apple.developer.team-identifier"] == team
            and expiration > datetime.datetime.now(datetime.timezone.utc)
            and entitlements.get("get-task-allow") is False
            and "ProvisionedDevices" not in profile
            and not profile.get("ProvisionsAllDevices", False)
        )
        if not valid:
            raise SigningError(
                "Provisioning profile must be an unexpired App Store profile for the configured app and team."
            )
        if not all(
            permits(entitlements.get(key), value)
            for key, value in required_entitlements.items()
        ):
            raise SigningError("Provisioning profile does not allow all Runner entitlements.")
        certificates = profile["DeveloperCertificates"]
        if not certificates or not all(isinstance(cert, bytes) for cert in certificates):
            raise ValueError
        fingerprints = {hashlib.sha1(cert).hexdigest().upper() for cert in certificates}
    except SigningError:
        raise
    except (KeyError, ValueError, TypeError, AttributeError):
        raise SigningError("Provisioning profile metadata is invalid.") from None
    return profile_uuid, fingerprints


def select_identity(output, fingerprints):
    identities = re.findall(
        r'^\s*\d+\) ([0-9A-Fa-f]{40}) "(?:Apple Distribution|iPhone Distribution):[^"\n]*"',
        output.decode("utf-8", errors="replace"),
        re.MULTILINE,
    )
    matches = {identity.upper() for identity in identities} & fingerprints
    if len(matches) != 1:
        raise SigningError(
            "The imported private key and valid distribution certificate must match the provisioning profile."
        )
    return matches.pop()


def write_private(path, content):
    with os.fdopen(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "wb") as stream:
        os.chmod(path, 0o600)
        stream.write(content)


def save_state(directory, state):
    pending = directory / "state.json.tmp"
    write_private(pending, json.dumps(state).encode())
    pending.replace(directory / "state.json")


def prepare():
    bundle = os.environ["IOS_BUNDLE_ID"]
    team = os.environ["APPLE_TEAM_ID"]
    if not re.fullmatch(r"[A-Za-z0-9.-]+", bundle) or not re.fullmatch(r"[A-Z0-9]{10}", team):
        raise SigningError("IOS_BUNDLE_ID or APPLE_TEAM_ID is invalid.")
    certificate = decode_secret("IOS_DISTRIBUTION_CERTIFICATE_BASE64")
    profile_data = decode_secret("IOS_PROVISIONING_PROFILE_BASE64")
    password = os.environ["IOS_DISTRIBUTION_CERTIFICATE_PASSWORD"]
    if not password:
        raise SigningError("IOS_DISTRIBUTION_CERTIFICATE_PASSWORD must not be empty.")
    workspace = Path(os.environ["GITHUB_WORKSPACE"])
    runner_temp = Path(os.environ["RUNNER_TEMP"])
    directory = runner_temp / "ios-signing"
    directory.mkdir(mode=0o700)
    state = {"keychains": None, "profile": None, "configuration": None, "export": None}
    save_state(directory, state)
    certificate_path = directory / "distribution.p12"
    profile_path = directory / "profile.mobileprovision"
    keychain = directory / "signing.keychain-db"
    write_private(certificate_path, certificate)
    write_private(profile_path, profile_data)
    try:
        profile = plistlib.loads(security(["cms", "-D", "-i", profile_path], "Could not decode the provisioning profile."))
        required = plistlib.loads((workspace / "apps/app/ios/Runner/Runner.entitlements").read_bytes())
    except (ValueError, TypeError, OSError, plistlib.InvalidFileException):
        raise SigningError("Could not read provisioning profile or Runner entitlements.") from None
    profile_uuid, fingerprints = validate_profile(profile, bundle, team, required)
    state["keychains"] = shlex.split(
        security(["list-keychains", "-d", "user"], "Could not read the keychain search list.").decode()
    )
    save_state(directory, state)
    keychain_password = secrets.token_urlsafe(32)
    if os.environ.get("GITHUB_ACTIONS") == "true":
        print("\n".join(mask_commands([keychain_password])), flush=True)
    security(["create-keychain", "-p", keychain_password, keychain], "Could not create the temporary signing keychain.")
    security(["set-keychain-settings", "-lut", "21600", keychain], "Could not configure the signing keychain timeout.")
    security(["unlock-keychain", "-p", keychain_password, keychain], "Could not unlock the signing keychain.")
    security(
        ["import", certificate_path, "-k", keychain, "-P", password, "-T", "/usr/bin/codesign", "-T", "/usr/bin/security"],
        "Could not import the distribution certificate and private key. Check the p12 and password Secrets.",
    )
    security(
        ["set-key-partition-list", "-S", "apple-tool:,apple:,codesign:", "-s", "-k", keychain_password, keychain],
        "Could not allow noninteractive code signing.",
    )
    security(["list-keychains", "-d", "user", "-s", keychain, *state["keychains"]], "Could not update the keychain search list.")
    fingerprint = select_identity(
        security(["find-identity", "-v", "-p", "codesigning", keychain], "Could not verify the imported signing identity."),
        fingerprints,
    )
    installed_profile = Path(os.environ["HOME"]) / "Library/Developer/Xcode/UserData/Provisioning Profiles" / f"{profile_uuid}.mobileprovision"
    configuration = workspace / "apps/app/ios/Flutter/Signing.xcconfig"
    export_path = runner_temp / "ExportOptions.plist"
    if any(path.exists() for path in (installed_profile, configuration, export_path)):
        raise SigningError("Temporary signing output already exists; clean up before preparing again.")
    state.update(profile=str(installed_profile), configuration=str(configuration), export=str(export_path))
    save_state(directory, state)
    installed_profile.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    write_private(installed_profile, profile_data)
    write_private(configuration, (
        "// Generated for this CI job; removed by signing cleanup.\n"
        "CODE_SIGN_STYLE[config=Release] = Manual\n"
        f"DEVELOPMENT_TEAM[config=Release] = {team}\n"
        f"CODE_SIGN_IDENTITY[sdk=iphoneos*][config=Release] = {fingerprint}\n"
        f"PROVISIONING_PROFILE_SPECIFIER[config=Release] = {profile_uuid}\n"
    ).encode())
    export = plistlib.loads((workspace / "apps/app/ios/ExportOptions.plist").read_bytes())
    export.update(
        signingStyle="manual", signingCertificate=fingerprint,
        teamID=team, provisioningProfiles={bundle: profile_uuid},
    )
    write_private(export_path, plistlib.dumps(export))
    # These two copies are no longer needed after import and profile installation.
    certificate_path.unlink()
    profile_path.unlink()
    print("Installed and validated reusable App Store signing assets.")


def cleanup():
    directory = Path(os.environ["RUNNER_TEMP"]) / "ios-signing"
    if not directory.exists():
        return
    state_path = directory / "state.json"
    state = json.loads(state_path.read_text()) if state_path.exists() else {}
    failures = []
    if state.get("keychains") is not None:
        try:
            security(["list-keychains", "-d", "user", "-s", *state["keychains"]], "Could not restore the keychain search list.")
        except SigningError as error:
            failures.append(str(error))
    keychain = directory / "signing.keychain-db"
    if keychain.exists():
        try:
            security(["delete-keychain", keychain], "Could not delete the temporary signing keychain.")
        except SigningError as error:
            failures.append(str(error))
    for name in ("profile", "configuration", "export"):
        if state.get(name):
            try:
                Path(state[name]).unlink(missing_ok=True)
            except OSError:
                failures.append("Could not remove a temporary signing file.")
    for name in ("distribution.p12", "profile.mobileprovision"):
        try:
            (directory / name).unlink(missing_ok=True)
        except OSError:
            failures.append("Could not remove a temporary credential file.")
    if failures:
        # Retain only cleanup state and any undeletable keychain for a retry.
        raise SigningError(" ".join(failures))
    shutil.rmtree(directory)


def main():
    try:
        if sys.argv[1:] == ["prepare"]:
            prepare()
        elif sys.argv[1:] == ["cleanup"]:
            cleanup()
        else:
            raise SigningError("Expected prepare or cleanup.")
    except SigningError as error:
        print(f"::error::{error}", file=sys.stderr)
        return 1
    except Exception:
        # Never print exceptions or tracebacks containing input or command data.
        print("::error::Could not complete iOS signing setup or cleanup.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
