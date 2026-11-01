import 'dart:async';

import 'package:path/path.dart' as p;

import '../../models/music_project.dart';
import '../scanner_service.dart';
import 'media_check.dart';
import 'project_anatomy_reader.dart';

/// A project bigger than this isn't read before a launch: the check must
/// never be what keeps the DAW waiting.
const kLaunchCheckMaxBytes = 256 * 1024 * 1024;

/// How long a check before a launch may take; past it, the project opens
/// with nothing said.
const kLaunchCheckTimeout = Duration(seconds: 2);

/// Whether to read [project] before launching it (#222): only when the
/// person switched it on, never for a cloud placeholder (reading downloads
/// it), never for a file too big to read in a moment, and only for a format
/// the Inspector reads.
bool shouldCheckBeforeLaunch({
  required bool enabled,
  required MusicProject project,
  required bool cloudOnly,
}) =>
    enabled &&
    !project.isVirtual &&
    !cloudOnly &&
    project.fileSizeBytes <= kLaunchCheckMaxBytes &&
    ScannerService.supportedExtensions.contains(
      p.extension(project.filePath).toLowerCase(),
    );

/// What is worth saying before a project opens.
class LaunchWarnings {
  const LaunchWarnings({
    this.missingAudio = 0,
    this.totalAudio = 0,
    this.projectRate,
    this.studioRate,
    this.media,
  });

  /// Audio files the project uses that aren't on this computer.
  final int missingAudio;
  final int totalAudio;

  /// The project's sample rate, and the studio's, when they differ; both
  /// null when they agree or either isn't known.
  final int? projectRate;
  final int? studioRate;

  /// The audio files as checked, for fixing the missing ones; null when not
  /// read.
  final List<MediaCheck>? media;

  bool get sampleRateDiffers => projectRate != null && studioRate != null;
  bool get any => missingAudio > 0 || sampleRateDiffers;
}

/// The warnings for a project whose audio files were checked ([media]; null
/// when not read) and whose sample rate is [projectRate], in a studio that
/// runs at [studioRate] (null when the person hasn't said).
LaunchWarnings launchWarnings({
  List<MediaCheck>? media,
  int? projectRate,
  int? studioRate,
}) {
  final differs =
      projectRate != null && studioRate != null && projectRate != studioRate;
  return LaunchWarnings(
    missingAudio:
        media?.where((m) => m.status == MediaStatus.missing).length ?? 0,
    totalAudio: media?.length ?? 0,
    projectRate: differs ? projectRate : null,
    studioRate: differs ? studioRate : null,
    media: media,
  );
}

/// Reads [project] and checks its audio files (existence only), within
/// [timeout]; null when that took too long or the file couldn't be read —
/// then nothing is said and the project opens. The sample rate comes from
/// the file, or else from the last deep scan.
Future<LaunchWarnings?> checkBeforeLaunch(
  MusicProject project, {
  int? studioRate,
  Duration timeout = kLaunchCheckTimeout,
}) async {
  try {
    return await () async {
      final anatomy = await readProjectAnatomy(project.filePath);
      final media = anatomy.media == null
          ? null
          : await checkMedia(
              anatomy.media!,
              projectDir: p.dirname(project.filePath),
            );
      return launchWarnings(
        media: media,
        projectRate: anatomy.sampleRate ?? project.stats?.sampleRate,
        studioRate: studioRate,
      );
    }().timeout(timeout);
  } on TimeoutException {
    return null;
  } catch (_) {
    return null;
  }
}
