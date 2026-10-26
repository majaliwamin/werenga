"""Convert the bundled recordings to a smaller, broadly playable format.

The source files are 128 kbps mono MP3, which is CD-era sizing for speech.
AAC-LC mono at 48 kbps is transparent enough for recitation and translation on
phone speakers and earbuds, and AAC is native to every Android version the app
supports (7.0+). Ogg Opus would be ~35% smaller again, but Android only decodes
it natively from Android 10; on older phones it needs a decoder the player does
not bundle, so Opus is deliberately not used.

Usage:

    # one file, explicit settings
    python tool/convert_audio.py --input a.mp3 --output b.m4a --bitrate 48k

    # migrate a folder in place: every non-AAC file becomes .m4a, and the
    # original is removed only after the length is verified to match
    python tool/convert_audio.py --in-place assets/audio --bitrate 48k --jobs 3

ffmpeg is looked up on PATH, then in the FFMPEG env variable (a binary path or
the folder that contains bin/ffmpeg.exe), then in the usual tools folder.
"""
import argparse
import os
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONVERTED = {"m4a", "aac"}
SOURCES = {"mp3", "wav", "ogg", "opus", "flac", "m4a", "aac"}

DEFAULT_FFMPEG = os.path.join(
    os.environ.get("LOCALAPPDATA", ""), "Temp", "opencode", "ffmpeg"
)


def find_ffmpeg(explicit=None):
    """Return (ffmpeg, ffprobe) paths."""
    candidates = []
    if explicit:
        candidates.append(explicit)
    if os.environ.get("FFMPEG"):
        candidates.append(os.environ["FFMPEG"])
    where = shutil.which("ffmpeg")
    if where:
        candidates.append(where)
    candidates += [
        DEFAULT_FFMPEG,
        os.path.join(DEFAULT_FFMPEG, "bin", "ffmpeg.exe"),
        os.path.join(DEFAULT_FFMPEG, "ffmpeg.exe"),
    ]
    for entry in candidates:
        if not entry:
            continue
        variants = [entry, os.path.join(entry, "bin", "ffmpeg.exe"),
                    os.path.join(entry, "ffmpeg.exe")]
        # Release zips unpack into <folder>/ffmpeg-<version>-<flavour>/bin/.
        for root in (entry,):
            if os.path.isdir(root):
                for child in sorted(os.listdir(root)):
                    sub = os.path.join(root, child)
                    if os.path.isdir(sub):
                        variants += [os.path.join(sub, "bin", "ffmpeg.exe"),
                                     os.path.join(sub, "ffmpeg.exe")]
        for path in variants:
            if os.path.isfile(path):
                folder = os.path.dirname(path)
                exe = "ffprobe.exe" if path.lower().endswith(".exe") else "ffprobe"
                return path, os.path.join(folder, exe)
    raise SystemExit(
        "ffmpeg not found. Install it or set FFMPEG to the binary (or its folder)."
    )


def duration(path, ffprobe):
    """Length in seconds via ffprobe, or None."""
    if not os.path.isfile(ffprobe):
        return None
    p = subprocess.run(
        [ffprobe, "-v", "error", "-show_entries", "format=duration",
         "-of", "default=noprint_wrappers=1:nokey=1", path],
        capture_output=True, text=True, errors="replace")
    try:
        return float(p.stdout.strip())
    except ValueError:
        return None


def transcode(src, dst, ffmpeg, bitrate="48k", sample_rate=44100, channels=1):
    """Encode src to AAC in an .m4a container. Returns True on success."""
    tmp = dst + ".part.m4a"
    if os.path.exists(tmp):
        os.remove(tmp)
    cmd = [
        ffmpeg, "-hide_banner", "-nostdin", "-y",
        "-i", src,
        "-vn", "-map", "0:a:0",
        "-ac", str(channels),
        "-ar", str(sample_rate),
        "-c:a", "aac", "-profile:a", "aac_low", "-b:a", bitrate,
        "-movflags", "+faststart",
        tmp,
    ]
    p = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    if p.returncode != 0 or not os.path.exists(tmp) or os.path.getsize(tmp) < 1024:
        if os.path.exists(tmp):
            os.remove(tmp)
        sys.stderr.write((p.stderr or "")[-1500:] + "\n")
        return False
    os.replace(tmp, dst)
    return True


def migrate(folder, ffmpeg, ffprobe, bitrate, keep_original, jobs=1):
    files = sorted(f for f in os.listdir(folder)
                   if f.rsplit(".", 1)[-1].lower() in SOURCES)
    todo, skipped, failed = [], [], []
    for name in files:
        stem, ext = os.path.splitext(name)
        ext = ext.lower().lstrip(".")
        if ext in CONVERTED:
            skipped.append((name, "already AAC"))
            continue
        src = os.path.join(folder, name)
        dst = os.path.join(folder, stem + ".m4a")
        if os.path.exists(dst):
            skipped.append((name, "m4a exists"))
            continue
        todo.append((name, src, dst))

    if not todo:
        print("nothing to convert")
        return 0

    total_before = sum(os.path.getsize(s) for _, s, _ in todo)
    print(f"{len(todo)} files, {total_before/1e6:.0f} MB -> AAC {bitrate} mono "
          f"({jobs} at a time)\n")

    def work(item):
        name, src, dst = item
        before = duration(src, ffprobe)
        if not transcode(src, dst, ffmpeg, bitrate=bitrate):
            return name, None, before, "encode failed"
        after = duration(dst, ffprobe)
        if before is not None and after is not None and abs(before - after) > 2.0:
            os.remove(dst)  # truncated or wrong stream: never keep it
            return name, None, before, f"duration {before:.0f}s != {after:.0f}s"
        return name, (dst, os.path.getsize(src), os.path.getsize(dst), after), before, None

    done = []
    with ThreadPoolExecutor(max_workers=max(jobs, 1)) as pool:
        for name, result, _, err in pool.map(work, todo):
            if err:
                failed.append((name, err))
                print(f"  FAILED  {name}: {err}")
                continue
            dst, size_before, size_after, after = result
            if not keep_original:
                os.remove(os.path.join(folder, name))
            done.append((name, dst, size_before, size_after, after or 0))
            print(f"  {os.path.basename(dst):44s} {size_before/1e6:6.1f} -> "
                  f"{size_after/1e6:6.1f} MB   {after/60 if after else 0:5.1f} min")

    if done:
        total_before = sum(d[2] for d in done)
        total_after = sum(d[3] for d in done)
        hours = sum(d[4] for d in done) / 3600
        print(f"\n{len(done)} converted: {total_before/1e6:.0f} MB -> "
              f"{total_after/1e6:.0f} MB "
              f"({100 - total_after / total_before * 100:.0f}% smaller)")
        print(f"average {total_after*8/max(hours*3600,1)/1000:.1f} kbps "
              f"over {hours:.2f} h")
    for name, why in skipped:
        print(f"  skipped {name}: {why}")
    return 0 if not failed else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--input")
    ap.add_argument("--output")
    ap.add_argument("--in-place", metavar="FOLDER")
    ap.add_argument("--bitrate", default="48k")
    ap.add_argument("--jobs", type=int, default=1)
    ap.add_argument("--ffmpeg", help="path to ffmpeg(.exe)")
    ap.add_argument("--keep-original", action="store_true",
                    help="with --in-place, keep the source files")
    args = ap.parse_args()

    ffmpeg, ffprobe = find_ffmpeg(args.ffmpeg)
    print(f"ffmpeg: {ffmpeg}")
    if not os.path.isfile(ffprobe):
        print("warning: ffprobe missing, duration checks are skipped")

    if args.in_place:
        return migrate(args.in_place, ffmpeg, ffprobe, args.bitrate,
                       args.keep_original, args.jobs)
    if not (args.input and args.output):
        ap.error("give --input and --output, or --in-place FOLDER")

    before = duration(args.input, ffprobe)
    if not transcode(args.input, args.output, ffmpeg, bitrate=args.bitrate):
        return 1
    after = duration(args.output, ffprobe)
    a, b = os.path.getsize(args.input), os.path.getsize(args.output)
    print(f"{a/1e6:.2f} MB -> {b/1e6:.2f} MB ({b/a*100:.0f}%)  "
          f"{before or 0:.0f}s -> {after or 0:.0f}s")
    if before and after and abs(before - after) > 2.0:
        print("WARNING: durations differ, do not trust this output")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
