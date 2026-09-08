import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/custom_theme.dart';

/// Reads and writes single-theme `.dpmtheme` files.
///
/// This is how themes are shared: there is no server and no gallery, just a
/// small JSON file a user can send to someone else.
class ThemeFileService {
  ThemeFileService._();

  /// Marker so a file that merely happens to be JSON is rejected instead of
  /// importing as a theme full of fallback colors.
  static const String fileType = 'dpm-theme';
  static const int fileVersion = 1;
  static const String fileExtension = 'dpmtheme';

  static String encode(CustomTheme theme) {
    return const JsonEncoder.withIndent('  ').convert({
      'type': fileType,
      'version': fileVersion,
      'theme': theme.toJson(),
    });
  }

  /// Parses a `.dpmtheme` document.
  ///
  /// Returns null for anything that isn't one. The imported theme always gets
  /// a **new** id: importing the same file twice yields two themes rather
  /// than silently overwriting one the user has since edited.
  static CustomTheme? decode(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return null;
      if (decoded['type'] != fileType) return null;
      final raw = decoded['theme'];
      if (raw is! Map) return null;

      final now = DateTime.now();
      final theme = CustomTheme.fromJson({
        ...Map<String, dynamic>.from(raw),
        'id': const Uuid().v4(),
      });
      return theme.copyWith(updatedAt: now);
    } catch (_) {
      return null;
    }
  }

  /// Writes [theme] to a file the user picks. Returns null if cancelled.
  static Future<File?> export(
    CustomTheme theme, {
    required String dialogTitle,
    required String fallbackName,
  }) async {
    final safeName = (theme.name?.trim().isNotEmpty ?? false)
        ? theme.name!.trim().replaceAll(RegExp(r'[^\w\- ]'), '_')
        : fallbackName;

    final path = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: '$safeName.$fileExtension',
      type: FileType.custom,
      allowedExtensions: [fileExtension],
    );
    if (path == null) return null;

    final file = File(path);
    await file.writeAsString(encode(theme));
    return file;
  }

  /// Prompts for a `.dpmtheme` file and parses it.
  ///
  /// Returns null both when the user cancels and when the file isn't a valid
  /// theme — the caller distinguishes them by whether a file was chosen, so
  /// cancelling doesn't raise an error toast.
  static Future<ThemeImportResult> import({required String dialogTitle}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [fileExtension],
      dialogTitle: dialogTitle,
    );
    final path = result?.files.single.path;
    if (path == null) return const ThemeImportResult.cancelled();

    try {
      final theme = decode(await File(path).readAsString());
      return theme == null
          ? const ThemeImportResult.invalid()
          : ThemeImportResult.imported(theme);
    } catch (_) {
      return const ThemeImportResult.invalid();
    }
  }
}

/// Outcome of [ThemeFileService.import].
class ThemeImportResult {
  final CustomTheme? theme;
  final bool wasCancelled;

  const ThemeImportResult.imported(CustomTheme this.theme)
      : wasCancelled = false;
  const ThemeImportResult.cancelled()
      : theme = null,
        wasCancelled = true;
  const ThemeImportResult.invalid()
      : theme = null,
        wasCancelled = false;

  bool get isInvalid => theme == null && !wasCancelled;
}
