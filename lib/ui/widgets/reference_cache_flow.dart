import 'package:material_ui/material_ui.dart';

import '../../models/music_project.dart';
import '../../services/midi/melodic_midi_reading.dart';
import '../../services/template_export/reference_service.dart';
import 'midi_read_dialogs.dart';

/// What [updateReferenceCache] says while asking and reading.
class ReferenceReadWords {
  const ReferenceReadWords({
    required this.title,
    required this.body,
    required this.readLabel,
    required this.skipLabel,
    required this.readingTitle,
    required this.stopLabel,
  });

  final String title;

  /// The question, given how many projects and how much would be read.
  final String Function(int count, String size) body;
  final String readLabel;
  final String skipLabel;
  final String readingTitle;
  final String stopLabel;
}

/// Reads into [cache] the Cubase projects of [projects] whose tracks it
/// doesn't hold as the files are now — after asking, since reading opens
/// each file and downloads one from a cloud drive — and saves it. Returns
/// false when the person cancelled; true when there was nothing to read,
/// they chose to go on with what is read, or the reading is done (or was
/// stopped: what was read stays read).
Future<bool> updateReferenceCache(
  BuildContext context,
  List<MusicProject> projects,
  ReferenceCache cache, {
  required ReferenceReadWords words,
}) async {
  final stale = projectsToReadForReference(projects, cache);
  if (stale.isEmpty) return true;
  final choice = await askProjectRead(
    context,
    title: words.title,
    body: words.body(
      stale.length,
      formatDataSize(stale.fold<int>(0, (sum, x) => sum + x.fileSizeBytes)),
    ),
    readLabel: words.readLabel,
    skipLabel: words.skipLabel,
  );
  if (choice == MidiReadChoice.cancel || !context.mounted) return false;
  if (choice == MidiReadChoice.readThenExport) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MidiReadDialog(
        projects: stale,
        title: words.readingTitle,
        stopLabel: words.stopLabel,
        read: (project) => readProjectIntoCache(project, cache),
      ),
    );
    cache.retainOnly({for (final x in projects) x.id});
    await cache.save();
  }
  return true;
}
