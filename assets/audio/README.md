# Bundled recordings

Put the audio files you want to ship inside the app in this folder, then rebuild.

Supported extensions: `mp3`, `m4a`, `aac`, `wav`, `ogg`, `opus`, `flac`.
`.m4a` (AAC) is recommended: it is roughly 60% smaller than the original
128 kbps mono MP3s and plays on every Android version the app supports.

```powershell
# shrink the bundled audio in place (verifies length, then removes the MP3)
python tool\convert_audio.py --in-place assets\audio --bitrate 48k --jobs 3
```

`tool\convert_audio.py` needs ffmpeg: install it, or point `FFMPEG` at the
binary. It refuses to keep an encode whose duration does not match the source.

Each file must already contain the Quran recitation followed by its Chichewa
translation. Do not split the two parts. Werenga plays the file unchanged.

Any supported audio file in this folder is added to the library automatically.
Metadata is optional. To set a display title or Surah details, add an entry to
`recordings.json`:

```json
[
  {
    "file": "al-fatihah.mp3",
    "title": "Al-Fatihah",
    "surahName": "Al-Fatihah",
    "surahNumber": 1,
    "verseRange": "1–7",
    "durationMs": 180000
  }
]
```

- `file`: file name in this folder, or the full `assets/audio/...` path.
- `durationMs`: optional; if omitted, the duration is learned on first playback.
- All metadata fields except `file` are optional.

After adding files, run:

```powershell
# number and title the files from their names -> recordings.json
python tool\audio_metadata.py

flutter run
# or
flutter build apk --release
```

`tool\audio_metadata.py` recognises the surah in each file name and records its
verified `surahNumber`, which puts the home screen and library in mushaf order.
Names it cannot identify unambiguously are left unnumbered (the title then comes
from the file name) rather than being guessed.

Bundled audio becomes part of the APK, so keep files compressed and intentional.
Only bundle recordings you have the right to distribute. See the project
`README.md` for the full recording and packaging guide.
