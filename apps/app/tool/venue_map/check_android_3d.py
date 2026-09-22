"""Check the real Android app's first 3D load from an already visible 2D map.

Uses only Python's standard library and adb. The app must be freshly launched
and its 2D map visible; subsequent switches reuse the scene and are not a cold
load. UI polling gives an upper bound, not an exact first-frame timestamp.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import time
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default=os.environ.get("ADB", "adb"))
    parser.add_argument("--serial", required=True)
    parser.add_argument("--budget", type=float, default=20)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.budget <= 0:
        parser.error("--budget must be positive")
    args.output.mkdir(parents=True, exist_ok=True)
    command = [args.adb, "-s", args.serial]

    def adb(*arguments, timeout=30):
        return subprocess.run(
            command + list(arguments), check=True, capture_output=True, timeout=timeout
        ).stdout

    def ui():
        output = adb("exec-out", "uiautomator", "dump", "/dev/tty")
        start = output.find(b"<?xml")
        end = output.find(b"</hierarchy>")
        # Android can report "could not get idle state" during first render.
        # Count that time against the budget and retry, never as a ready frame.
        if start < 0 or end < 0:
            return None
        return ET.fromstring(output[start : end + len(b"</hierarchy>")])

    def descriptions(tree):
        return "\n".join(
            node.get("text", "") + "\n" + node.get("content-desc", "")
            for node in tree.iter("node")
        )

    def ready(tree):
        labels = descriptions(tree)
        return "Explore the venue with Dashumaru" in labels or "だしゅまると会場さんぽ" in labels

    initial = ui()
    if initial is None:
        parser.error("could not read the initial UI; wait for the 2D map to settle")
    if ready(initial):
        parser.error("3D is already loaded; relaunch the app and show the 2D map first")
    buttons = [
        node for node in initial.iter("node")
        if node.get("text") == "3D" or node.get("content-desc") == "3D"
    ]
    if len(buttons) != 1 or buttons[0].get("selected") == "true":
        parser.error("show the 2D venue map before running this check")
    bounds = [int(value) for value in re.findall(r"\d+", buttons[0].get("bounds", ""))]
    if len(bounds) != 4:
        parser.error("cannot locate the 3D button")

    start = time.monotonic()
    adb(
        "shell", "input", "tap",
        str((bounds[0] + bounds[2]) // 2), str((bounds[1] + bounds[3]) // 2),
    )
    loaded = False
    elapsed = 0.0
    tree = initial
    while elapsed < args.budget:
        sample = ui()
        elapsed = time.monotonic() - start
        if sample is not None:
            tree = sample
            loaded = ready(tree)
        if loaded:
            break
        time.sleep(0.25)

    result = {
        "ready": loaded,
        "observed_after_seconds": round(elapsed, 3),
        "budget_seconds": args.budget,
    }
    result["passed"] = loaded and elapsed <= args.budget
    (args.output / "result.json").write_text(json.dumps(result, indent=2) + "\n")
    ET.ElementTree(tree).write(args.output / "ui.xml", encoding="utf-8")
    (args.output / "screen.png").write_bytes(adb("exec-out", "screencap", "-p"))
    print(json.dumps(result), flush=True)
    raise SystemExit(0 if result["passed"] else 1)


if __name__ == "__main__":
    main()
