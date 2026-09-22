"""Register decoded delivery credentials with the GitHub Actions log masker."""

import json
import re
import sys
from pathlib import Path


def unescape_property(value):
    def replace(match):
        escaped = match.group(1)
        if escaped.startswith("u"):
            if not re.fullmatch(r"u[0-9a-fA-F]{4}", escaped):
                raise ValueError("Invalid property escape")
            return chr(int(escaped[1:], 16))
        return {"t": "\t", "n": "\n", "r": "\r", "f": "\f"}.get(escaped, escaped)

    decoded = re.sub(r"\\(u.{0,4}|.)", replace, value)
    # Java properties express non-BMP characters as UTF-16 surrogate pairs.
    return decoded.encode("utf-16", "surrogatepass").decode("utf-16")


def signing_passwords(path):
    # Match Properties.load(InputStream), which Gradle uses: Latin-1, escaped
    # separators/Unicode, and an odd trailing backslash for line continuation.
    properties = {}
    pending = ""
    continuing = False
    for line in [*re.split(r"\r\n?|\n", path.read_bytes().decode("latin-1")), ""]:
        line = line.lstrip(" \t\f")
        if not continuing and (not line or line.startswith(("#", "!"))):
            continue
        pending += line
        backslashes = len(pending) - len(pending.rstrip("\\"))
        continuing = backslashes % 2 == 1
        if continuing:
            pending = pending[:-1]
            continue
        key, raw_value = re.fullmatch(r"((?:\\.|[^\\:= \t\f])*)(.*)", pending).groups()
        raw_value = raw_value.lstrip(" \t\f")
        if raw_value.startswith(("=", ":")):
            raw_value = raw_value[1:].lstrip(" \t\f")
        properties[unescape_property(key)] = (raw_value, unescape_property(raw_value))
        pending = ""
    return [value for name in ("storePassword", "keyPassword") for value in properties[name]]


def credential_values(kind, path):
    if kind == "android-signing":
        return signing_passwords(path)
    if kind == "google-play":
        # The JSON wrapper is not enough: tools may print the PEM independently.
        return [json.loads(path.read_text(encoding="utf-8"))["private_key"]]
    if kind == "pem":
        return [path.read_bytes().decode("utf-8")]
    raise ValueError("Unknown credential type")


def mask_commands(values):
    if any(not isinstance(value, str) or not value.strip() for value in values):
        raise ValueError("Empty credential")
    masks = dict.fromkeys(
        part for value in values for part in (value, *value.splitlines()) if part.strip()
    )
    # Escape in the same order as @actions/core so a credential cannot inject
    # another workflow command, and literal %0A/%0D values survive unchanged.
    return [
        "::add-mask::" + value.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
        for value in masks
    ]


def main():
    try:
        if len(sys.argv) != 3:
            raise ValueError("Expected a credential type and file")
        commands = mask_commands(credential_values(sys.argv[1], Path(sys.argv[2])))
        # Validate the whole input before emitting any commands. Never include
        # parser exceptions: they can contain unmasked credential fragments.
        output = "\n".join(commands) + "\n"
        output.encode("utf-8")
    except (OSError, ValueError, KeyError, TypeError, AttributeError):
        print("::error::Could not register decoded credential masks.", file=sys.stderr)
        return 1
    print(output, end="", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
