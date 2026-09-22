import base64
import contextlib
import datetime
import hashlib
import io
import json
import os
import plistlib
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import ios_signing


CERTIFICATE = b"fixture-distribution-certificate"
FINGERPRINT = hashlib.sha1(CERTIFICATE).hexdigest().upper()
BUNDLE = "jp.flutterkaigi.conf2026.stg"
TEAM = "TEAM123456"
PROFILE_UUID = "84E2DC69-9B7C-4A4A-A2C6-164996F998FC"
REQUIRED = {
    "com.apple.developer.applesignin": ["Default"],
    "com.apple.developer.associated-domains": ["applinks:2026.flutterkaigi.jp"],
    "com.apple.developer.devicecheck.appattest-environment": "production",
}


def profile_fixture():
    return {
        "UUID": PROFILE_UUID,
        "ApplicationIdentifierPrefix": ["PREFIX1234"],
        "TeamIdentifier": [TEAM],
        "ExpirationDate": datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None) + datetime.timedelta(days=30),
        "DeveloperCertificates": [CERTIFICATE],
        "Entitlements": {
            "application-identifier": f"PREFIX1234.{BUNDLE}",
            "com.apple.developer.team-identifier": TEAM,
            "get-task-allow": False,
            "com.apple.developer.applesignin": ["Default"],
            "com.apple.developer.associated-domains": "*",
            "com.apple.developer.devicecheck.appattest-environment": ["development", "production"],
        },
    }


class ProfileValidationTest(unittest.TestCase):
    def test_team_can_differ_from_application_identifier_prefix(self):
        self.assertEqual(
            ios_signing.validate_profile(profile_fixture(), BUNDLE, TEAM, REQUIRED),
            (PROFILE_UUID, {FINGERPRINT}),
        )

    def test_preserves_profile_uuid_casing_for_xcode(self):
        profile = profile_fixture()
        profile["UUID"] = PROFILE_UUID.lower()
        profile_uuid, _ = ios_signing.validate_profile(profile, BUNDLE, TEAM, REQUIRED)
        self.assertEqual(profile_uuid, PROFILE_UUID.lower())

    def test_rejects_wrong_app_team_expired_and_device_profiles(self):
        cases = [
            ("TeamIdentifier", ["OTHER12345"]),
            ("ExpirationDate", datetime.datetime(2000, 1, 1)),
            ("ProvisionedDevices", []),
            ("ProvisionsAllDevices", True),
            ("UUID", "../../outside"),
            ("DeveloperCertificates", ["invalid-certificate"]),
        ]
        for key, value in cases:
            profile = profile_fixture()
            profile[key] = value
            with self.subTest(key=key), self.assertRaises(ios_signing.SigningError):
                ios_signing.validate_profile(profile, BUNDLE, TEAM, REQUIRED)
        for key, value in [
            ("application-identifier", "PREFIX1234.*"),
            ("application-identifier", f"PREFIX1234.{BUNDLE}.other"),
            ("com.apple.developer.team-identifier", "OTHER12345"),
            ("get-task-allow", True),
            ("get-task-allow", None),
        ]:
            profile = profile_fixture()
            profile["Entitlements"][key] = value
            with self.subTest(key=key, value=value), self.assertRaises(ios_signing.SigningError):
                ios_signing.validate_profile(profile, BUNDLE, TEAM, REQUIRED)

    def test_rejects_missing_entitlements_and_development_only_app_attest(self):
        for key in REQUIRED:
            profile = profile_fixture()
            del profile["Entitlements"][key]
            with self.subTest(key=key), self.assertRaises(ios_signing.SigningError):
                ios_signing.validate_profile(profile, BUNDLE, TEAM, REQUIRED)
        profile = profile_fixture()
        profile["Entitlements"]["com.apple.developer.devicecheck.appattest-environment"] = ["development"]
        with self.assertRaises(ios_signing.SigningError):
            ios_signing.validate_profile(profile, BUNDLE, TEAM, REQUIRED)

    def test_entitlement_string_list_and_wildcard_allowances(self):
        for allowed in ("*", ["applinks:*"], ["applinks:2026.flutterkaigi.jp"]):
            self.assertTrue(ios_signing.permits(allowed, REQUIRED["com.apple.developer.associated-domains"]))
        self.assertFalse(ios_signing.permits("applinks:other.example", REQUIRED["com.apple.developer.associated-domains"]))
        self.assertFalse(ios_signing.permits(None, "production"))

    def test_requires_valid_matching_distribution_identity(self):
        valid = f'  1) {FINGERPRINT} "Apple Distribution: Fixture (TEAM123456)"\n  1 valid identities found\n'.encode()
        self.assertEqual(ios_signing.select_identity(valid, {FINGERPRINT}), FINGERPRINT)
        for output, fingerprints in (
            (valid, {"0" * 40}),
            (valid.replace(b"Apple Distribution", b"Apple Development"), {FINGERPRINT}),
            (b"  0 valid identities found\n", {FINGERPRINT}),
        ):
            with self.subTest(output=output), self.assertRaises(ios_signing.SigningError):
                ios_signing.select_identity(output, fingerprints)


class SigningLifecycleTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.workspace = root / "workspace"
        self.ios = self.workspace / "apps/app/ios"
        (self.ios / "Runner").mkdir(parents=True)
        (self.ios / "Flutter").mkdir()
        (self.ios / "Runner/Runner.entitlements").write_bytes(plistlib.dumps(REQUIRED))
        (self.ios / "ExportOptions.plist").write_bytes(plistlib.dumps({"method": "app-store-connect", "manageAppVersionAndBuildNumber": False}))
        self.runner = root / "runner"
        self.runner.mkdir()
        self.signing = self.runner / "ios-signing"
        self.home = root / "home"
        self.home.mkdir()
        self.environment = mock.patch.dict(os.environ, {
            "GITHUB_WORKSPACE": str(self.workspace), "RUNNER_TEMP": str(self.runner),
            "HOME": str(self.home), "GITHUB_ACTIONS": "false", "IOS_BUNDLE_ID": BUNDLE,
            "APPLE_TEAM_ID": TEAM, "IOS_DISTRIBUTION_CERTIFICATE_PASSWORD": "sensitive-fixture-password",
            "IOS_DISTRIBUTION_CERTIFICATE_BASE64": base64.b64encode(b"sensitive-fixture-p12").decode(),
            "IOS_PROVISIONING_PROFILE_BASE64": base64.b64encode(b"fixture-cms").decode(),
        })
        self.environment.start()
        self.addCleanup(self.environment.stop)
        self.calls = []

    def security(self, arguments, failure):
        self.calls.append(arguments)
        command = arguments[0]
        if command == "cms":
            return plistlib.dumps(profile_fixture())
        if command == "list-keychains" and "-s" not in arguments:
            return b'    "/fixture/login.keychain-db"\n    "/fixture/with space.keychain-db"\n'
        if command == "create-keychain":
            Path(arguments[-1]).touch(mode=0o600)
        if command == "find-identity":
            return f'  1) {FINGERPRINT} "Apple Distribution: Fixture"\n'.encode()
        if command == "delete-keychain":
            Path(arguments[-1]).unlink()
        return b""

    def test_prepare_and_cleanup_generate_manual_signing_and_restore_search_list(self):
        with mock.patch.object(ios_signing, "security", side_effect=self.security), contextlib.redirect_stdout(io.StringIO()):
            ios_signing.prepare()
            configuration = self.ios / "Flutter/Signing.xcconfig"
            self.assertIn(f"CODE_SIGN_IDENTITY[sdk=iphoneos*][config=Release] = {FINGERPRINT}", configuration.read_text())
            self.assertIn("CODE_SIGN_STYLE[config=Release] = Manual", configuration.read_text())
            export = plistlib.loads((self.runner / "ExportOptions.plist").read_bytes())
            self.assertEqual(export["signingStyle"], "manual")
            self.assertEqual(export["signingCertificate"], FINGERPRINT)
            self.assertEqual(export["provisioningProfiles"], {BUNDLE: PROFILE_UUID})
            self.assertFalse(export["manageAppVersionAndBuildNumber"])
            state = json.loads((self.signing / "state.json").read_text())
            installed = Path(state["profile"])
            self.assertEqual(installed.stat().st_mode & 0o777, 0o600)
            self.assertEqual(self.signing.stat().st_mode & 0o777, 0o700)
            self.assertFalse((self.signing / "distribution.p12").exists())
            ios_signing.cleanup()
            ios_signing.cleanup()
            self.assertFalse(self.signing.exists())
            self.assertFalse(installed.exists())
            self.assertFalse(configuration.exists())
            self.assertFalse((self.runner / "ExportOptions.plist").exists())
            self.assertIn(["list-keychains", "-d", "user", "-s", "/fixture/login.keychain-db", "/fixture/with space.keychain-db"], self.calls)

    def test_cleanup_after_import_failure(self):
        def fail_import(arguments, failure):
            if arguments[0] == "import":
                raise ios_signing.SigningError(failure)
            return self.security(arguments, failure)
        with mock.patch.object(ios_signing, "security", side_effect=fail_import):
            with self.assertRaises(ios_signing.SigningError):
                ios_signing.prepare()
            self.assertTrue((self.signing / "distribution.p12").exists())
            ios_signing.cleanup()
            self.assertFalse(self.signing.exists())

    def test_cleanup_continues_and_can_retry_after_search_list_restore_failure(self):
        with mock.patch.object(ios_signing, "security", side_effect=self.security), contextlib.redirect_stdout(io.StringIO()):
            ios_signing.prepare()
        (self.signing / "distribution.p12").write_bytes(b"sensitive-fixture")
        def fail_restore(arguments, failure):
            if arguments[0] == "list-keychains":
                raise ios_signing.SigningError(failure)
            return self.security(arguments, failure)
        with mock.patch.object(ios_signing, "security", side_effect=fail_restore):
            with self.assertRaises(ios_signing.SigningError):
                ios_signing.cleanup()
        self.assertFalse((self.signing / "distribution.p12").exists())
        self.assertFalse((self.signing / "signing.keychain-db").exists())
        self.assertFalse((self.ios / "Flutter/Signing.xcconfig").exists())
        with mock.patch.object(ios_signing, "security", side_effect=self.security):
            ios_signing.cleanup()
        self.assertFalse(self.signing.exists())

    def test_invalid_secret_does_not_echo_input_or_traceback(self):
        with mock.patch.dict(os.environ, {"IOS_DISTRIBUTION_CERTIFICATE_BASE64": "sensitive-fixture-invalid"}), mock.patch.object(sys, "argv", ["ios_signing.py", "prepare"]):
            stdout, stderr = io.StringIO(), io.StringIO()
            with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                self.assertEqual(ios_signing.main(), 1)
        self.assertEqual(stdout.getvalue(), "")
        self.assertNotIn("sensitive-fixture", stderr.getvalue())
        self.assertNotIn("Traceback", stderr.getvalue())
        self.assertIn("valid base64", stderr.getvalue())

    def test_cli_errors_are_captured_and_redacted(self):
        result = subprocess.CompletedProcess([], 1, b"sensitive-fixture-stdout", b"sensitive-fixture-stderr")
        with mock.patch.object(ios_signing.subprocess, "run", return_value=result) as run:
            with self.assertRaisesRegex(ios_signing.SigningError, "Static safe failure"):
                ios_signing.security(["import", "sensitive-fixture-password"], "Static safe failure")
        self.assertTrue(run.call_args.kwargs["capture_output"])

    def test_unexpected_errors_never_print_exception_contents(self):
        with mock.patch.object(sys, "argv", ["ios_signing.py", "prepare"]), mock.patch.object(ios_signing, "prepare", side_effect=ValueError("sensitive-fixture")):
            stderr = io.StringIO()
            with contextlib.redirect_stderr(stderr):
                self.assertEqual(ios_signing.main(), 1)
        self.assertNotIn("sensitive-fixture", stderr.getvalue())
        self.assertNotIn("Traceback", stderr.getvalue())


if __name__ == "__main__":
    unittest.main()
