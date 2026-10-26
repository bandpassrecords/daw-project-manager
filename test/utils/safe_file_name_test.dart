import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/utils/safe_file_name.dart';

void main() {
  final folder = p.join(Directory.systemTemp.path, 'dpm_safe', 'project_cover_art');

  group('safeFileIn', () {
    test('a plain name lands in the folder', () {
      expect(
        safeFileIn(folder, '3f2a9c1e-0b7d-4c8e-9a51-2d6f0e8b4c11_cover.jpg'),
        p.join(folder, '3f2a9c1e-0b7d-4c8e-9a51-2d6f0e8b4c11_cover.jpg'),
      );
      expect(safeFileIn(folder, 'demo-project-night-drive_cover.png'), isNotNull);
    });

    test('a name that climbs out of the folder is refused', () {
      expect(safeFileIn(folder, r'..\..\Startup\x_cover.bat'), isNull);
      expect(safeFileIn(folder, '../../.config/autostart/x_cover.desktop'), isNull);
      expect(safeFileIn(folder, '..'), isNull);
      expect(safeFileIn(folder, '.'), isNull);
    });

    test('a name naming another folder or a drive is refused', () {
      expect(safeFileIn(folder, 'sub/x.jpg'), isNull);
      expect(safeFileIn(folder, r'C:\Windows\x.jpg'), isNull);
      expect(safeFileIn(folder, '/etc/x.jpg'), isNull);
      // An alternate data stream on Windows.
      expect(safeFileIn(folder, 'x.jpg:hidden'), isNull);
    });

    test('empty, control characters and over-long names are refused', () {
      expect(safeFileIn(folder, ''), isNull);
      expect(safeFileIn(folder, 'x\u0000.jpg'), isNull);
      expect(safeFileIn(folder, 'x\n.jpg'), isNull);
      expect(safeFileIn(folder, '${'a' * 201}.jpg'), isNull);
    });

    test('dots inside a name are only a name', () {
      expect(safeFileIn(folder, '.._cover.jpg'), p.join(folder, '.._cover.jpg'));
    });
  });

  group('safeExtension', () {
    test('a plain extension is kept', () {
      expect(safeExtension('.png', fallback: '.jpg'), '.png');
      expect(safeExtension('.FLAC', fallback: '.mp3'), '.FLAC');
    });

    test('anything else falls back', () {
      expect(safeExtension(null, fallback: '.jpg'), '.jpg');
      expect(safeExtension('', fallback: '.jpg'), '.jpg');
      expect(safeExtension('png', fallback: '.jpg'), '.jpg');
      expect(safeExtension(r'.jpg\..\..\x', fallback: '.jpg'), '.jpg');
      expect(safeExtension('.b:stream', fallback: '.jpg'), '.jpg');
      expect(safeExtension('.waytoolongextension', fallback: '.jpg'), '.jpg');
    });
  });
}
