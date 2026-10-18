"""Verify native Google configuration survives iOS packaging for either environment."""

import contextlib
import copy
import io
from pathlib import Path
import plistlib
import sys
import tempfile
import unittest
from unittest import mock

import configure_ios_google_sign_in as google_sign_in


DEV_CALLBACK = "app-1-000000000000-ios-0000000000000000000000"


def service_fixture(environment):
    client_id = f"123456789-{environment}.apps.googleusercontent.com"
    return {
        "CLIENT_ID": client_id,
        "REVERSED_CLIENT_ID": ".".join(reversed(client_id.split("."))),
    }


def app_fixture():
    return {
        "CFBundleDisplayName": "FlutterKaigi",
        "CFBundleURLTypes": [{
            "CFBundleTypeRole": "Editor",
            "CFBundleURLSchemes": [DEV_CALLBACK, "existing-callback"],
        }],
    }


class GoogleSignInConfigurationTest(unittest.TestCase):
    def test_configures_stg_and_prod_without_changing_existing_callbacks(self):
        for environment in ("stg", "prod"):
            with self.subTest(environment=environment):
                service = service_fixture(environment)
                info = app_fixture()
                original = copy.deepcopy(info)
                google_sign_in.configure(service, info)
                self.assertEqual(info["GIDClientID"], service["CLIENT_ID"])
                self.assertEqual(info["CFBundleDisplayName"], original["CFBundleDisplayName"])
                self.assertEqual(info["CFBundleURLTypes"][0], original["CFBundleURLTypes"][0])
                self.assertIn(service["REVERSED_CLIENT_ID"], google_sign_in.callback_schemes(info))
                google_sign_in.verify(service, info)

    def test_repeated_configuration_does_not_add_duplicate_url_types(self):
        service = service_fixture("stg")
        info = app_fixture()
        google_sign_in.configure(service, info)
        configured = copy.deepcopy(info)
        google_sign_in.configure(service, info)
        self.assertEqual(info, configured)

    def test_existing_google_callback_is_reused(self):
        service = service_fixture("stg")
        info = app_fixture()
        info["CFBundleURLTypes"][0]["CFBundleURLSchemes"].append(service["REVERSED_CLIENT_ID"])
        google_sign_in.configure(service, info)
        self.assertEqual(len(info["CFBundleURLTypes"]), 1)

    def test_configures_an_app_without_url_types(self):
        service = service_fixture("prod")
        info = {}
        google_sign_in.configure(service, info)
        google_sign_in.verify(service, info)

    def test_rejects_missing_empty_or_nonstring_client_configuration(self):
        for key in ("CLIENT_ID", "REVERSED_CLIENT_ID"):
            for value in (None, "", " ", 123, False, [], {}):
                with self.subTest(key=key, value=value):
                    service = service_fixture("stg")
                    if value is None:
                        del service[key]
                    else:
                        service[key] = value
                    info = app_fixture()
                    original = copy.deepcopy(info)
                    with self.assertRaises(google_sign_in.ConfigurationError):
                        google_sign_in.configure(service, info)
                    self.assertEqual(info, original)

    def test_rejects_mismatched_client_and_callback(self):
        service = service_fixture("stg")
        service["REVERSED_CLIENT_ID"] = service_fixture("prod")["REVERSED_CLIENT_ID"]
        with self.assertRaises(google_sign_in.ConfigurationError):
            google_sign_in.configure(service, app_fixture())

    def test_rejects_malformed_existing_callback_configuration(self):
        for url_types in ({}, ["callback"], [{"CFBundleURLSchemes": "callback"}], [{"CFBundleURLSchemes": [123]}]):
            with self.subTest(url_types=url_types), self.assertRaises(google_sign_in.ConfigurationError):
                google_sign_in.configure(service_fixture("stg"), {"CFBundleURLTypes": url_types})

    def test_verify_rejects_packaged_app_from_another_environment(self):
        info = app_fixture()
        google_sign_in.configure(service_fixture("prod"), info)
        with self.assertRaises(google_sign_in.ConfigurationError):
            google_sign_in.verify(service_fixture("stg"), info)

    def test_verify_requires_client_id_and_callback_in_packaged_app(self):
        service = service_fixture("stg")
        for missing_key in ("GIDClientID", "CFBundleURLTypes"):
            with self.subTest(missing_key=missing_key):
                info = app_fixture()
                google_sign_in.configure(service, info)
                del info[missing_key]
                with self.assertRaises(google_sign_in.ConfigurationError):
                    google_sign_in.verify(service, info)

    def test_cli_configures_xml_then_verifies_binary_ipa_plist_without_modifying_it(self):
        with tempfile.TemporaryDirectory() as directory:
            service_path = Path(directory) / "GoogleService-Info.plist"
            info_path = Path(directory) / "Info.plist"
            service_path.write_bytes(plistlib.dumps(service_fixture("stg")))
            info_path.write_bytes(plistlib.dumps(app_fixture()))
            arguments = ["--google-service-plist", str(service_path), "--app-plist", str(info_path)]
            with mock.patch.object(sys, "argv", ["configure_ios_google_sign_in.py", "configure", *arguments]), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(google_sign_in.main(), 0)
            binary_info = plistlib.dumps(plistlib.loads(info_path.read_bytes()), fmt=plistlib.FMT_BINARY)
            info_path.write_bytes(binary_info)
            with mock.patch.object(sys, "argv", ["configure_ios_google_sign_in.py", "verify", *arguments]), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(google_sign_in.main(), 0)
            self.assertEqual(info_path.read_bytes(), binary_info)

    def test_cli_failure_does_not_print_configuration_values(self):
        with tempfile.TemporaryDirectory() as directory:
            service_path = Path(directory) / "GoogleService-Info.plist"
            info_path = Path(directory) / "Info.plist"
            service = service_fixture("stg")
            service["REVERSED_CLIENT_ID"] = "private-fixture-value"
            service_path.write_bytes(plistlib.dumps(service))
            original = plistlib.dumps(app_fixture())
            info_path.write_bytes(original)
            output = io.StringIO()
            arguments = ["configure_ios_google_sign_in.py", "configure", "--google-service-plist", str(service_path), "--app-plist", str(info_path)]
            with mock.patch.object(sys, "argv", arguments), contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
                self.assertEqual(google_sign_in.main(), 1)
            self.assertIn("::error::", output.getvalue())
            for value in service.values():
                self.assertNotIn(value, output.getvalue())
            self.assertEqual(info_path.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
