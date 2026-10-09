import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../services/midi/melodic_midi_reading.dart';

/// What the person chose when told some projects have no MIDI read yet.
enum MidiReadChoice { readThenExport, exportWhatIsRead, cancel }

/// Asks whether to read the [count] projects ([bytes] on disk) that have no
/// MIDI read before exporting. Reading opens each file, and one on a cloud
/// drive is downloaded first, so it is never done without asking.
Future<MidiReadChoice> askMidiRead(
  BuildContext context, {
  required int count,
  required int bytes,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final choice = await showDialog<MidiReadChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.melodicReadConfirmTitle),
      content: Text(l10n.melodicReadConfirmBody(count, formatDataSize(bytes))),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, MidiReadChoice.cancel),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, MidiReadChoice.exportWhatIsRead),
          child: Text(l10n.melodicExportReadOnly),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, MidiReadChoice.readThenExport),
          child: Text(l10n.melodicReadAndExport),
        ),
      ],
    ),
  );
  return choice ?? MidiReadChoice.cancel;
}

/// Reads [projects] through [read] while showing how far it is, and closes
/// with the [MidiReadOutcome]. Its one button stops the reading early; what
/// was read stays read.
class MidiReadDialog extends StatefulWidget {
  const MidiReadDialog({
    super.key,
    required this.projects,
    required this.read,
  });

  final List<MusicProject> projects;
  final Future<void> Function(MusicProject project) read;

  @override
  State<MidiReadDialog> createState() => _MidiReadDialogState();
}

class _MidiReadDialogState extends State<MidiReadDialog> {
  int _done = 0;
  String _current = '';
  bool _stop = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final outcome = await readMissingMidi(
      widget.projects,
      read: widget.read,
      shouldStop: () => _stop,
      onProgress: (done, total, next) {
        if (!mounted) return;
        setState(() {
          _done = done;
          _current = projectFileLabel(next);
        });
      },
    );
    if (mounted) Navigator.pop(context, outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = widget.projects.length;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.melodicReadingTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: total == 0 ? null : _done / total),
            const SizedBox(height: 12),
            Text(
              l10n.melodicReadingProgress(_done + 1 > total ? total : _done + 1,
                  total, _current),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _stop ? null : () => setState(() => _stop = true),
            child: Text(l10n.melodicReadStop),
          ),
        ],
      ),
    );
  }
}
