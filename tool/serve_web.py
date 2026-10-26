"""Static file server for the Werenga web build with HTTP Range support.

Python's http.server ignores Range requests, which breaks seeking in <audio>.
This adds single-range support (bytes=start-end) as required by Chrome.
"""
import os
import re
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

RANGE_RE = re.compile(r"bytes=(\d*)-(\d*)")


class RangeHandler(SimpleHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def end_headers(self):
        self.send_header("Accept-Ranges", "bytes")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def _parse_range(self, size):
        header = self.headers.get("Range")
        if not header:
            return None
        match = RANGE_RE.fullmatch(header.strip())
        if not match:
            return None
        raw_start, raw_end = match.groups()
        if raw_start == "" and raw_end == "":
            return None
        if raw_start == "":
            length = int(raw_end)
            if length <= 0:
                return None
            return max(size - length, 0), size - 1
        start = int(raw_start)
        end = int(raw_end) if raw_end else size - 1
        if start >= size or end < start:
            return None
        return start, min(end, size - 1)

    def send_head(self):
        path = self.translate_path(self.path)
        if os.path.isdir(path):
            return super().send_head()

        range_header = self.headers.get("Range")
        if not range_header or not os.path.isfile(path):
            return super().send_head()

        try:
            size = os.path.getsize(path)
            span = self._parse_range(size)
        except OSError:
            return super().send_head()

        if span is None:
            self.send_response(416)
            self.send_header("Content-Range", "bytes */%d" % size)
            self.send_header("Content-Length", "0")
            self.end_headers()
            return None

        start, end = span
        handle = open(path, "rb")
        handle.seek(start)
        self._range_remaining = end - start + 1
        self.send_response(206)
        self.send_header("Content-Type", self.guess_type(path))
        self.send_header("Content-Range", "bytes %d-%d/%d" % (start, end, size))
        self.send_header("Content-Length", str(end - start + 1))
        self.end_headers()
        return handle

    def copyfile(self, source, outputfile):
        remaining = getattr(self, "_range_remaining", None)
        if remaining is None:
            return super().copyfile(source, outputfile)
        self._range_remaining = None
        while remaining > 0:
            chunk = source.read(min(256 * 1024, remaining))
            if not chunk:
                break
            try:
                outputfile.write(chunk)
            except (BrokenPipeError, ConnectionResetError):
                break
            remaining -= len(chunk)


CDN_WARNING = """\
WARNING: this build loads CanvasKit from www.gstatic.com.
         The preview will fail with ERR_CONNECTION_CLOSED when that host is
         blocked or the machine is offline. Rebuild with:
             flutter build web --release --no-web-resources-cdn
"""


def warn_if_cdn_engine(root):
    """Catch the silent regression where CanvasKit comes from the CDN.

    The build only fails at runtime, in the browser, so surface it here instead
    of leaving it for whoever opens the preview on a bad connection.
    """
    bootstrap = os.path.join(root, "flutter_bootstrap.js")
    try:
        with open(bootstrap, encoding="utf-8", errors="replace") as handle:
            config = handle.read()
    except OSError:
        return
    if '"useLocalCanvasKit":true' not in config.replace(" ", ""):
        print(CDN_WARNING, flush=True)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8080
    warn_if_cdn_engine(root)
    handler = partial(RangeHandler, directory=root)
    server = ThreadingHTTPServer(("127.0.0.1", port), handler)
    print("Serving %s on http://127.0.0.1:%d (Range enabled)" % (root, port), flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
