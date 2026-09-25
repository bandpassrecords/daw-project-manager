#!/usr/bin/env python3
"""Add (or update) a release entry in assets/changelog/changelog.json.

Run this BEFORE tagging a release. The app ships the changelog as an asset so
the "What's New" dialog and Settings > About > Changelog work offline and
inside Flatpak, whose manifest has no network access at all — which means the
entry has to exist in the commit being tagged, not be fetched from the GitHub
release afterwards. `.github/workflows/release.yml` fails the release if the
newest entry doesn't match the tag.

Usage:
    python scripts/new_changelog_entry.py 2.9.0 \
        --highlight "Short, user-facing sentence." \
        --highlight "One line per change worth mentioning."

    # Amend the entry that's already there (replaces its highlights):
    python scripts/new_changelog_entry.py 2.9.0 --replace --highlight "..."

    # Fill in a translation once it comes back:
    python scripts/new_changelog_entry.py 2.9.0 --locale pt --highlight "..."

Only `en` is required. Locales left out fall back to English at runtime, so
shipping before the translations land is fine.
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import sys

CHANGELOG_PATH = os.path.join("assets", "changelog", "changelog.json")

# The locales the app ships in — see lib/l10n/. Used only to reject typos in
# --locale; nothing here has to be present in an entry.
KNOWN_LOCALES = {"en", "pt", "es", "fr", "de", "it", "ru", "ja", "zh"}

VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")


def version_key(version: str) -> tuple[int, int, int]:
    parts = [int(p) for p in version.split(".")]
    return (parts[0], parts[1], parts[2])


def load(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save(path: str, data: dict) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("version", help="Bare semver, e.g. 2.9.0 (no leading v)")
    parser.add_argument("--highlight", action="append", default=[],
                        help="One user-facing line. Repeat for each highlight.")
    parser.add_argument("--locale", default="en",
                        help="Locale these highlights are written in (default: en)")
    parser.add_argument("--date", default=None,
                        help="Release date YYYY-MM-DD (default: today)")
    parser.add_argument("--replace", action="store_true",
                        help="Replace this locale's highlights instead of appending")
    parser.add_argument("--path", default=CHANGELOG_PATH,
                        help=f"Changelog file (default: {CHANGELOG_PATH})")
    args = parser.parse_args()

    version = args.version.lstrip("v").strip()
    if not VERSION_RE.match(version):
        print(f"error: '{args.version}' is not a bare semver like 2.9.0", file=sys.stderr)
        return 2
    if args.locale not in KNOWN_LOCALES:
        print(f"error: unknown locale '{args.locale}'. Known: {', '.join(sorted(KNOWN_LOCALES))}",
              file=sys.stderr)
        return 2
    highlights = [h.strip() for h in args.highlight if h.strip()]
    if not highlights:
        print("error: at least one --highlight is required", file=sys.stderr)
        return 2

    date = args.date or datetime.date.today().isoformat()
    try:
        datetime.date.fromisoformat(date)
    except ValueError:
        print(f"error: --date '{date}' is not YYYY-MM-DD", file=sys.stderr)
        return 2

    data = load(args.path)
    releases = data.setdefault("releases", [])

    entry = next((r for r in releases if r.get("version") == version), None)
    if entry is None:
        entry = {"version": version, "date": date, "highlights": {}}
        releases.append(entry)
    else:
        entry["date"] = date

    by_locale = entry.setdefault("highlights", {})
    if args.replace or args.locale not in by_locale:
        by_locale[args.locale] = highlights
    else:
        by_locale[args.locale].extend(highlights)

    # Newest first, matching how the app renders it and how a reader expects
    # to find the latest release without scrolling.
    releases.sort(key=lambda r: version_key(r["version"]), reverse=True)
    save(args.path, data)

    print(f"Wrote {len(by_locale[args.locale])} {args.locale} highlight(s) for {version} "
          f"to {args.path}")
    if args.locale == "en":
        missing = sorted(KNOWN_LOCALES - set(by_locale) - {"en"})
        if missing:
            print(f"Note: no translation yet for {', '.join(missing)} — "
                  f"those locales will show the English text.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
