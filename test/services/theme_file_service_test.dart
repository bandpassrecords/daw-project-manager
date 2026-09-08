import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/custom_theme.dart';
import 'package:daw_project_manager/services/theme_file_service.dart';

/// `.dpmtheme` is how themes get shared, so it has to reject junk without
/// throwing and never overwrite an existing theme on import (#148).
void main() {
  final source = CustomTheme(
    id: 'original-id',
    name: 'Studio Amber',
    brightness: Brightness.dark,
    primary: const Color(0xFFFFCA28),
    secondary: const Color(0xFFFF7043),
    background: const Color(0xFF14161A),
    card: const Color(0xFF232529),
    cardRadius: 10,
    controlRadius: 6,
    updatedAt: DateTime(2026, 3, 1),
  );

  group('encode/decode', () {
    test('a round trip keeps every editable value', () {
      final decoded = ThemeFileService.decode(ThemeFileService.encode(source))!;

      expect(decoded.name, 'Studio Amber');
      expect(decoded.primary, source.primary);
      expect(decoded.secondary, source.secondary);
      expect(decoded.background, source.background);
      expect(decoded.card, source.card);
      expect(decoded.cardRadius, 10);
      expect(decoded.controlRadius, 6);
      expect(decoded.brightness, Brightness.dark);
    });

    test('an imported theme always gets a new id', () {
      // Importing the same file twice has to give two themes, not silently
      // overwrite one the user has since edited.
      final first = ThemeFileService.decode(ThemeFileService.encode(source))!;
      final second = ThemeFileService.decode(ThemeFileService.encode(source))!;

      expect(first.id, isNot('original-id'));
      expect(second.id, isNot('original-id'));
      expect(first.id, isNot(second.id));
    });

    test('an imported theme is not marked built-in', () {
      final decoded = ThemeFileService.decode(ThemeFileService.encode(source))!;
      expect(decoded.isBuiltIn, isFalse);
    });
  });

  group('decode rejects anything that is not a theme file', () {
    test('malformed JSON', () {
      expect(ThemeFileService.decode('{ not json'), isNull);
    });

    test('JSON that is not an object', () {
      expect(ThemeFileService.decode('[1, 2, 3]'), isNull);
    });

    test('an object without the type marker', () {
      // A backup file is also JSON with a "version" — without the marker it
      // would import as a theme full of fallback colors.
      expect(
        ThemeFileService.decode(jsonEncode({'version': 1, 'theme': {}})),
        isNull,
      );
    });

    test('the wrong type marker', () {
      expect(
        ThemeFileService.decode(
          jsonEncode({'type': 'something-else', 'theme': source.toJson()}),
        ),
        isNull,
      );
    });

    test('a missing theme body', () {
      expect(
        ThemeFileService.decode(
          jsonEncode({'type': ThemeFileService.fileType, 'version': 1}),
        ),
        isNull,
      );
    });
  });

  test('the encoded document carries its type and version', () {
    final decoded =
        jsonDecode(ThemeFileService.encode(source)) as Map<String, dynamic>;
    expect(decoded['type'], ThemeFileService.fileType);
    expect(decoded['version'], ThemeFileService.fileVersion);
    expect(decoded['theme'], isA<Map>());
  });
}
