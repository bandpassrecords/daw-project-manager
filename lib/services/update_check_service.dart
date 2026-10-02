import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'appimage_update_service.dart';

/// GitHub repo to check for releases. Set via --dart-define at build time.
const String _kGithubOwner = String.fromEnvironment('GITHUB_OWNER', defaultValue: 'bandpassrecords');
const String _kGithubRepo  = String.fromEnvironment('GITHUB_REPO',  defaultValue: 'daw-project-manager');

class UpdateCheckService {
  /// False on Linux, EXCEPT when running as the AppImage build — this pings
  /// the GitHub releases API and, if newer, either self-updates in place
  /// (AppImage; see AppImageUpdateService) or links out to the release page
  /// to download an installer. Linking out is the wrong pattern under
  /// Flatpak: Flathub already owns update delivery (`flatpak update`, the
  /// software center), and a GitHub release page isn't even the right place
  /// to send a Flatpak user — and the plain tarball build has no reliable
  /// way to tell itself apart from Flatpak at runtime, so both stay opted
  /// out here. AppImages, by contrast, always set the `APPIMAGE` env var, so
  /// they can be identified precisely and offered a real self-update.
  /// Every UI entry point (startup check, Settings, onboarding toggle) is
  /// gated on this, which is also what lets the Flatpak manifest drop
  /// --share=network entirely — see flatpak/README.md.
  static bool get isSupported => !Platform.isLinux || AppImageUpdateService.isRunningAsAppImage;

  /// Whether the check that runs by itself at startup should run for this
  /// build. It never does in a debug build, nor in any build still carrying
  /// the `0.0.0` placeholder version — a local `flutter build` without
  /// `--dart-define=APP_VERSION` — since every published release is newer
  /// than that and a developer would get the "update available" popup on
  /// every launch. Release CI always sets the real version, so shipped
  /// builds are unaffected; the manual "Check now" in Settings still works
  /// everywhere.
  static bool shouldCheckAtStartup(String currentVersion, {bool isDebug = kDebugMode}) =>
      !isDebug && !isDevelopmentVersion(currentVersion);

  /// True for the `0.0.0` placeholder (with or without a `+build` suffix).
  static bool isDevelopmentVersion(String version) =>
      _parse(version.split('+').first).every((n) => n == 0);

  /// Returns the latest tag name (e.g. "v1.2.3") if it is strictly newer than
  /// [currentVersion], or null if the app is up-to-date or the check fails.
  static Future<String?> checkForUpdate(String currentVersion) async {
    if (_kGithubOwner.isEmpty || _kGithubRepo.isEmpty) return null;
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_kGithubOwner/$_kGithubRepo/releases/latest',
      );
      final response = await http.get(uri, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?)?.replaceAll(RegExp(r'^v'), '') ?? '';
      if (tag.isEmpty) return null;
      if (_isNewer(tag, currentVersion)) return tag;
      return null;
    } catch (e) {
      if (kDebugMode) print('[UpdateCheck] error: $e');
      return null;
    }
  }

  /// Returns true if [remote] semver is strictly greater than [local].
  static bool _isNewer(String remote, String local) {
    final r = _parse(remote);
    final l = _parse(local);
    for (int i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String v) {
    final parts = v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) { parts.add(0); }
    return parts;
  }
}
