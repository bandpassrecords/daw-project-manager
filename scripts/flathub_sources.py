#!/usr/bin/env python3
"""Does the Flathub repo still build what this release builds?

Flathub's flatpak-external-data-checker bot watches this repo's tags and opens
a PR on flathub/com.bandpassrecords.dpm that changes only the app source's
`tag:` and `commit:`. That builds only while everything else Flathub holds is
still right: the manifest flatpak-flutter wrote, and `generated/` — the
Flutter SDK module and every pub package, vendored for an offline build. A
dependency or Flutter upgrade changes those, the bot's PR keeps the old ones,
and Flathub's build fails (3.0.0: "no versions of device_info_plus match
13.3.0", 2.9.1: "could not find package ffmpeg_kit_flutter_platform_interface").

This compares the build_flatpak job's output (the `flatpak-generated-sources`
artifact: the rewritten manifest and `generated/`) with a checkout of the
Flathub repo, ignoring the tag and commit the bot does bump:

    python scripts/flathub_sources.py <artifact dir> <flathub checkout>

Exit code 0: the bot's PR is enough. 1: the differences are printed, and the
Flathub repo needs this release's files pushed by hand (flatpak/README.md,
"Per-release maintenance"). 2: something to compare is missing.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

MANIFEST = "com.bandpassrecords.dpm.yml"
GENERATED = "generated"

# The app's own source block: its url, then the tag/commit the bot rewrites.
_APP_SOURCE_PIN = re.compile(
    r"^(?P<indent>\s+)(?:tag: \S+|commit: [0-9a-f]{40})\s*$", re.MULTILINE
)


def normalize_manifest(text: str) -> str:
    """The manifest with the app source's tag and commit taken out — the only
    lines the bot's PR changes — and line endings made plain."""
    text = text.replace("\r\n", "\n")
    lines = text.split("\n")
    out: list[str] = []
    in_app_source = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("url:") or stripped.startswith("- type:"):
            in_app_source = "bandpassrecords/daw-project-manager" in stripped
        if in_app_source and _APP_SOURCE_PIN.match(line):
            continue
        out.append(line)
    return "\n".join(out).rstrip("\n") + "\n"


def _read(path: Path) -> str:
    return path.read_bytes().decode("utf-8").replace("\r\n", "\n")


def _generated_files(root: Path) -> dict[str, Path]:
    base = root / GENERATED
    if not base.is_dir():
        return {}
    return {
        p.relative_to(root).as_posix(): p for p in base.rglob("*") if p.is_file()
    }


def _package_names(pubspec_sources: str) -> set[str]:
    """Each vendored pub package as `name-version` (the archive's file name)."""
    names = set()
    for source in json.loads(pubspec_sources):
        if not isinstance(source, dict):
            continue
        url = source.get("url") or ""
        name = url.rsplit("/", 1)[-1]
        if name.endswith(".tar.gz"):
            names.add(name[: -len(".tar.gz")])
    return names


def compare(ours: Path, flathub: Path) -> list[str]:
    """What the Flathub checkout lacks of [ours], as lines for a person to
    read. Empty: only the tag and commit differ."""
    for root in (ours, flathub):
        if not (root / MANIFEST).is_file():
            raise FileNotFoundError(f"no {MANIFEST} in {root}")

    differences: list[str] = []
    if normalize_manifest(_read(ours / MANIFEST)) != normalize_manifest(
        _read(flathub / MANIFEST)
    ):
        differences.append(f"{MANIFEST} differs beyond the app's tag and commit")

    here = _generated_files(ours)
    there = _generated_files(flathub)
    for name in sorted(here.keys() - there.keys()):
        differences.append(f"only in this build: {name}")
    for name in sorted(there.keys() - here.keys()):
        differences.append(f"only on Flathub: {name}")
    for name in sorted(here.keys() & there.keys()):
        a, b = _read(here[name]), _read(there[name])
        if a == b:
            continue
        if name.endswith("pubspec.json"):
            try:
                added = sorted(_package_names(a) - _package_names(b))
                gone = sorted(_package_names(b) - _package_names(a))
            except (ValueError, TypeError):
                added, gone = [], []
            if added or gone:
                differences.append(
                    f"{name}: {len(added)} package(s) Flathub lacks, "
                    f"{len(gone)} it has that this build no longer uses"
                )
                differences.extend(f"  + {n}" for n in added)
                differences.extend(f"  - {n}" for n in gone)
                continue
        differences.append(f"{name} differs")
    return differences


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    try:
        differences = compare(Path(argv[1]), Path(argv[2]))
    except FileNotFoundError as e:
        print(f"error: {e}", file=sys.stderr)
        return 2
    if not differences:
        print("Flathub holds this build's sources: the bot's tag/commit PR is enough.")
        return 0
    print("Flathub's sources are out of date; the bot's tag/commit PR won't build:")
    for line in differences:
        print(f"- {line}" if not line.startswith("  ") else line)
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
