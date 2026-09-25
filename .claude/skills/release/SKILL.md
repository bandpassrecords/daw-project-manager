---
name: release
description: Cut a DAW Project Manager release end to end. Writes the in-app changelog entry and the Flatpak metainfo entry, verifies the CI version gates, publishes the GitHub release (which creates the tag and starts release.yml), watches the pipeline, and if it fails deletes the release and tag, diagnoses the failed jobs, fixes, commits, pushes and tries again until every build is green. Use when the user says "release", "cut a release", "release 2.10.0", "ship vX.Y.Z", or "publish a new version".
argument-hint: "[X.Y.Z]"
---

# Release

Carries a release from "the code is on `main`" to "every asset is on the
GitHub release". Two checkpoints need the user, both at the start:

1. the version number, and
2. the notes: the in-app changelog highlights plus the GitHub release notes.

Once the user has said go, keep going on your own through the pipeline,
failures and retries, reporting as you go.

## How releasing works in this repo (read first)

- **The GitHub release has to exist before the builds finish.** Every build job
  in `.github/workflows/release.yml` ends with `getReleaseByTag` and uploads its
  asset to that release. With no release it fails with "Please create a Release
  manually on GitHub matching this tag before pushing the tag".
  - So **never push a bare tag.** Create the release with `gh release create`,
    which creates the tag on the remote, and that tag push starts the workflow
    (a v2.8.0 release created at 23:17:27 had its run start at 23:17:29).
- **Two version gates** in the `Unit Tests` job must both match the tag:
  - the newest `<release version>` in
    `flatpak/com.bandpassrecords.dpm.metainfo.xml`, which the Flatpak build also
    reads `APP_VERSION` from;
  - the newest entry in `assets/changelog/changelog.json`, which is bundled
    because the Flatpak build has no network.

  `prepare_release.py` (next to this file) writes the metainfo entry and checks
  both gates locally.
- `pubspec.yaml` stays at `version: 0.0.0+0`. CI stamps the version from the
  tag, so don't change it.
- **What a tag run builds:** Unit Tests, then Windows (exe + MSIX), macOS
  (DMG + ZIP), Linux (AppImage + tar.gz), Flatpak, Android (AAB), an iOS
  compile check, and the gh-pages download link. It takes about **15 minutes**.
- **Retries are safe.** Nothing is published outside the GitHub release, and
  there is no store upload that would reject a reused version code. Deleting
  a failed release and its tag, then recreating them, leaves nothing behind.
- **Use the `gh` client first.** For anything that reads or changes GitHub —
  tags, releases, runs, logs, PRs, the remote state of `main`, comparing
  commits — use `gh` (or `gh api`), not `git`.
  - Fall back to `git` only where `gh` has no equivalent: staging,
    committing, pushing commits, and removing a local tag.
  - No default repo is set for `gh` here and the checkout has several
    remotes (`bp`, `origin`, `http`), so **always pass
    `-R bandpassrecords/daw-project-manager`**. `gh api` paths spell out
    `repos/bandpassrecords/daw-project-manager/…`.
- **Remote:** when `git` is needed, always `bp`, never `origin`.
  **Repo:** `bandpassrecords/daw-project-manager`.
- **Commits:** follow the user's global rules. No `Co-Authored-By:` trailer and
  no "Generated with Claude Code" footer, in commits and in the release notes.

## 1. Version and pre-flight

- Version: from `$ARGUMENTS` if given (strip a leading `v`). Otherwise:
  - Newest **remote** tag:
    ```
    gh api repos/bandpassrecords/daw-project-manager/git/matching-refs/tags/v \
      --jq '.[].ref | sub("refs/tags/"; "")' | sort -V | tail -1
    ```
  - Always ask GitHub, not local `git tag`: local-only test tags such as
    `v9.9.9` exist here and would make every real version look old.
  - If the newest `changelog.json` entry is ahead of that tag, it's the
    version being released. Otherwise propose a patch or minor bump from the
    changes since the last tag, and ask.
- It must be `X.Y.Z` and higher than the newest remote tag. Neither a
  release nor a tag may exist for it yet; both of these must fail (404):
  - `gh release view vX.Y.Z -R bandpassrecords/daw-project-manager`
  - `gh api repos/bandpassrecords/daw-project-manager/git/ref/tags/vX.Y.Z`
- **Release from `main`**, or from `release/vX.Y.Z` for a fix to an
  already-released version.
  - `git checkout main`, then bring it up to date with
    `gh repo sync --source bandpassrecords/daw-project-manager --branch main`.
  - That sync refuses to overwrite diverged local commits. If it refuses,
    stop and report rather than forcing it.
  - If the work the user means to ship sits on an unmerged PR branch
    (`gh pr list -R bandpassrecords/daw-project-manager --state open`), stop
    and say so. Merging it is their call.
- The working tree must be clean apart from `android/local.properties` and
  `flatpak/shared-modules`. Those are always dirty here and are never
  committed.

## 2. Notes (checkpoint: user approval)

Collect what changed since the last tag:

- The commits:
  ```
  gh api repos/bandpassrecords/daw-project-manager/compare/<last-tag>...main \
    --jq '.commits[] | select(.parents | length == 1) | .commit.message'
  ```
  Paginate with `--paginate` if the compare reports more than 250 commits.
- The merged PRs:
  ```
  gh pr list -R bandpassrecords/daw-project-manager --state merged --base main \
    --search "merged:>=<date of last tag>" --json number,title,body
  ```
- The date of the last tag comes from
  `gh release view <last-tag> -R bandpassrecords/daw-project-manager --json publishedAt`.

Draft two things and show them together:

- **In-app changelog highlights** (`changelog.json`, English)
  - One short sentence per change a musician using the app would notice.
    Match the tone of the existing entries.
  - Leave out refactors, CI, tests and dependency bumps.
  - If an entry for this version already exists (they are often written
    during development), show it and ask if it's final rather than rewriting
    it.
- **GitHub release notes**, in the same shape as previous releases
  (`gh release view <last-tag> --json body`):
  - `### Highlights` — bold-lead bullets, e.g.
    `- **Name of the thing** — what it does for the user.`
  - `---`
  - One `### <Area>` section per theme, with more detailed bullets.

Wait for the user's OK or edits. Then write the changelog entry:

- `python scripts/new_changelog_entry.py X.Y.Z --highlight "…"` (repeat
  `--highlight`; use `--replace` to amend an existing entry).
- Translations are optional: a missing locale falls back to English. The `pt`
  locale is **Brazilian** Portuguese (see CLAUDE.md).

Save the GitHub notes to a scratch file for step 4.

## 3. Prepare and verify the commit

```
python .claude/skills/release/prepare_release.py X.Y.Z --dry-run
python .claude/skills/release/prepare_release.py X.Y.Z
```

- The script adds the metainfo `<release>` entry, built from the changelog's
  English highlights, which Flathub shows as the version's changelog.
- It moves the store screenshot URL to the new tag, but only if that image is
  committed with content. Flathub rejects a broken screenshot URL.
- It exits non-zero, with the reason, if either gate would still fail.
- Running it again is harmless.

Then:

- `git diff`: only the metainfo and `changelog.json` should have changed.
- `flutter analyze`, then the full `flutter test` (CLAUDE.md requires it before
  every commit).
  - Background both to a file with the compact reporter.
  - A failure here would fail `Unit Tests` in CI too, so fix it (see step 6)
    before going on.
- Commit only those two files as `Prepare release vX.Y.Z`, then
  `git push bp main`. `gh` can't push commits, so this is `git`.
- Confirm GitHub has it before publishing:
  `gh api repos/bandpassrecords/daw-project-manager/commits/main --jq .sha`
  must equal `git rev-parse HEAD`.

## 4. Publish

```
gh release create vX.Y.Z -R bandpassrecords/daw-project-manager \
  --target <sha of the pushed commit> --title vX.Y.Z --notes-file <notes file>
```

- Use `--target` with the exact SHA, not `main`, so a later push can't slip
  into the tag.
- Find the run it started:
  ```
  gh run list -R bandpassrecords/daw-project-manager --workflow release.yml \
    --branch vX.Y.Z --limit 1 --json databaseId,createdAt,status
  ```
  - Don't add `--event push`: combined with `--branch` it matches nothing,
    even though tag runs are push events.
  - Runs come newest first, and a retried tag has one run per attempt.
    Only accept a run whose `createdAt` is after this attempt's release was
    published.
  - It can take a few seconds to appear; poll briefly.

## 5. Watch the pipeline

- Watch in the background, since the run takes about 15 minutes:
  `gh run watch <run-id> -R bandpassrecords/daw-project-manager --exit-status`
  with `run_in_background`.
- Tell the user it's running and roughly when it should finish.
- When it finishes:
  - **Success:** check that every asset arrived. Compare against the
    previous release with the version swapped:
    ```
    gh release view <prev-tag> -R bandpassrecords/daw-project-manager --json assets --jq '.assets[].name' | sed 's/<prev-tag>/vX.Y.Z/' | sort > expected
    gh release view vX.Y.Z   -R bandpassrecords/daw-project-manager --json assets --jq '.assets[].name' | sort > actual
    diff expected actual
    ```
    A missing asset counts as a failure. An extra one is fine: it's a new
    build target. Then report the release URL, its assets and how many
    attempts it took. Done.
  - **Failure:** go to step 6.

## 6. When a run fails

1. **Diagnose:** `gh run view <run-id> -R bandpassrecords/daw-project-manager --log-failed`.
   Name the failing job and step and quote the actual error.
2. **Sort out what kind of failure it is.**

   **Transient** (runner lost, network timeout, a download or service
   hiccup, rate limit):
   - Nothing to fix and nothing to delete. The release still exists, so run
     `gh run rerun <run-id> --failed` and go back to step 5.
   - Do this at most twice for the same job, then treat it as real.

   **Needs something only the user can do** (a missing or expired secret —
   see `.github/REQUIRED_SECRETS.md` — a signing certificate, an Apple or
   Google account problem):
   - **Stop.** Report exactly what's needed.
   - Don't delete the release: once they fix it, a `--failed` rerun
     finishes it.

   **A real problem in the repo** (test failure, version gate, build error,
   workflow bug):
   - Delete the release **and** its tag, so the fix can be tagged:
     ```
     gh release delete vX.Y.Z -R bandpassrecords/daw-project-manager --cleanup-tag --yes
     gh api repos/bandpassrecords/daw-project-manager/git/ref/tags/vX.Y.Z   # must now 404
     git tag -d vX.Y.Z 2>/dev/null   # a local copy, if one was fetched; gh can't remove it
     ```
     If `--cleanup-tag` left the tag behind, remove it with
     `gh api -X DELETE repos/bandpassrecords/daw-project-manager/git/refs/tags/vX.Y.Z`.
   - Fix the root cause on `main`. Follow CLAUDE.md as for any fix, including
     a regression test when it's a code bug.
   - Reproduce locally where you can: `flutter test`, `flutter analyze`,
     `prepare_release.py X.Y.Z --check`, a local build.
   - Run the full test suite, commit the fix on its own (a normal descriptive
     message, not "fix release"), and `git push bp main`.
   - Confirm the push landed with
     `gh api repos/bandpassrecords/daw-project-manager/commits/main --jq .sha`.
   - Go back to step 4 with the new SHA. The notes don't change unless the
     fix is something users would notice.
3. **Stop after 3 attempts that each needed a code fix.** Report what each
   attempt changed and the current error, and ask how to proceed. Delete
   the half-finished release first, so the repo isn't left with a failed
   release marked Latest.

Keep the user posted at each transition: the release is published, the run
has failed (and why), a fix has been pushed, a retry has started, and the
release is done.

## Afterwards

- The Flathub side (`tag:`/`commit:` bump) is a PR the
  flatpak-external-data-checker bot opens on the Flathub repo by itself. There
  is nothing to do here.
- If a tag had to be deleted after being public for a while, mention that the
  bot may have opened a PR for the dead tag. It should be closed on Flathub's
  side.
