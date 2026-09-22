import contextlib
import io
import json
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import verify_app_links as verifier


SCRIPT = Path(__file__).with_name("verify_app_links.py")
APP_ID = "ABCDE12345.jp.flutterkaigi.conf2026"
EXPECTED = {
    verifier.AASA: {"applinks": {"apps": [], "details": [{"appID": APP_ID, "paths": ["/*"]}]}},
    verifier.ASSETLINKS: [{"relation": ["delegate_permission/common.handle_all_urls"], "target": {"namespace": "android_app", "package_name": "jp.flutterkaigi.conf2026", "sha256_cert_fingerprints": ["AB:CD"]}}],
}


def response(body, status=200, content_type="application/json", delay=0):
    return status, content_type, body if isinstance(body, bytes) else json.dumps(body).encode(), delay


@contextlib.contextmanager
def server(responses, required_user_agent=None):
    calls = []
    counts = {}

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            calls.append(self.path)
            options = responses.get(self.path, [response({}, 404)])
            index = counts.get(self.path, 0)
            counts[self.path] = index + 1
            status, content_type, body, delay = options[min(index, len(options) - 1)]
            if required_user_agent is not None and self.headers.get("User-Agent") != required_user_agent:
                status, content_type, body, delay = response({"error": "unidentified client"}, 403)
            time.sleep(delay)
            try:
                self.send_response(status)
                self.send_header("Content-Type", content_type)
                if 300 <= status < 400:
                    self.send_header("Location", "/redirect-target")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass

        def log_message(self, *args):
            pass

    httpd = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=lambda: httpd.serve_forever(poll_interval=0.01), daemon=True)
    thread.start()
    try:
        yield f"http://127.0.0.1:{httpd.server_port}", calls
    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()


def documents():
    return {f"/.well-known/{name}": [response(value)] for name, value in EXPECTED.items()}


class VerifyAppLinksTest(unittest.TestCase):
    def verify(self, origin, **kwargs):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            verifier.verify(origin, expected=EXPECTED, timeout=0.2, interval=0.01, request_timeout=0.05, **kwargs)
        return output.getvalue()

    def run_cli(self, origin, *options, expected=True):
        with tempfile.TemporaryDirectory() as directory:
            if expected:
                for name, value in EXPECTED.items():
                    (Path(directory) / name).write_text(json.dumps(value))
                options = ("--expected-dir", directory, *options)
            return subprocess.run([sys.executable, str(SCRIPT), "--base-url", origin, "--timeout-seconds", "0.15", "--interval-seconds", "0.01", "--request-timeout-seconds", "0.05", *options], capture_output=True, text=True, timeout=3)

    def test_identifies_verifier_and_logs_response_metadata(self):
        with server(documents(), required_user_agent="FlutterKaigi-App-Link-Verifier/1.0") as (origin, calls):
            output = self.verify(origin)
        self.assertEqual(len(calls), 2)
        for name in EXPECTED:
            self.assertIn(f"/.well-known/{name}: HTTP 200, Content-Type 'application/json'", output)
        self.assertIn("Verified", output)
        self.assertNotIn(APP_ID, output)
        self.assertNotIn("sha256_cert_fingerprints", output)

    def test_old_html_becomes_json_without_redeploy(self):
        replies = documents()
        path = f"/.well-known/{verifier.AASA}"
        replies[path].insert(0, response(b"<html>old deployment</html>", content_type="text/html"))
        with server(replies) as (origin, calls):
            output = self.verify(origin)
        self.assertEqual(calls.count(path), 2)
        self.assertIn("Content-Type", output)
        self.assertIn("Verified", output)
        self.assertNotIn("<html>", output)

    def test_second_document_mismatch_is_retried_too(self):
        replies = documents()
        path = f"/.well-known/{verifier.ASSETLINKS}"
        replies[path].insert(0, response([]))
        with server(replies) as (origin, calls):
            self.verify(origin)
        self.assertEqual(calls.count(path), 2)
        self.assertEqual(calls.count(f"/.well-known/{verifier.AASA}"), 2)

    def test_semantic_json_and_content_type_parameters(self):
        replies = documents()
        replies[f"/.well-known/{verifier.AASA}"] = [response({"applinks": {"details": EXPECTED[verifier.AASA]["applinks"]["details"], "apps": []}}, content_type="Application/JSON; charset=utf-8")]
        with server(replies) as (origin, calls):
            self.verify(origin)
        self.assertEqual(len(calls), 2)

    def test_transient_http_error_and_redirect_recover(self):
        for status in [404, 503, 302]:
            with self.subTest(status=status):
                replies = documents()
                path = f"/.well-known/{verifier.AASA}"
                replies[path].insert(0, response({}, status))
                with server(replies) as (origin, calls):
                    output = self.verify(origin)
                self.assertIn(f"HTTP {status}", output)
                self.assertNotIn("/redirect-target", calls)

    def test_permanent_failures_time_out_and_do_not_dump_body(self):
        cases = [
            (response({}, 404), "HTTP 404"),
            (response({}, 302), "HTTP 302"),
            (response({"private": "do-not-log"}), "does not match"),
            (response(b"do-not-log"), "invalid JSON"),
            (response(b"do-not-log", content_type="text/html"), "Content-Type"),
        ]
        for reply, diagnostic in cases:
            with self.subTest(diagnostic=diagnostic):
                replies = documents()
                replies[f"/.well-known/{verifier.AASA}"] = [reply]
                with server(replies) as (origin, calls):
                    result = self.run_cli(origin)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("Timed out", result.stderr)
                self.assertIn(diagnostic, result.stdout + result.stderr)
                self.assertNotIn("do-not-log", result.stdout + result.stderr)
                self.assertGreater(len(calls), 1)
                self.assertNotIn("/redirect-target", calls)

    def test_website_readiness_requires_exact_app_id_and_valid_shape(self):
        for value in [None, [], {}, {"applinks": []}, {"applinks": {"details": {}}}, {"applinks": {"details": [None, {"appID": "OTHER." + APP_ID}]}}]:
            with self.subTest(value=value):
                replies = documents()
                replies[f"/.well-known/{verifier.AASA}"] = [response(value), response(EXPECTED[verifier.AASA])]
                with server(replies) as (origin, calls):
                    result = self.run_cli(origin, "--apple-app-id", APP_ID, expected=False)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("Verified", result.stdout)
                self.assertEqual(len(calls), 2)
                self.assertNotIn(f"/.well-known/{verifier.ASSETLINKS}", calls)

    def test_website_wrong_app_id_times_out(self):
        with server(documents()) as (origin, calls):
            result = self.run_cli(origin, "--apple-app-id", APP_ID + ".stg", expected=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn("expected appID", result.stdout + result.stderr)

    def test_request_timeout_retries_and_recovers(self):
        replies = documents()
        path = f"/.well-known/{verifier.AASA}"
        replies[path].insert(0, response(EXPECTED[verifier.AASA], delay=0.1))
        with server(replies) as (origin, calls):
            output = self.verify(origin)
        self.assertEqual(calls.count(path), 2)
        self.assertIn("request failed", output)
        self.assertIn("Verified", output)

    def test_slow_request_and_sleep_are_bounded_by_deadline(self):
        replies = documents()
        replies[f"/.well-known/{verifier.AASA}"] = [response(EXPECTED[verifier.AASA], delay=0.5)]
        with server(replies) as (origin, calls):
            started = time.monotonic()
            result = self.run_cli(origin, "--interval-seconds", "10", "--request-timeout-seconds", "10")
            elapsed = time.monotonic() - started
        self.assertEqual(result.returncode, 1)
        self.assertLess(elapsed, 1)
        self.assertEqual(len(calls), 1)

    def test_invalid_local_configuration_fails_without_requests(self):
        with server(documents()) as (origin, calls):
            for options in [("--timeout-seconds", "0"), ("--interval-seconds", "nan"), ("--request-timeout-seconds", "-1"), ("--base-url", origin + "/path"), ("--base-url", "https://user:password@example.com"), ("--base-url", "https://example.com:invalid")]:
                with self.subTest(options=options):
                    result = self.run_cli(origin, *options)
                    self.assertEqual(result.returncode, 2)
            for app_id in ["", ".", "TEAM."]:
                result = self.run_cli(origin, "--apple-app-id", app_id, expected=False)
                self.assertEqual(result.returncode, 2)
            with tempfile.TemporaryDirectory() as directory:
                for content in [None, b"invalid-json", b"[]"]:
                    if content is not None:
                        (Path(directory) / verifier.AASA).write_bytes(content)
                    result = self.run_cli(origin, "--expected-dir", directory, expected=False)
                    self.assertEqual(result.returncode, 2)
            self.assertEqual(calls, [])


if __name__ == "__main__":
    unittest.main()
