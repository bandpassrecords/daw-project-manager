# Flatpak packaging

Target: submission to Flathub (not just a self-hosted `.flatpak` bundle), so
this has to satisfy Flathub's review bar — a reproducible, network-free
build, AppStream metadata, and minimal/justified sandbox permissions.

Everything here was authored on Windows, where none of the Flatpak tooling
can actually run — so the `build_flatpak` job in
`.github/workflows/release.yml` is the actual first test of this pipeline,
on every PR and tag push. It runs `flatpak-flutter` to vendor the Flutter SDK
and every `pubspec.lock` package as hashed sources, then builds
`com.bandpassrecords.dpm.yml` offline with `flatpak-builder` — the same shape
of build Flathub's own infrastructure will eventually run. `flatpak-flutter`'s
exact CLI/output conventions were taken from its README, not verified by
running it, so expect the first CI run to need a round of debugging from the
Actions log (the job is marked `continue-on-error` for exactly this reason —
it won't block the other platform builds while that happens).

## Files in this directory

| File | Purpose |
|---|---|
| `com.bandpassrecords.dpm.yml` | The Flatpak manifest — actually a *template* for `flatpak-flutter` (see above), not the final buildable manifest. |
| `com.bandpassrecords.dpm.desktop` | Desktop entry (app menu, launcher, taskbar). |
| `com.bandpassrecords.dpm.metainfo.xml` | AppStream metadata Flathub uses for the store listing. Manually maintained — bump the screenshot URL's tag and add a new `<release>` entry on every release (see that file's own comment). The Flatpak build reads `APP_VERSION` straight from this file's newest `<release version="...">` (see the daw-project-manager module's build-commands in `com.bandpassrecords.dpm.yml`) rather than deriving it from git, deliberately — so it doesn't depend on git tags/history being present in whatever environment ends up building it. `unit_tests`' "Verify metainfo.xml version matches the tag" step fails the release workflow if this file is forgotten before tagging. |
| `icons/com.bandpassrecords.dpm_{128,256}.png` | Derived from `app_icon.png`. No scalable/SVG source exists in the repo; Flathub accepts raster-only, but a vector icon is preferred if one ever gets made. |

## Outstanding blockers before this can be submitted

### 1. Domain verification (bandpassrecords.com)

`com.bandpassrecords.dpm.metainfo.xml` declares `<developer id="com.bandpassrecords">`
(not just the app's own `com.bandpassrecords.dpm` id), so Flathub verifies at
the **developer**-id level, not the app-id level — reversing
`com.bandpassrecords` gives the bare `bandpassrecords.com`, not the
`dpm.bandpassrecords.com` subdomain this section used to say. (An earlier
version of this doc assumed app-id-level verification, i.e. the subdomain;
Flathub's own submission-bot comment on the PR is what confirmed it actually
checks the bare domain here — trust that live signal over this doc if they
ever disagree again.) This happens *after* the PR is merged, via Flathub's
"manage app" verification flow — it doesn't block opening the submission PR,
but does block it going live.

Upload the **empty** `flatpak/org.flathub.VerifiedApps.txt` (already created
in this directory — note it's `org.flathub`, not `org.flatpak`; Flathub's own
bot comment names the exact filename it's looking for, so re-check that
against whatever it says if this is ever redone) to:

```
https://bandpassrecords.com/.well-known/org.flathub.VerifiedApps.txt
```

Then, on the Flathub developer portal for this app, choose "Website"
verification and point it at `bandpassrecords.com` — it checks for that file.

### 2. Screenshots are 0-byte placeholders

`resources/screenshots/**/*.png` (see `resources/screenshots/README.md`) are
placeholder files, not real captures. The metainfo's `<screenshots>` block
points at `dashboard/dashboard-overview.png` on the `v2.6.2` tag (bumped
ahead of `v2.6.1`, since that's the version this screenshot is expected to
ship in) — Flathub's linter fetches that URL and will fail the submission on
a broken image until the real file exists at that tag. Capture the
screenshot, replace the file in place, and cut `v2.6.2`.

### 3. Vendoring the Flutter SDK + pub packages — now automated in CI

Flathub builds are sandboxed with no network access, and `org.freedesktop.Sdk`
doesn't include Flutter — so the manifest needs every dependency pinned as a
hashed source up front: the Flutter SDK itself, plus every package in
`pubspec.lock`. This is what `build_flatpak` does in CI now (see above) via
[`flatpak-flutter`](https://github.com/TheAppgineer/flatpak-flutter) — nothing
to do by hand for a PR/tag build.

To reproduce the same thing locally (Linux/WSL2 only, e.g. to debug a CI
failure faster than round-tripping through Actions):

```bash
# Pin to the same flatpak-flutter release CI uses (FLATPAK_FLUTTER_VERSION in
# .github/workflows/release.yml) — not master, so an upstream change there
# can't break this build with no warning. Check that value before running
# this if it's been a while.
git clone --depth 1 --branch 0.15.0 https://github.com/TheAppgineer/flatpak-flutter.git /tmp/flatpak-flutter
pip install -r /tmp/flatpak-flutter/requirements.txt
cd flatpak
python3 /tmp/flatpak-flutter/flatpak-flutter.py com.bandpassrecords.dpm.yml
```

That rewrites the manifest in place with the Flutter SDK module wired in and
writes `pubspec-sources.json` alongside it — check `git diff` here before
committing anything, since this working copy's `git` source (pinned to the
`v2.6.2` tag) is what a real Flathub build needs; CI instead repoints that
same `git` source at the exact commit under test (`github.sha`), so it can
validate PRs before a release tag exists. Don't commit the CI-only commit
swap.

## Local build/test (Linux/WSL2 only)

```bash
sudo apt install flatpak flatpak-builder
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# after running flatpak-flutter as above:
flatpak-builder --repo=repo --force-clean --sandbox --user \
  --install-deps-from=flathub build com.bandpassrecords.dpm.yml
flatpak-builder --run build com.bandpassrecords.dpm.yml daw_project_manager
```

No OAuth credentials to set up for this build at all — Google Drive sync
isn't offered inside a Flatpak sandbox (see `GoogleDriveSyncService.isSupported`
in `lib/services/google_drive_sync_service.dart`), so the manifest's
build-commands generate a placeholder `lib/config/oauth_config.dart` straight
from the committed template. See "Why Google Drive sync isn't offered in
Flatpak" below for the reasoning, and `lib/services/backup_service.dart` for
the local-file backup/restore Flatpak uses instead.

Things that can only be verified this way (not from Windows, not by reading
the code):

- **System tray icon** (`tray_manager`) — appindicator support inside a
  Flatpak sandbox is inconsistent across desktop environments; confirm it at
  least degrades gracefully where there's no `StatusNotifierWatcher` running.
- **Notifications** — confirm deadline reminders actually show up via
  `org.freedesktop.portal.Notification` (`lib/services/linux_portal_notifier.dart`),
  now that this goes through the portal instead of
  `flutter_local_notifications`' Linux backend.
- **Drag-and-drop** (`desktop_drop`) — there's no mature portal for DnD yet;
  worth confirming dropping a project folder onto the window still works
  sandboxed.

## Why Google Drive sync isn't offered in Flatpak

The desktop OAuth flow needs a client secret — confirmed against a live
Google sign-in attempt, Google's token endpoint rejects the exchange without
one for this app's "Desktop app" OAuth client type, even with PKCE (Google's
docs list `client_secret` as "not applicable" only for Android/iOS/Chrome-app
client types, not Desktop). That's fine for Windows/macOS and the plain
Linux tarball/AppImage, none of which ever distribute the secret outside
this repo's own CI (`build_linux` injects it the same way the other
platforms do — see `lib/config/README.md`). It's not something to accept for
Flathub specifically, since its build sandbox has no secret-injection
mechanism at all — the file would have to be committed in the open in the
public Flathub submission repo. Rather than ship a secret that broadly,
`GoogleDriveSyncService.isSupported` is `false` only when actually running
inside the Flatpak sandbox (detected via the `/.flatpak-info` marker file),
and every UI entry point (dashboard, profile page, the startup dialog, the
tray menu) is gated on it. `BackupService`'s local JSON export/import covers
the same user data instead for Flatpak users (extended in lockstep with this
decision — see its own history for what that covers).

## Submitting to Flathub

1. **Get the submission bundle from CI, don't hand-assemble it.** Every
   `build_flatpak` run uploads a `flatpak-generated-sources` artifact
   containing exactly what needs to go into the Flathub repo:
   - `com.bandpassrecords.dpm.yml` — the *rewritten* manifest (Flutter SDK
     module wired in, `pubspec-sources.json` etc. appended) — not the
     template version in this directory.
   - `generated/` — the vendored modules/sources/patches that manifest
     references.

   That's it — no OAuth config file to worry about. Google Drive sync isn't
   offered inside Flatpak at all (see "Why Google Drive sync isn't offered
   in Flatpak" above), so the manifest's build-commands generate a
   placeholder `oauth_config.dart` from the already-public template at build
   time; there was never anything here that needed to stay out of a public
   artifact.

   Download it from a run **on the actual release tag** you're submitting
   (not a PR run) — that's what makes the manifest's `commit:` match a real,
   permanent release rather than a moving PR head. On a tag-triggered run the
   substitution step also keeps a `tag: vX.Y.Z` line alongside `commit:`
   (a PR run has no tag yet, so it's `commit:`-only there) — nothing to add
   back by hand.

2. Fork [flathub/flathub](https://github.com/flathub/flathub) and use their
   "New app" request flow to get a repository created at
   `flathub/com.bandpassrecords.dpm`.

3. Push the two items from the artifact into that repo's root (so
   `generated/` sits next to the manifest, matching the relative paths the
   manifest's sources use).

4. **Also add the `shared-modules` submodule at that repo's root** — the
   `libappindicator` module entry (`shared-modules/libappindicator/libappindicator-gtk3-12.10.json`)
   isn't something `flatpak-flutter` rewrites or vendors into `generated/`;
   it's a relative reference straight into this submodule, same as in this
   directory (see `.gitmodules` at the repo root here). Skipping this step
   is exactly what produces `flatpak-builder-lint`'s
   `Failed to load included manifest (.../shared-modules/libappindicator/libappindicator-gtk3-12.10.json): No such file or directory`
   during the Flathub PR's own CI:

   ```bash
   git submodule add https://github.com/flathub/shared-modules.git shared-modules
   git submodule update --init
   ```

   Pin it to the same commit this repo's `flatpak/shared-modules` is on
   (`git -C flatpak/shared-modules rev-parse HEAD` from this repo) unless a
   newer `shared-modules` release is preferred.

5. Open the PR.

6. Their CI builds it and a human reviewer checks the `finish-args` — be
   ready to justify the D-Bus `--talk-name`s above if asked; the comments
   already in the manifest cover the reasoning for each. There's no
   `--device=all` either: MIDI keyboards in the piano roll would need it
   (the ALSA sequencer, `/dev/snd/seq`, has no narrower `--device`), so
   MIDI input is switched off inside the sandbox
   (`MidiInputBackend.isSupported`) instead of granted it. There's no
   `--share=network` to justify — both things that would have needed it are
   switched off instead of granted the permission: Drive sync specifically
   inside the Flatpak sandbox (`GoogleDriveSyncService.isSupported`) and the
   GitHub-releases update check on Linux generally
   (`UpdateCheckService.isSupported`, unrelated to the secret-injection story
   above — it's a network-sandboxing choice, not something the tarball/AppImage
   builds have reopened).

Per-release maintenance of the Flathub manifest:

- The app source carries `x-checker-data`, so Flathub's
  flatpak-external-data-checker bot watches this repo for new `v*` tags and
  automatically opens a PR on the Flathub repo bumping `tag:`/`commit:`.
  **That PR changes nothing else**, so it builds only while the Flathub
  repo's manifest and `generated/` still match what this release generates.
  Any dependency upgrade (a new `pubspec.lock`), a new Flutter version, or a
  manifest change breaks that, and Flathub's offline build then fails — for
  3.0.0, `no versions of device_info_plus match 13.3.0`; for 2.9.1,
  `could not find package ffmpeg_kit_flutter_platform_interface`.
- So after every release, compare the tag run's `flatpak-generated-sources`
  artifact with the Flathub repo (`build_flatpak`'s "Compare with the sources
  Flathub builds from" step already does, and warns; by hand:
  `python scripts/flathub_sources.py <artifact dir> <flathub checkout>`).
  - **Same** (exit 0): merge the bot's PR.
  - **Different** (exit 1): on a branch of the Flathub repo, replace
    `com.bandpassrecords.dpm.yml` and `generated/` with the artifact's (step
    3 above), open a PR ("Update to vX.Y.Z", as flathub#3 and #7 were), and
    close the bot's PR as superseded once Flathub's test build passes. The
    artifact is kept 14 days.
- The one manual step, on this repo's side, before tagging a release: add a
  new `<release version="X.Y.Z" date="...">` entry to
  `com.bandpassrecords.dpm.metainfo.xml` (Flathub surfaces these as the
  changelog) and update the screenshot URL's tag. `APP_VERSION` for the
  Flatpak build is read straight from that file rather than from git (see
  the file table above for why), so this also decides what version the
  Linux build reports. `unit_tests`' "Verify metainfo.xml version matches
  the tag" step fails the whole release workflow — for every platform, not
  just Linux — if this is forgotten before pushing the tag.
