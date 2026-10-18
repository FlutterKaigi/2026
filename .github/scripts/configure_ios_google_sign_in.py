"""Configure and verify native Google sign-in without logging client IDs."""

import argparse
from pathlib import Path
import plistlib
import sys
from xml.parsers.expat import ExpatError


class ConfigurationError(Exception):
    """A static message that is safe to show in Actions logs."""


def read_plist(path):
    with path.open("rb") as source:
        value = plistlib.load(source)
    if not isinstance(value, dict):
        raise ConfigurationError("Expected a dictionary in the iOS configuration plist.")
    return value


def google_client_configuration(service):
    client_id = service.get("CLIENT_ID")
    reversed_client_id = service.get("REVERSED_CLIENT_ID")
    if not all(isinstance(value, str) and value.strip() and value == value.strip()
               for value in (client_id, reversed_client_id)):
        raise ConfigurationError("CLIENT_ID and REVERSED_CLIENT_ID must be nonempty strings.")
    if reversed_client_id != ".".join(reversed(client_id.split("."))):
        raise ConfigurationError("REVERSED_CLIENT_ID does not match CLIENT_ID.")
    return client_id, reversed_client_id


def callback_schemes(info):
    url_types = info.get("CFBundleURLTypes", [])
    if not isinstance(url_types, list):
        raise ConfigurationError("CFBundleURLTypes must be an array.")
    schemes = []
    for entry in url_types:
        if not isinstance(entry, dict):
            raise ConfigurationError("CFBundleURLTypes entries must be dictionaries.")
        entry_schemes = entry.get("CFBundleURLSchemes", [])
        if not isinstance(entry_schemes, list) or not all(isinstance(value, str) for value in entry_schemes):
            raise ConfigurationError("CFBundleURLSchemes must be an array of strings.")
        schemes.extend(entry_schemes)
    return schemes


def verify(service, info):
    client_id, reversed_client_id = google_client_configuration(service)
    if info.get("GIDClientID") != client_id:
        raise ConfigurationError("The app's GIDClientID does not match its Firebase configuration.")
    if reversed_client_id not in callback_schemes(info):
        raise ConfigurationError("The app is missing its Google sign-in callback URL scheme.")


def configure(service, info):
    client_id, reversed_client_id = google_client_configuration(service)
    schemes = callback_schemes(info)
    info["GIDClientID"] = client_id
    if reversed_client_id not in schemes:
        info.setdefault("CFBundleURLTypes", []).append({
            "CFBundleTypeRole": "Editor",
            "CFBundleURLSchemes": [reversed_client_id],
        })
    verify(service, info)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("configure", "verify"))
    parser.add_argument("--google-service-plist", required=True, type=Path)
    parser.add_argument("--app-plist", required=True, type=Path)
    args = parser.parse_args()
    try:
        service = read_plist(args.google_service_plist)
        info = read_plist(args.app_plist)
        if args.mode == "configure":
            configure(service, info)
            with args.app_plist.open("wb") as destination:
                plistlib.dump(info, destination, sort_keys=False)
        else:
            verify(service, info)
    except ConfigurationError as error:
        print(f"::error::{error}", file=sys.stderr)
        return 1
    except (OSError, ValueError, plistlib.InvalidFileException, ExpatError):
        print("::error::Could not read or write the iOS Google sign-in configuration.", file=sys.stderr)
        return 1
    print("iOS Google sign-in configuration verified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
