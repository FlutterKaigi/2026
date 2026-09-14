#!/usr/bin/env python3
"""Serve the local venue walk preview and up to eight in-memory PNG downloads."""

import argparse
from collections import OrderedDict
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import threading
from urllib.parse import urlsplit
import uuid


class PhotoServer(ThreadingHTTPServer):
    def __init__(self, address, handler):
        super().__init__(address, handler)
        self.photos = OrderedDict()
        self.photo_lock = threading.Lock()


class PreviewHandler(SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/__demo/photos":
            self.send_error(404)
            return
        host = self.headers.get("Host", "")
        port = self.server.server_port
        if (
            host not in (f"127.0.0.1:{port}", f"localhost:{port}")
            or self.headers.get("Origin", f"http://{host}") != f"http://{host}"
            or self.headers.get("X-Venue-Walk-Photo") != "1"
        ):
            self.send_error(403)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            self.send_error(400)
            return
        if not 0 < length <= 8 * 1024 * 1024:
            self.send_error(413)
            return
        data = self.rfile.read(length)
        if len(data) != length or not data.startswith(b"\x89PNG\r\n\x1a\n"):
            self.send_error(415, "A PNG image is required")
            return
        name = f"flutterkaigi-2026-{uuid.uuid4().hex}.png"
        path = f"/__demo/photos/{name}"
        with self.server.photo_lock:
            self.server.photos[path] = data
            while len(self.server.photos) > 8:
                self.server.photos.popitem(last=False)
        result = json.dumps({"url": path}).encode()
        self.send_response(201)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(result)))
        self.end_headers()
        self.wfile.write(result)

    def _photo(self, head=False):
        path = urlsplit(self.path).path
        if not path.startswith("/__demo/photos/"):
            return False
        with self.server.photo_lock:
            data = self.server.photos.get(path)
        if data is None:
            self.send_error(404)
            return True
        self.send_response(200)
        self.send_header("Content-Type", "image/png")
        self.send_header("Content-Disposition", f'attachment; filename="{path.rsplit("/", 1)[-1]}"')
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        if not head:
            self.wfile.write(data)
        return True

    def do_GET(self):
        if not self._photo():
            super().do_GET()

    def do_HEAD(self):
        if not self._photo(head=True):
            super().do_HEAD()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8774)
    parser.add_argument("--directory", type=Path, default=Path(__file__).resolve().parents[2] / "build/venue-walk-demo")
    options = parser.parse_args()
    handler = partial(PreviewHandler, directory=str(options.directory.resolve()))
    with PhotoServer(("127.0.0.1", options.port), handler) as server:
        print(f"Venue walk demo: http://127.0.0.1:{options.port}/", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
