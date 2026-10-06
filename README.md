# DAW Project Manager

Cross-platform app for organizing and tracking music production projects. Scan your drives, manage metadata, track todos, group releases, and sync everything via Google Drive.

Supports **macOS**, **Windows**, **Android** (closed testing).

---

## Features

- **Smart two-phase scanning** — instant file detection, then background deep extraction of BPM, key, and DAW version.
- **Customizable production phases** — rename, reorder, color, and mark phases as "finished"; not limited to a fixed Idea → Finished pipeline.
- **Task Queue** — every open todo across every project in one unified, checkable list.
- **Releases** — group projects into EPs/albums/singles with artwork, description, attached files, and a "download all as ZIP" export.
- **Project & Todo Templates** — spin up new projects pre-filled from a saved template; import reusable todo checklists.
- **Music Player** — a full library player on desktop (queue, shuffle, Camelot-wheel key-compatible auto-queue) and a "Now Playing" screen on mobile, on top of the per-project preview player.
- **Playlists** *(Android/iOS)* — ordered sequences of preview songs for reviewing work on the go.
- **Statistics** — global library dashboard plus per-project phase/activity history.
- **Multiple Profiles** — fully isolated scan roots, projects, and settings per profile.
- **Google Drive sync** *(Windows/macOS/Android/iOS)* — back up metadata, preview songs, and artwork, with an optional auto-backup interval (30 min / hourly / 6-hourly / daily). Not available on Linux (see `flatpak/README.md`); use local backup/restore instead.
- **Background / tray mode** *(desktop)* — keep running after closing the window, with a tray/menu-bar icon for quick backup and work-session controls.
- **Cross-platform sharing** — shares preview songs through the OS share sheet, transcoding to AAC (macOS) or MP3 (Windows, via bundled ffmpeg) when the source format isn't shareable directly.
- **9 languages** — fully localized UI, switchable at any time.

---

## Supported DAWs

| DAW | Extension(s) |
|-----|-------------|
| Ableton Live | `.als`, `.alp` |
| Bitwig Studio | `.bwproject` |
| Cakewalk / Sonar | `.cwp`, `.wrk`, `.bun` |
| Cubase | `.cpr` |
| FL Studio | `.flp` |
| Logic Pro | `.logicx` |
| MAGDA | `.mgd` |
| Maschine | `.maschine`, `.maschine2` |
| Nuendo | `.npr` |
| Pro Tools | `.ptx`, `.pts` |
| Reaper | `.rpp` |
| Studio One | `.song` |
| Tracktion Waveform | `.tracktionedit`, `.tracktion` |
| Universal Audio LUNA | `.luna` |

**Additional DAWs** — detected and scanned like the above, but without automatic BPM/key/version extraction yet (see [Metadata Extraction](#metadata-extraction) below):

| DAW | Extension(s) |
|-----|-------------|
| ACID Pro | `.acd` |
| Adobe Audition | `.sesx` |
| Ardour | `.ardour` |
| Audacity | `.aup3` |
| Digital Performer | `.dpproj` |
| GarageBand | `.band` |
| LMMS | `.mmp`, `.mmpz` |
| Mixcraft | `.mx8`, `.mx9`, `.mx10` |
| Qtractor | `.qtr` |
| Reason | `.reason`, `.rns` |
| Renoise | `.xrns` |
| Rosegarden | `.rg` |
| Samplitude / Sequoia | `.vip` |
| Zrythm | `.zpj` |

Not yet supported: Harrison Mixbus and SAWStudio/Pyramix/Zynewave Podium (no reliably documented file extension), and browser-only tools like BandLab/Soundtrap/Audiotool (no local project file to scan). Missing a DAW? Open an issue.

---

## Metadata Extraction

Deep Scan reads BPM, musical key, DAW version, and (Reaper only) project notes and timeline markers directly from certain project files. For the DAWs marked below it also reads what is *inside* the project: how many tracks of each kind (audio, MIDI, instrument, sampler, groups/FX, folders) and which plug-ins it loads, shown on the project's detail page and searchable from the dashboard (type a plug-in name to find every song that uses it). Everything else needs the field entered manually, or picked up from an optional `bpm.txt`/`key.txt` file dropped next to the project. See **Settings → Metadata Extraction** in the app for the full breakdown by DAW.

| Automatic extraction | BPM | Key | Version | Notes | Markers | Tracks | Plug-ins | MIDI clips |
|---|---|---|---|---|---|---|---|---|
| Ableton Live | ✓ | ✓ | ✓ | | | ✓ | ✓ | ✓ |
| Bitwig Studio | ✓ | ✓ | ✓ | | | | | |
| Cubase / Nuendo | ✓ | ✓ | ✓ | ✓ | | ✓ | ✓ | ✓ |
| FL Studio | ✓ | | ✓ | | | ✓ | ✓ | ✓ |
| Logic Pro *(macOS)* | ✓ | ✓ | ✓ | | | | | |
| MAGDA | ✓ | ✓ | ✓ | | | | | |
| Reaper | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Studio One | ✓ | | ✓ | | | ✓ | | |

**MIDI clips** *(desktop)* — the project's MIDI clips/parts/patterns, read from the project file whenever its metadata is extracted and kept with the project, so they sync to your other devices and phone; listed under the track they sit on, since a clip's own name is often just a DAW default. Each one can be previewed through a simple built-in synth (at the project tempo, or any tempo you set; saved files carry the same tempo; on a seamless loop if you like), opened in a piano roll that zooms around the mouse, with a playback line (click or drag along the bar ruler to jump), the project's scale highlighted (or any scale you pick), and a lane underneath for velocity, pitch bend, controllers (mod wheel, sustain, filter cutoff…), aftertouch or program changes — where notes can also be edited the way Cubase's key editor does it (select, range, eraser and pencil tools, duplicate with Ctrl/Cmd+D, quantize with Q, clips that grow as you draw past their end, a tempo and time signature of their own, a Cubase-style loop region on the ruler, the view scrolling as you drag past its edges, double-click to add or delete, box-select, ↑/↓ to transpose by a semitone or Shift for an octave, drag either edge to resize, Alt-drag to copy, Ctrl to ignore the grid, velocities drawn across many notes at once, finely drawn pitch bend and controller curves, undo), with every shortcut on one cheat sheet (press ?), notes outside the scale shown in orange, a playable keyboard, a full screen mode, notes heard as you edit them if you like, and the instrument switchable from the editor and saved as a new clip in a collection, played with an instrument guessed from the track or clip name (lead, bass, pad, keys, drums… or picked by hand), saved as a standard `.mid` file — controllers, pitch bend and the project's key included (the key is in the file name too) — shared with friends, or dragged straight into another DAW or a folder; **Export all** writes every clip at once. REAPER items that reference an external `.mid` file are read from that file, and the project page warns when a referenced file can't be found. The dashboard can show only projects that contain MIDI.

**MIDI tab** — every unique MIDI clip across all your projects in one place (the same riff in two versions of a song shows once), searchable, filterable by instrument, and arrangeable by tempo to find loops at the BPM you need. Put clips into **collections** ("Psytrance basslines", "Ideas for the EP"): a collection holds copies, so it keeps working whatever happens to the projects, and it can be played, shared or exported as a set. **Import MIDI files** brings `.mid` files from anywhere into a collection (one clip per track, keeping the file's tempo and key), so loops that don't belong to any project can sit next to the ones that do. **New clip** starts a blank clip in a collection, opened in the piano roll with the pencil in hand, to draft an idea from scratch. Collections sync with Drive and go into backups. Clips are compared by their notes, not their names: copies, renamed duplicates and longer clips that only repeat a shorter pattern collapse into one entry with a use count, so what you get is the project's set of unique clips.

All other supported DAWs are detected and scanned but rely on manual entry today.

---

## Getting Started

### Prerequisites

- **Flutter 3.41.9** (stable) — [install](https://docs.flutter.dev/get-started/install)
- Platform tooling:
  - **macOS / iOS** — Xcode (latest)
  - **Windows** — Visual Studio with the "Desktop development with C++" workload
  - **Android** — Android Studio (latest)
  - **Linux** — GTK/GStreamer/libsecret dev headers, plus a C++ toolchain:
    ```bash
    sudo apt-get install -y clang cmake ninja-build pkg-config unzip \
      libgtk-3-dev liblzma-dev libsecret-1-dev libayatana-appindicator3-dev \
      libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
    ```
    (Linux isn't a released platform yet — see `flatpak/README.md` for the
    in-progress Flathub packaging effort — but `flutter run -d linux` works
    for local development.)

### Install and generate

```bash
git clone <repo-url>
cd daw_project_manager

flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
flutter run -d macos       # macOS
flutter run -d windows     # Windows
flutter run -d linux       # Linux
flutter run -d <device-id> # Android or iOS — list with: flutter devices
```

### Google Drive sync (optional, not available on Linux)

Drive sync requires OAuth config injected into `lib/config/oauth_config.dart` (not versioned). This only actually enables Drive sign-in on Windows/macOS/Android/iOS — on Linux the feature is hidden in the UI regardless of what's in this file (see `flatpak/README.md` for why), so there's no need to run this setup step on a Linux dev machine.

**Quickest way — use the setup script:**

```bash
# macOS / Linux
./scripts/setup_local_oauth_config.sh

# Windows
.\scripts\setup_local_oauth_config.ps1
```

The script prompts for your Google Cloud OAuth credentials (`DESKTOP_CLIENT_ID`, `DESKTOP_CLIENT_SECRET`, `ANDROID_WEB_CLIENT_ID`) and writes the file for you. Without it the app runs normally; only Drive features won't authenticate.

---

## Project Structure

```
lib/
├── models/        Hive data models (MusicProject, Release, …)
├── providers/     Riverpod providers and state
├── repository/    Hive box management and data access
├── services/      Scanner, metadata extractor, Drive sync, notifications
├── ui/            Pages: dashboard, project detail, releases, queue, stats
└── utils/         Search, platform helpers, file launcher
```

---

## Common Commands

| Task | Command |
|------|---------|
| Run all tests | `flutter test` |
| Regenerate Hive adapters | `dart run build_runner build --delete-conflicting-outputs` |
| Regenerate localization | `flutter gen-l10n` |
| Add a UI string | Edit `lib/l10n/app_en.arb`, run `flutter gen-l10n` |

---

## Releasing

Push a version tag to trigger the CI release workflow:

```bash
git tag v1.2.3
git push origin v1.2.3
```

CI outputs: macOS `.dmg`, Windows `.msix`, Android `.apk` and `.aab`.

Required GitHub secrets: `DESKTOP_CLIENT_ID`, `DESKTOP_CLIENT_SECRET`, `ANDROID_WEB_CLIENT_ID`.
