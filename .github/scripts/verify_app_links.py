"""Verify deployed app associations, including content, without following redirects."""

import argparse
import http.client
import json
import math
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


AASA = "apple-app-site-association"
ASSETLINKS = "assetlinks.json"
MAX_JSON_BYTES = 1024 * 1024
USER_AGENT = "FlutterKaigi-App-Link-Verifier/1.0"


class VerificationError(Exception):
    """A failure safe to include in deployment logs without response bodies."""


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, url):
        return None


def positive_seconds(value):
    try:
        result = float(value)
    except ValueError:
        raise argparse.ArgumentTypeError("must be a positive finite number") from None
    if not math.isfinite(result) or result <= 0:
        raise argparse.ArgumentTypeError("must be a positive finite number")
    return result


def base_url(value):
    try:
        parsed = urllib.parse.urlsplit(value)
        valid = (
            parsed.scheme in {"http", "https"}
            and parsed.hostname
            and not parsed.username
            and not parsed.password
            and not parsed.query
            and not parsed.fragment
            and parsed.path in {"", "/"}
        )
        parsed.port  # Validate malformed ports before making any requests.
    except ValueError:
        valid = False
    if not valid:
        raise argparse.ArgumentTypeError("must be an HTTP(S) origin without credentials, query, or fragment")
    return value.rstrip("/")


def load_expected(directory):
    expected = {}
    for name, root_type in [(AASA, dict), (ASSETLINKS, list)]:
        try:
            value = json.loads((directory / name).read_text(encoding="utf-8"))
        except (OSError, UnicodeError, ValueError):
            raise ValueError(f"cannot read valid expected JSON: {name}") from None
        if not isinstance(value, root_type):
            raise ValueError(f"invalid expected JSON structure: {name}")
        expected[name] = value
    return expected


def fetch_json(opener, origin, name, timeout):
    path = f"/.well-known/{name}"
    request = urllib.request.Request(origin + path, headers={"Accept": "application/json", "User-Agent": USER_AGENT})
    try:
        with opener.open(request, timeout=timeout) as response:
            content_type = response.headers.get("Content-Type", "")
            print(f"{path}: HTTP {response.status}, Content-Type {content_type!r}", flush=True)
            if response.status != 200:
                raise VerificationError(f"{path}: HTTP {response.status}, expected 200")
            if content_type.split(";", 1)[0].strip().lower() != "application/json":
                raise VerificationError(f"{path}: Content-Type {content_type!r}, expected application/json")
            body = response.read(MAX_JSON_BYTES + 1)
    except urllib.error.HTTPError as error:
        content_type = error.headers.get("Content-Type", "")
        print(f"{path}: HTTP {error.code}, Content-Type {content_type!r}", flush=True)
        raise VerificationError(f"{path}: HTTP {error.code}, expected 200 (redirects are not followed)") from None
    except (urllib.error.URLError, OSError, http.client.HTTPException) as error:
        raise VerificationError(f"{path}: request failed ({type(error).__name__})") from None
    if len(body) > MAX_JSON_BYTES:
        raise VerificationError(f"{path}: JSON exceeds {MAX_JSON_BYTES} bytes")
    try:
        return json.loads(body)
    except (UnicodeError, ValueError):
        raise VerificationError(f"{path}: invalid JSON") from None


def verify_once(opener, origin, expected, apple_app_id, deadline, request_timeout):
    for name in expected if expected is not None else [AASA]:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise VerificationError("verification deadline reached")
        actual = fetch_json(opener, origin, name, min(request_timeout, remaining))
        if expected is not None:
            if actual != expected[name]:
                raise VerificationError(f"/.well-known/{name}: JSON does not match generated file")
        else:
            applinks = actual.get("applinks") if isinstance(actual, dict) else None
            details = applinks.get("details") if isinstance(applinks, dict) else None
            if not isinstance(details, list):
                raise VerificationError(f"/.well-known/{AASA}: invalid applinks.details structure")
            if not any(isinstance(detail, dict) and detail.get("appID") == apple_app_id for detail in details):
                raise VerificationError(f"/.well-known/{AASA}: expected appID {apple_app_id} is absent")


def verify(origin, expected=None, apple_app_id=None, timeout=300, interval=10, request_timeout=20):
    opener = urllib.request.build_opener(NoRedirect())
    deadline = time.monotonic() + timeout
    last_error = "verification deadline reached"
    attempt = 0
    while time.monotonic() < deadline:
        attempt += 1
        try:
            verify_once(opener, origin, expected, apple_app_id, deadline, request_timeout)
        except VerificationError as error:
            last_error = str(error)
        else:
            if time.monotonic() <= deadline:
                print(f"Verified app associations at {origin} (attempt {attempt})", flush=True)
                return
            last_error = "verification deadline reached"
        remaining = deadline - time.monotonic()
        if remaining > 0:
            print(f"Attempt {attempt}: {last_error}; retrying ({remaining:.1f}s remaining)", flush=True)
            time.sleep(min(interval, remaining))
    raise VerificationError(f"Timed out after {timeout:g}s: {last_error}")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", type=base_url, required=True)
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--expected-dir", type=Path)
    target.add_argument("--apple-app-id")
    parser.add_argument("--timeout-seconds", type=positive_seconds, default=300)
    parser.add_argument("--interval-seconds", type=positive_seconds, default=10)
    parser.add_argument("--request-timeout-seconds", type=positive_seconds, default=20)
    args = parser.parse_args(argv)
    if args.apple_app_id is not None and not re.fullmatch(r"[A-Z0-9]{10}\.[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", args.apple_app_id):
        parser.error("--apple-app-id must be a nonempty TEAM.bundle identifier")
    try:
        expected = load_expected(args.expected_dir) if args.expected_dir else None
    except ValueError as error:
        parser.error(str(error))
    try:
        verify(args.base_url, expected, args.apple_app_id, args.timeout_seconds, args.interval_seconds, args.request_timeout_seconds)
    except VerificationError as error:
        print(f"App association verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
