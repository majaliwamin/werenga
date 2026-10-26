"""Print a live progress report: python tool/progress.py

Shows how many recordings are actually in the app, how many are still
downloading, the current transfer rate and a rough time remaining. Read-only.
"""
import json
import os
import re
import sys
import time

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from audio_metadata import match  # noqa: E402

BASE = r"C:\Users\AMINILOGY\AppData\Local\Temp\opencode"
STAGE = os.path.join(BASE, "quran_audio")
PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(PROJECT, "assets", "audio")
LIST = os.path.join(BASE, "drive_list.json")
RES = os.path.join(BASE, "download_results.json")


def key_for(title):
    found = match(title)
    if found:
        number, name, part = found
        return f"surah:{number}|{part or ''}"
    # Unnumbered files are compared on a normalised name, so "6__Surat
    # THAARIAT.mp3" and "6-surat-thaariat.m4a" count as the same recording.
    stem = os.path.splitext(title)[0].lower()
    stem = re.sub(r"[^a-z0-9]+", " ", stem).strip()
    return "name:" + re.sub(r"\s+", " ", stem)


def load(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def partial_stats():
    files = [f for f in os.listdir(STAGE) if f.endswith(".part")]
    total = sum(os.path.getsize(os.path.join(STAGE, f)) for f in files)
    newest = max((os.path.getmtime(os.path.join(STAGE, f)) for f in files), default=0)
    return len(files), total, newest


targets = load(LIST, [])
targets = [t for t in targets if not t.get("folder") and t["title"].lower().endswith(".mp3")]
unique_targets = {key_for(t["title"]) for t in targets}

bundled = sorted(f for f in os.listdir(AUDIO)
                 if f.lower().endswith((".mp3", ".m4a", ".aac", ".ogg", ".opus", ".flac")))
# What is in the app decides progress: a file may have arrived through another
# path (Al-Kahf did), so counting only this download run would understate it.
done_keys = {key_for(f) for f in bundled}

before = partial_stats()
time.sleep(6)
after = partial_stats()

count_before, bytes_before, newest = before
count_after, bytes_after, newest_after = after
rate = (bytes_after - bytes_before) / 6

remaining_keys = unique_targets - done_keys
done_count = len(done_keys)
total_unique = len(unique_targets)

print("=" * 58)
print("  WERENGA PROGRESS")
print("=" * 58)
print(f"  Recordings in the app      {len(bundled)}")
print(f"  Library size               "
      f"{sum(os.path.getsize(os.path.join(AUDIO, f)) for f in bundled)/1e6:.0f} MB")
print(f"  Unique surahs downloaded   {done_count} of {total_unique}")

if not remaining_keys:
    print("  Download status            complete")
    print("-" * 58)
    print("  Every recording from the folder is in the app.")
    print("=" * 58)
    raise SystemExit(0)

print(f"  Files still downloading    {count_after}  ({bytes_after/1e6:.0f} MB buffered)")

if rate > 50_000:
    avg = sum(os.path.getsize(os.path.join(AUDIO, f)) for f in bundled) / max(len(bundled), 1)
    eta = (avg * len(remaining_keys)) / rate
    print(f"  Speed now                  {rate/1024:.0f} KB/s")
    print(f"  Rough time remaining       {eta/3600:.1f} h")
elif rate > 0:
    print(f"  Speed now                  {rate/1024:.0f} KB/s (very slow)")
    print("  Rough time remaining       several hours")
else:
    print("  Speed now                  0 KB/s")
    print("  Status                     waiting out a throttle window")

idle = time.time() - max(newest, newest_after) if newest_after else None
if idle is not None and idle > 300 and rate == 0:
    print(f"  No writes for               {idle/60:.0f} min (cooling down, will resume)")

print("-" * 58)
if remaining_keys:
    waiting = [t["title"] for t in targets if key_for(t["title"]) in remaining_keys]
    waiting = list(dict.fromkeys(waiting))
    shown = waiting[:6]
    print("  Next up:")
    for title in shown:
        print(f"    - {title}")
    if len(waiting) > len(shown):
        print(f"    ... and {len(waiting) - len(shown)} more")
else:
    print("  Everything downloaded. Run a rebuild if the count looks stale.")
print("=" * 58)
