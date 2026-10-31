"""Tests for flathub_sources.py: python -m unittest discover -s scripts -p "test_*.py"."""

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import flathub_sources as fs  # noqa: E402

MANIFEST = """\
app-id: com.bandpassrecords.dpm
modules:
  - name: daw-project-manager
    sources:
      - type: git
        url: https://github.com/bandpassrecords/daw-project-manager.git
        tag: {tag}
        commit: {commit}
        x-checker-data:
          type: git
          tag-pattern: ^v([\\d.]+)$
      - type: git
        url: https://github.com/flutter/flutter.git
        tag: '{flutter}'
        dest: flutter
      - generated/sources/pubspec.json
    modules:
      - generated/modules/flutter-sdk-{flutter}.json
"""


def pubspec(*packages):
    return json.dumps(
        [
            {
                "type": "archive",
                "url": f"https://pub.dev/api/archives/{p}.tar.gz",
                "dest": f".pub-cache/hosted/pub.dev/{p}",
            }
            for p in packages
        ]
    )


def write_tree(root, *, tag, commit, flutter, packages, newline="\n"):
    root.mkdir(parents=True, exist_ok=True)
    text = MANIFEST.format(tag=tag, commit=commit, flutter=flutter)
    (root / fs.MANIFEST).write_bytes(text.replace("\n", newline).encode())
    gen = root / "generated"
    (gen / "modules").mkdir(parents=True, exist_ok=True)
    (gen / "sources").mkdir(parents=True, exist_ok=True)
    (gen / "modules" / f"flutter-sdk-{flutter}.json").write_text("{}")
    (gen / "sources" / "pubspec.json").write_text(pubspec(*packages))


class CompareTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.ours = Path(self._tmp.name) / "ours"
        self.flathub = Path(self._tmp.name) / "flathub"

    def test_only_tag_and_commit_differ_is_enough(self):
        write_tree(self.ours, tag="v3.0.1", commit="a" * 40, flutter="3.47.7",
                   packages=["device_info_plus-13.3.0"])
        # Flathub's checkout also has CRLF endings on Windows.
        write_tree(self.flathub, tag="v3.0.0", commit="b" * 40, flutter="3.47.7",
                   packages=["device_info_plus-13.3.0"], newline="\r\n")
        self.assertEqual(fs.compare(self.ours, self.flathub), [])

    def test_a_package_upgrade_is_reported_by_name(self):
        # 3.0.0's case: device_info_plus 13.3.0 here, 11.5.0 on Flathub.
        write_tree(self.ours, tag="v3.0.0", commit="a" * 40, flutter="3.47.7",
                   packages=["device_info_plus-13.3.0", "path-1.9.1"])
        write_tree(self.flathub, tag="v2.9.3", commit="b" * 40, flutter="3.47.7",
                   packages=["device_info_plus-11.5.0", "path-1.9.1"])
        diff = fs.compare(self.ours, self.flathub)
        self.assertIn("  + device_info_plus-13.3.0", diff)
        self.assertIn("  - device_info_plus-11.5.0", diff)
        self.assertNotIn("  + path-1.9.1", diff)

    def test_a_flutter_upgrade_is_reported(self):
        write_tree(self.ours, tag="v3.0.0", commit="a" * 40, flutter="3.47.7",
                   packages=["x-1.0.0"])
        write_tree(self.flathub, tag="v2.9.3", commit="b" * 40, flutter="3.41.9",
                   packages=["x-1.0.0"])
        diff = fs.compare(self.ours, self.flathub)
        # The manifest names the Flutter tag and module: not the bot's lines.
        self.assertIn(f"{fs.MANIFEST} differs beyond the app's tag and commit", diff)
        self.assertIn("only in this build: generated/modules/flutter-sdk-3.47.7.json", diff)
        self.assertIn("only on Flathub: generated/modules/flutter-sdk-3.41.9.json", diff)

    def test_a_manifest_change_the_bot_would_drop_is_reported(self):
        write_tree(self.ours, tag="v3.0.1", commit="a" * 40, flutter="3.47.7",
                   packages=["x-1.0.0"])
        write_tree(self.flathub, tag="v3.0.0", commit="b" * 40, flutter="3.47.7",
                   packages=["x-1.0.0"])
        manifest = self.ours / fs.MANIFEST
        manifest.write_text(manifest.read_text().replace(
            "app-id: com.bandpassrecords.dpm\n",
            "app-id: com.bandpassrecords.dpm\nfinish-args:\n  - --share=ipc\n"))
        self.assertEqual(fs.compare(self.ours, self.flathub),
                         [f"{fs.MANIFEST} differs beyond the app's tag and commit"])

    def test_the_flutter_sources_tag_is_not_ignored(self):
        text = MANIFEST.format(tag="v1.0.0", commit="c" * 40, flutter="3.47.7")
        normalized = fs.normalize_manifest(text)
        self.assertNotIn("tag: v1.0.0", normalized)
        self.assertNotIn("commit: " + "c" * 40, normalized)
        self.assertIn("tag: '3.47.7'", normalized)
        self.assertIn("tag-pattern:", normalized)

    def test_exit_codes(self):
        write_tree(self.ours, tag="v3.0.1", commit="a" * 40, flutter="3.47.7",
                   packages=["x-1.0.0"])
        write_tree(self.flathub, tag="v3.0.0", commit="b" * 40, flutter="3.47.7",
                   packages=["x-1.0.0"])
        self.assertEqual(fs.main(["", str(self.ours), str(self.flathub)]), 0)
        (self.ours / "generated" / "sources" / "pubspec.json").write_text(
            pubspec("x-1.0.1"))
        self.assertEqual(fs.main(["", str(self.ours), str(self.flathub)]), 1)
        self.assertEqual(fs.main(["", str(self.ours), str(self.ours / "nope")]), 2)


if __name__ == "__main__":
    unittest.main()
