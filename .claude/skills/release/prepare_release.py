#!/usr/bin/env python3
"""Bump everything a release tag is checked against, then verify it.

Used by the release skill (see SKILL.md next to this file).

`.github/workflows/release.yml` fails a tag build unless, for tag vX.Y.Z:
  1. the newest <release version="..."> in
     flatpak/com.bandpassrecords.dpm.metainfo.xml is X.Y.Z — the Flatpak
     build also reads APP_VERSION from it, so a stale entry would ship a
     Linux build reporting the wrong version; and
  2. the newest entry in assets/changelog/changelog.json is X.Y.Z.

This script owns (1) and checks (2). The changelog entry itself is written
with scripts/new_changelog_entry.py, because its highlights need a human.

Usage:
    python .claude/skills/release/prepare_release.py 2.9.0
    python .claude/skills/release/prepare_release.py 2.9.0 --check
    python .claude/skills/release/prepare_release.py 2.9.0 --dry-run

Exit status is non-zero whenever the tag would still fail CI.
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import subprocess
import sys
from xml.sax.saxutils import escape

METAINFO = os.path.join("flatpak", "com.bandpassrecords.dpm.metainfo.xml")
CHANGELOG = os.path.join("assets", "changelog", "changelog.json")
REPO_URL = "https://github.com/bandpassrecords/daw-project-manager"

VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")
RELEASE_RE = re.compile(r'<release version="([^"]+)"')
SCREENSHOT_RE = re.compile(
    r"(https://raw\.githubusercontent\.com/bandpassrecords/daw-project-manager/)"
    r"(v\d+\.\d+\.\d+)(/)([^<\s]+)"
)


def vkey(v: str) -> tuple[int, int, int]:
    a, b, c = (int(x) for x in v.split("."))
    return a, b, c


def read(path: str) -> str:
    with open(path, "r", encoding="utf-8", newline="") as f:
        return f.read()


def write(path: str, text: str) -> None:
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(text)


def newest_metainfo_version(text: str) -> str | None:
    """What CI reads: the first <release version=...> in the file."""
    m = RELEASE_RE.search(text)
    return m.group(1) if m else None


def changelog_releases(root: str) -> list[dict]:
    with open(os.path.join(root, CHANGELOG), "r", encoding="utf-8") as f:
        return json.load(f).get("releases", [])


def release_block(version: str, date: str, highlights: list[str], indent: str,
                  nl: str) -> str:
    """A <release> entry in the same shape as the ones already in the file.

    Flathub shows the description as the version's changelog, so it carries
    the English highlights from changelog.json when there are any.
    """
    i1, i2, i3 = indent, indent + "  ", indent + "    "
    lines = [f'{i1}<release version="{version}" date="{date}">',
             f"{i2}<description>"]
    if highlights:
        lines.append(f"{i3}<ul>")
        lines += [f"{i3}  <li>{escape(h)}</li>" for h in highlights]
        lines.append(f"{i3}</ul>")
    else:
        lines.append(f"{i3}<p>See the GitHub release notes for details.</p>")
    lines += [f"{i2}</description>",
              f"{i2}<url>{REPO_URL}/releases/tag/v{version}</url>",
              f"{i1}</release>"]
    return nl.join(lines) + nl


def tracked_non_empty(root: str, path: str) -> bool:
    """Whether [path] is committed at HEAD with real content — i.e. whether
    the raw.githubusercontent URL for the new tag will resolve."""
    try:
        out = subprocess.run(
            ["git", "cat-file", "-s", f"HEAD:{path}"],
            cwd=root, capture_output=True, text=True, check=True,
        ).stdout.strip()
        return int(out) > 0
    except (subprocess.CalledProcessError, ValueError, FileNotFoundError):
        return False


def bump_metainfo(root: str, version: str, date: str,
                  highlights: list[str]) -> tuple[str, list[str]]:
    """Returns the new metainfo text and a list of human-readable notes."""
    path = os.path.join(root, METAINFO)
    text = read(path)
    nl = "\r\n" if "\r\n" in text else "\n"
    notes: list[str] = []

    top = newest_metainfo_version(text)
    if top == version:
        notes.append(f"metainfo already has v{version} as its newest release "
                     "- left as is")
    else:
        if f'<release version="{version}"' in text:
            sys.exit(f"error: metainfo lists {version}, but not as the newest "
                     f"release (newest is {top}). Fix the file by hand.")
        if top and vkey(version) < vkey(top):
            sys.exit(f"error: {version} is older than the newest metainfo "
                     f"release {top}.")
        m = re.search(r'(?m)^([ \t]*)<release version="', text)
        if not m:
            sys.exit("error: no <release> entry found in the metainfo to "
                     "insert above.")
        block = release_block(version, date, highlights, m.group(1), nl)
        text = text[:m.start()] + block + text[m.start():]
        notes.append(f"metainfo: added <release version=\"{version}\" "
                     f"date=\"{date}\"> above {top}"
                     + (f" with {len(highlights)} highlight(s)"
                        if highlights else ""))

    # The store screenshot is served from a tag. Move it to the new tag only
    # when the image is committed with content, or Flathub's validator gets a
    # broken image and rejects the submission.
    def repoint(m: re.Match) -> str:
        old_tag, rel_path = m.group(2), m.group(4)
        new_tag = f"v{version}"
        if old_tag == new_tag:
            return m.group(0)
        if not tracked_non_empty(root, rel_path):
            notes.append(f"screenshot {rel_path}: not committed with content "
                         f"at HEAD - left on {old_tag}")
            return m.group(0)
        notes.append(f"screenshot {rel_path}: {old_tag} -> {new_tag}")
        return m.group(1) + new_tag + m.group(3) + rel_path

    text = SCREENSHOT_RE.sub(repoint, text)
    return text, notes


def verify(root: str, version: str) -> list[str]:
    """The two release.yml gates, run locally. Empty list == would pass."""
    problems = []
    meta = newest_metainfo_version(read(os.path.join(root, METAINFO)))
    if meta != version:
        problems.append(f"metainfo newest release is {meta}, tag would be "
                        f"v{version}")
    releases = changelog_releases(root)
    newest = releases[0]["version"] if releases else None
    if newest != version:
        problems.append(
            f"changelog.json newest entry is {newest}, tag would be "
            f"v{version} - run: python scripts/new_changelog_entry.py "
            f'{version} --highlight "..."')
    return problems


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("version", help="X.Y.Z, without the v")
    ap.add_argument("--date", default=datetime.date.today().isoformat(),
                    help="release date for the metainfo entry (YYYY-MM-DD)")
    ap.add_argument("--check", action="store_true",
                    help="only run the CI gates; change nothing")
    ap.add_argument("--dry-run", action="store_true",
                    help="show what would change; write nothing")
    ap.add_argument("--root", default=".", help="repository root")
    args = ap.parse_args()

    version = args.version.lstrip("v")
    if not VERSION_RE.match(version):
        sys.exit(f"error: version must be X.Y.Z (got {args.version})")
    root = args.root

    if not args.check:
        entry = next((r for r in changelog_releases(root)
                      if r.get("version") == version), None)
        highlights = []
        if entry:
            highlights = (entry.get("highlights") or {}).get("en") or []
        text, notes = bump_metainfo(root, version, args.date, highlights)
        for n in notes:
            print(("[dry-run] " if args.dry_run else "") + n)
        if not args.dry_run:
            write(os.path.join(root, METAINFO), text)

    if args.dry_run:
        return 0
    problems = verify(root, version)
    if problems:
        print("\nv%s would FAIL release.yml:" % version)
        for p in problems:
            print("  - " + p)
        return 1
    print(f"\nv{version} passes both release.yml version gates "
          "(metainfo + changelog).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
