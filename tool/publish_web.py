"""Publish the web build into the folder the preview server serves.

    python tool\\publish_web.py

Copying `build\\web` to `build\\site` means the running preview server never
holds a handle on `build\\web`. Flutter can therefore clean and rebuild
`build\\web` while the app stays open in the browser, instead of the earlier
sequence of stopping the server, deleting the bundle and rebuilding, which left
the open page fetching from a dead port (`ERR_CONNECTION_REFUSED`).

Run it after `flutter build web`, then refresh the browser.
"""
import os
import shutil
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "build", "web")
DST = os.path.join(ROOT, "build", "site")
SAMPLES = os.path.join(ROOT, "tool", "samples")


def file_set(root):
    found = set()
    for base, _dirs, files in os.walk(root):
        for name in files:
            path = os.path.join(base, name)
            found.add(os.path.relpath(path, root))
    return found


def main():
    if not os.path.isfile(os.path.join(SRC, "main.dart.js")):
        print("build\\web is missing or incomplete. Run:\n"
              "  flutter build web --release --no-web-resources-cdn "
              "--no-wasm-dry-run --no-source-maps")
        return 1

    os.makedirs(DST, exist_ok=True)

    copied = 0
    for rel in sorted(file_set(SRC)):
        src = os.path.join(SRC, rel)
        dst = os.path.join(DST, rel)
        if os.path.exists(dst) and os.path.getsize(dst) == os.path.getsize(src) \
                and os.path.getmtime(dst) >= os.path.getmtime(src):
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
        copied += 1

    removed = 0
    for rel in file_set(DST) - file_set(SRC):
        os.remove(os.path.join(DST, rel))
        removed += 1

    # The quality-comparison page is a tool, not app code, so it lives in the
    # repository and is copied in after every publish.
    if os.path.isdir(SAMPLES):
        os.makedirs(os.path.join(DST, "samples"), exist_ok=True)
        for name in os.listdir(SAMPLES):
            src = os.path.join(SAMPLES, name)
            if os.path.isfile(src):
                shutil.copy2(src, os.path.join(DST, "samples", name))

    audio = os.path.join(DST, "assets", "assets", "audio")
    size = sum(os.path.getsize(os.path.join(audio, f))
               for f in os.listdir(audio)) if os.path.isdir(audio) else 0
    print(f"published {copied} updated file(s), removed {removed} stale file(s)")
    print(f"serving folder build\\site  ({size/1e6:.0f} MB of audio)")
    print("if the server is not running yet: python tool\\serve_web.py build\\site 8080")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
