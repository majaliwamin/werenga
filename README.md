# Werenga

**Qur'an · Chichewa**

Werenga is a quiet, entirely offline Android library for listening to Quran
recitation followed by its Chichewa translation. Each recording is a single
audio file supplied by you. Werenga never splits, re-records, translates,
mixes or otherwise alters that audio.

The interface uses a classical Islamic visual language: emerald and parchment,
antique gold, eight-point stars, mihrab arches and locally bundled Cormorant
Garamond and Manrope typefaces. It includes a dashboard, local library,
listening history, full player, shared mini-player, import flow and light/dark
themes.

---

## Features

- **Offline by design** — the release manifest has no `INTERNET` permission.
  Recordings, listening positions, history and preferences stay on the device.
- **One shared player** — the full player and mini-player use the same audio
  session, so navigating between tabs never restarts or duplicates playback.
- **Complete recordings** — a file contains the Arabic recitation followed by
  its Chichewa meaning. Werenga plays it exactly as supplied.
- **Local library** — search, filter (all / in progress / completed), sort,
  resume positions, completion marks and removal of imported files.
- **Flexible importing** — pick recordings with the system file picker, review
  and correct their titles and optional Surah details, then copy them into the
  app's private storage. SHA-256 duplicate detection avoids importing the same
  file twice.
- **Bundled recordings** — drop supported audio into `assets/audio/` and rebuild.
  Files are discovered automatically; optional metadata lives in
  `assets/audio/recordings.json`.
- **Privacy-first history** — listening dates, positions and completion stay in
  a local SQLite database and can be cleared at any time.
- **Thoughtful playback** — audio focus, interruptions, headphone unplug,
  seek, restart, previous/next, completion handling and saved positions.
- **Light and dark themes**, with system, light or dark selection.

## Requirements

There are two ways to work with Werenga. You do **not** need a local Android
SDK, Android Studio or JDK just to get an installable APK.

**Editing and testing on this computer**

- Flutter 3.47.2 / Dart 3.13.2
- Internet access for the initial dependency download
- Around 2 GB of free RAM for analysis and tests

**Building the APK (cloud, recommended)**

- A free GitHub account and internet access
- Nothing else: GitHub's runner supplies JDK 21, the Android SDK and Gradle

```powershell
flutter doctor
flutter pub get
```

## Build the APK in the cloud

`.github/workflows/android.yml` runs static analysis, the test suite and both
APK builds on a GitHub-hosted runner, then publishes installable artifacts. This
keeps Gradle off a low-memory laptop entirely.

1. Create an empty repository on GitHub (no README, no `.gitignore`).
2. Commit and push this folder (it is already initialized as a Git repository):

```powershell
git config user.name "YOUR NAME"
git config user.email "you@example.com"
git commit -m "Werenga: offline Quran + Chichewa audio library"
git remote add origin https://github.com/YOUR-USERNAME/werenga.git
git push -u origin main
```

If you copy the project somewhere without its `.git` folder, run
`git init -b main` and `git add .` first.

3. Open the repository's **Actions** tab → **Android APK** → newest run.
4. Under **Artifacts**, download `werenga-release-apk` (or
   `werenga-debug-apk`), unzip it and copy the `.apk` to your phone.

Builds also start on every push to `main`, or manually through
**Actions → Android APK → Run workflow**. Artifacts are kept for 30 days.
Public repositories build without a usage limit; private repositories get 2,000
free runner-minutes per month, and the workflow takes roughly 10 minutes.

The release APK is signed with the debug key, which is fine for personal
sideloading. For public distribution see [Release signing](#release-signing) and
store the keystore in repository secrets, never in the source tree.

## Run and build locally (optional)

Local builds need Android SDK 36 and JDK 21, and are slow on an 8 GB machine.

```powershell
# Run on a connected Android device or emulator
flutter run

# Static analysis and tests (no Gradle involved)
dart analyze
flutter test --no-pub

# Debug or release APK
flutter build apk --debug
flutter build apk --release
```

The APK is written to `build\app\outputs\flutter-apk\`. For a smaller,
ABI-specific APK use `flutter build apk --release --split-per-abi`.

`android/gradle.properties` caps the Gradle daemon at 3 GB (`-Xmx3G`) and the
Kotlin daemon at 1.5 GB. The Flutter template default of `-Xmx8G` cannot be
honoured on an 8 GB laptop, where it causes swapping and apparent hangs. Raise
those values only on a machine with more memory.

### Browser preview (optional)

The app also builds for the browser, where the library lives in memory for the
session and importing is disabled. Bundled files in `assets/audio/` are still
listed and played, which makes this a quick way to check a recording without
assembling an APK.

```powershell
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run --no-source-maps
python tool\publish_web.py                  # build\web -> build\site
python tool\serve_web.py build\site 8080
# open http://127.0.0.1:8080
```

Use `tool\serve_web.py` rather than `python -m http.server`: the browser needs
HTTP Range requests to seek inside a recording, and the stock server always
replies with the whole file. Rebuild and refresh the page after adding audio;
there is no hot reload in this mode.

Serve `build\site`, not `build\web`. The server holds a handle on the folder it
serves, so a build into `build\web` was impossible while the preview was open:
stopping the server first left any open tab fetching from a dead port
(`ERR_CONNECTION_REFUSED` for every audio file, plus an uncaught error in
Flutter's shader loader). `tool\publish_web.py` copies the finished build into
`build\site`, so you can rebuild and re-publish with the page still open, then
just refresh. It also carries over `tool\samples\`, the audio-quality
comparison page at `/samples/`.

`--no-web-resources-cdn` is required, not optional. Without it the release build
loads the CanvasKit engine from `www.gstatic.com`, so the preview dies on a
blocked, metered or offline connection with `ERR_CONNECTION_CLOSED` and
`Failed to fetch`, even though every app asset is local. The flag copies
`canvaskit/` into `build\web\` and points the loader at it.

## Adding recordings

### Option 1 — import inside the app (recommended)

1. Open **Library** or **Settings** and tap **Add**.
2. Select one or more supported audio files.
3. Review the suggested title and, if you know them, add the Surah name,
   Surah number and Ayah range.
4. Tap **Import**.

Werenga copies each file into its private application storage, probes the
duration, records a SHA-256 hash, and adds the recording to the library. The
original file on your device is left untouched. Removing an imported recording
from Werenga deletes only Werenga's copy.

Supported extensions: **MP3, M4A, AAC, WAV, OGG, OPUS, FLAC**. M4A (AAC) is the
recommended format: it plays on every Android version the app supports and is
about 60% smaller than the equivalent mono MP3 for speech.

To shrink files that are already bundled, convert them in place:

```powershell
python tool\convert_audio.py --in-place assets\audio --bitrate 48k --jobs 3
```

The converter needs ffmpeg on `PATH` (or `FFMPEG` set to the binary), keeps the
original length in a container that seeks cleanly, and deletes a source only
after the encode is verified.

### Option 2 — bundle recordings into the APK

1. Put audio files in `assets/audio/`.
2. Optionally describe them in `assets/audio/recordings.json`.
3. Rebuild the app (`flutter run` or `flutter build apk`).

Any supported audio file in `assets/audio/` is registered automatically, even
without metadata. The title then comes from the file name.

Filenames whose prefixes do not match the surah they contain (for example a
recording of Al-Mujaadalah named `01-...`) would otherwise appear out of mushaf
order. To number and title the collection from the filenames, run:

```bash
python tool/audio_metadata.py
```

It writes `assets/audio/recordings.json` with a verified `surahNumber` for every
file it can identify unambiguously, and leaves anything uncertain alone rather
than guessing. The home screen and library both sort by that number
(**Mushaf order**), with unmatched files listed alphabetically afterwards.

Example `assets/audio/recordings.json`:

```json
[
  {
    "file": "al-fatihah.mp3",
    "title": "Al-Fatihah",
    "surahName": "Al-Fatihah",
    "surahNumber": 1,
    "verseRange": "1–7",
    "durationMs": 180000
  },
  {
    "file": "al-ikhlas.mp3",
    "title": "Al-Ikhlas",
    "surahName": "Al-Ikhlas",
    "surahNumber": 112,
    "durationMs": 95000
  }
]
```

- `file` may be just the file name or the full asset path
  (`assets/audio/al-fatihah.mp3`).
- `title`, `surahName`, `surahNumber`, `verseRange` and `durationMs` are all
  optional. Missing durations are learned when the recording is played.
- An object form is also accepted: `{ "recordings": [ ... ] }`.
- Bundled files increase APK size. Prefer mono AAC (`.m4a`) at 48–64 kbps and
  keep the collection intentional.
- Do not include Quranic Arabic text unless you have a verified source; the app
  is deliberately audio-first and does not ship scripture text or calligraphy.

## Recording guidance

Werenga expects recordings that already exist and that you have the right to
use.

- Use one file per complete listening item.
- The order inside the file is **recitation first, then the Chichewa
  translation**, as described on the splash and player screens.
- Keep both parts in the same file. Do not split the Arabic and Chichewa into
  separate recordings for the same item.
- Consistent loudness and a clean ending make consecutive listening pleasant.
- Name files clearly (for example `al-fatihah.mp3`) so automatic titles are
  useful.
- Quran recitation and translations remain the property of their respective
  owners. Werenga does not generate, translate, verify or redistribute audio.

## Where data lives

- Imported audio: the app's private application-support `recordings/` folder.
- Library, listening positions and history: a local SQLite database
  (`werenga.db`).
- Theme and resume preferences: the same local database.
- Bundled recordings: inside the APK, read-only.

Clearing Android app data or uninstalling Werenga removes imported audio, the
database and preferences. Back up any recordings you cannot re-import.

## Offline and privacy guarantees

- `android/app/src/main/AndroidManifest.xml` contains **no** network permission.
- Debug and profile manifests add `INTERNET` only because Flutter's development
  tooling requires it for hot reload and debugging. Release builds do not.
- There are no accounts, ads, analytics, cloud services, remote audio URLs or
  telemetry.
- The app reads only audio you explicitly select or files bundled at build time.

## Project structure

```text
.github/workflows/            Cloud APK build (analysis, tests, packaging)
lib/
  app.dart                     Root app, providers, splash-to-shell transition
  main.dart                    Startup, font licenses, failure screen
  core/
    theme/                     Colors, tokens, light/dark themes
    utils/                     Duration, size, date and title formatting
    widgets/                   Emblem, ornaments, shared controls, recording tile
  data/
    db/                        SQLite schema and connection
    models/                    Recording model and library queries
    repositories/              RecordingStore boundary + SQLite implementation
    services/                  Asset sync, importing/audio probe, settings store
  features/
    splash/                    Animated brand splash
    shell/                     Bottom navigation and mini-player host
    dashboard/                 Featured recording, stats, recent listening
    library/                   Search/filter/sort/import/review/remove
    history/                   Grouped local listening history
    player/                    Full player + shared mini-player
    settings/                  Appearance, playback, storage, privacy, about
  state/                       Bootstrap, library, playback, preferences
assets/
  audio/                       Bundled recordings + optional metadata
  brand/                       Emblem, launcher and splash artwork
  fonts/                       Local Cormorant Garamond and Manrope
  licenses/                    SIL Open Font License texts
android/                       Android host and native splash/icon configuration
test/                          Query, controller, formatter and widget tests
tool/                          Headless-Chrome artwork sources
```

## Testing and verification

```powershell
dart analyze
flutter test --no-pub
```

- Earlier local runs: analysis clean apart from four minor style infos, and all
  31 unit and widget tests passing.
- The **Android APK** workflow re-runs analysis and the full test suite on every
  push, so a commit is verified on the runner before its APK is published.
- The APK is not assembled on this 8 GB laptop, where Gradle competes with the
  Dart toolchain for memory. The cloud workflow is the packaging path.
- Browser preview checked with the first bundled recording: it is listed on the
  landing page, plays, and seeks (HTTP Range) in Chrome. This exercises the same
  library, player and asset-manifest code paths as the APK.

Runtime audio output, seek behaviour, audio focus/interruption handling and
file-picker behaviour depend on the Android device and the supplied files. Test
with your actual recordings on the target phone before distributing.

## Troubleshooting

**The library is empty** — Werenga ships no audio. Import recordings or add
them to `assets/audio/` and rebuild.

**A recording says “File not found on this device”** — the imported copy was
deleted by a storage cleaner, restore operation or manual cleanup. Remove the
entry and import the file again.

**A file cannot be imported or played** — confirm the extension is supported
and that the file plays in another Android app. Some nominally supported
containers use codecs Android cannot decode. Re-encode to mono AAC (`.m4a`) or
MP3 if necessary.

**The file picker does not open** — update the app and Android System WebView /
Files app, then try again. On Android 13+, the system picker does not require
storage permissions.

**A local build stalls at “Generating Gradle API jar”** — Gradle is swapping.
Werenga already caps the daemon at 3 GB in `android/gradle.properties`; close
other memory-heavy apps, or use the cloud workflow above instead.

**Where is the APK?** — If you used the cloud workflow, open the run in GitHub
**Actions**, scroll to **Artifacts** and download `werenga-release-apk`. A local
build writes it to `build\app\outputs\flutter-apk\`.

**`flutter build apk` fails** — run `flutter doctor`, accept Android licenses
with `flutter doctor --android-licenses`, and ensure Gradle can reach Google
Maven and Maven Central for the first build.

**Release APK installs as a debug-signed build** — that is intentional for
personal sideloading. Configure a private keystore for public distribution.

## Release signing

For public distribution, create a keystore and configure release signing:

```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\werenga-release.jks" `
  -keyalg RSA -keysize 2048 -validity 10000 -alias werenga
```

Create `android/key.properties` (never commit it):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=werenga
storeFile=C:/Users/YOU/werenga-release.jks
```

Then replace the debug signing config in `android/app/build.gradle.kts` with a
release config that loads `key.properties`. Keep backups of the keystore and
passwords; losing them prevents future updates to an installed app.

## Licenses

The bundled Cormorant Garamond and Manrope fonts are licensed under the SIL Open
Font License. Their license texts are in `assets/licenses/` and are also
available from **Settings → Open source licenses**. Flutter and package licenses
are available from the same screen.

Recordings are not included. All supplied recordings remain the property of
their respective owners.
