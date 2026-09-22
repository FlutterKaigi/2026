import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("mask_credentials.py")


class MaskCredentialsTest(unittest.TestCase):
    def run_masker(self, kind, content):
        with tempfile.TemporaryDirectory() as directory:
            credential = Path(directory) / "credential"
            credential.write_bytes(content)
            return subprocess.run(
                [sys.executable, str(SCRIPT), kind, str(credential)],
                capture_output=True,
                text=True,
            )

    def registered_values(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        values = []
        for line in result.stdout.splitlines():
            self.assertTrue(line.startswith("::add-mask::"), "Unexpected log output")
            # Decode the workflow protocol, not URL encoding in general.
            value = (
                line.removeprefix("::add-mask::")
                .replace("%0D", "\r")
                .replace("%0A", "\n")
                .replace("%25", "%")
            )
            self.assertTrue(value.strip(), "Empty mask")
            values.append(value)
        return values

    def test_pem_registers_full_key_and_each_body_line(self):
        key = "-----BEGIN PRIVATE KEY-----\nfixture-first-line\nfixture-last-line\n-----END PRIVATE KEY-----\n"
        values = self.registered_values(self.run_masker("pem", key.encode()))
        self.assertIn(key, values)
        self.assertIn("fixture-first-line", values)
        self.assertIn("fixture-last-line", values)

    def test_pem_preserves_crlf_and_unterminated_last_line(self):
        key = "-----BEGIN PRIVATE KEY-----\r\nfixture-body\r\n-----END PRIVATE KEY-----"
        values = self.registered_values(self.run_masker("pem", key.encode()))
        self.assertIn(key, values)
        self.assertIn("fixture-body", values)

    def test_google_play_registers_private_key_without_public_metadata(self):
        key = "-----BEGIN PRIVATE KEY-----\nfixture-google-key\n-----END PRIVATE KEY-----\n"
        data = json.dumps({"private_key": key, "client_email": "public-id@example.invalid"})
        values = self.registered_values(self.run_masker("google-play", data.encode()))
        self.assertIn(key, values)
        self.assertIn("fixture-google-key", values)
        self.assertNotIn("public-id@example.invalid", values)

    def test_passwords_keep_equals_percent_and_spaces(self):
        data = b"storeFile=release.jks\nstorePassword=fixture=100%0A safe\nkeyAlias=public-alias\nkeyPassword=fixture-key"
        values = self.registered_values(self.run_masker("android-signing", data))
        self.assertIn("fixture=100%0A safe", values)
        self.assertIn("fixture-key", values)
        self.assertNotIn("release.jks", values)
        self.assertNotIn("public-alias", values)

    def test_properties_follow_java_escaping_and_continuation(self):
        data = (
            b"# ignored\r\n! ignored too\r\n"
            b"store\\u0050assword : fixture\\u0025\\:\\\r\n"
            b"    continued\\=value\r\n"
            b"keyPassword\tfixture\\ password\\twith\\nnewline\r\n"
        )
        values = self.registered_values(self.run_masker("android-signing", data))
        self.assertIn("fixture%:continued=value", values)
        self.assertIn("fixture password\twith\nnewline", values)
        self.assertIn("fixture\\u0025\\:continued\\=value", values)

    def test_latin1_and_duplicate_password_use_gradle_value(self):
        data = b"storePassword=old\nstorePassword=fixture-caf\xe9\nkeyPassword=fixture\\\\backslash\n"
        values = self.registered_values(self.run_masker("android-signing", data))
        self.assertIn("fixture-caf\u00e9", values)
        self.assertIn("fixture\\backslash", values)
        self.assertNotIn("old", values)

    def test_properties_surrogate_pair_and_trailing_continuation(self):
        data = b"storePassword=fixture-\\uD83D\\uDD12\nkeyPassword=fixture-eof\\"
        values = self.registered_values(self.run_masker("android-signing", data))
        self.assertIn("fixture-\U0001f512", values)
        self.assertIn("fixture-eof", values)

    def test_command_injection_and_literal_percent_escapes(self):
        key = "fixture%0A%0D%25\r\n::warning::fixture-injected\nlast-line"
        data = json.dumps({"private_key": key})
        result = self.run_masker("google-play", data.encode())
        values = self.registered_values(result)
        self.assertIn(key, values)
        self.assertNotIn("\n::warning::", result.stdout)

    def test_malformed_credentials_fail_without_echoing_input(self):
        cases = [
            ("google-play", b'{"private_key":"sensitive-fixture"'),
            ("google-play", b'{"private_key":null}'),
            ("google-play", b'[]'),
            ("google-play", b'{"private_key":""}'),
            ("android-signing", b"storePassword=sensitive-fixture"),
            ("android-signing", b"storePassword=sensitive-fixture\nkeyPassword=\\uNOPE"),
            ("pem", b""),
        ]
        for kind, data in cases:
            with self.subTest(kind=kind, data=data):
                result = self.run_masker(kind, data)
                self.assertEqual(result.returncode, 1)
                self.assertEqual(result.stdout, "")
                self.assertEqual(result.stderr, "::error::Could not register decoded credential masks.\n")

    def test_missing_file_fails_without_traceback(self):
        with tempfile.TemporaryDirectory() as directory:
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "pem", str(Path(directory) / "missing")],
                capture_output=True,
                text=True,
            )
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
