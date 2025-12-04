import 'dart:io';

import 'package:path/path.dart' as p;

class ScannerService {
  static const supportedExtensions = {
    '.als', // Ableton
    '.cpr', // Cubase
    '.flp', // FL Studio
    '.logicx', // Logic Pro (bundle on macOS)
  };

  bool _isInBackupFolder(String path) {
    final segments = p.split(path);
    return segments.any((s) => s.toLowerCase() == 'backup');
  }

  Stream<FileSystemEntity> scanDirectory(String rootPath) async* {
    final directory = Directory(rootPath);
    if (!await directory.exists()) return;

    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (!supportedExtensions.contains(ext)) continue;

        // Ignore Ableton backup projects (typically under a Backup folder)
        if (ext == '.als' && _isInBackupFolder(entity.path)) {
          continue;
        }

        yield entity;
      } else if (entity is Directory) {
        // Logic Pro projects present as .logicx bundles (directories)
        if (entity.path.toLowerCase().endsWith('.logicx')) {
          yield entity;
        }
      }
    }
  }
}


