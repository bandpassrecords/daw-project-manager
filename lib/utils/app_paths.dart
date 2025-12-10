import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Gets the LocalAppData directory path for the application.
/// On Windows, this returns %LocalAppData%\daw_project_manager
/// On other platforms, it returns the application support directory.
Future<String> getLocalAppDataPath() async {
  if (Platform.isWindows) {
    // On Windows, use LOCALAPPDATA environment variable
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final appDir = Directory(path.join(localAppData, 'daw_project_manager'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      return appDir.path;
    }
    // Fallback to application support directory if LOCALAPPDATA is not available
    final appSupportDir = await getApplicationSupportDirectory();
    return appSupportDir.path;
  } else {
    // On other platforms, use application support directory
    final appSupportDir = await getApplicationSupportDirectory();
    return appSupportDir.path;
  }
}

/// Gets the path for release files storage
Future<String> getReleaseFilesPath(String releaseId) async {
  final basePath = await getLocalAppDataPath();
  return path.join(basePath, 'release_files', releaseId);
}

/// Gets the path for release artwork storage
Future<String> getReleaseArtworkPath() async {
  final basePath = await getLocalAppDataPath();
  return path.join(basePath, 'release_artwork');
}

