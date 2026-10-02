import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/midi_clip.dart';
import '../../services/midi/midi_clip_service.dart';
import '../../services/midi/midi_file_writer.dart';
import '../../utils/mobile_utils.dart';
import 'midi_clip_list.dart';
import 'midi_tempo_control.dart';

/// The MIDI clips of one project: loaded from the project file on request,
/// previewed through the built-in synth, saved or dragged out as `.mid`.
///
/// The glue around [MidiClipList] — it owns the player, the temp files and
/// the file pickers, and is the only part that needs the platform.
///
/// Loading is a button rather than automatic: the project may live on a
/// cloud-synced drive where reading it means downloading it, and a big set
/// takes a moment to parse.
class MidiClipsSection extends StatefulWidget {
  const MidiClipsSection({
    super.key,
    required this.projectFilePath,
    this.bpm,
    this.knownClipCount,
  });

  final String projectFilePath;

  /// The project's tempo: where the tempo control starts, and what its
  /// reset goes back to.
  final double? bpm;

  /// The count from the last metadata extraction, shown before loading.
  final int? knownClipCount;

  @override
  State<MidiClipsSection> createState() => _MidiClipsSectionState();
}

class _MidiClipsSectionState extends State<MidiClipsSection> {
  List<MidiClip>? _clips;
  bool _loading = false;
  String? _error;
  int? _playing;
  int? _preparing;
  AudioPlayer? _player;
  StreamSubscription<void>? _completeSub;

  /// A tempo the user picked; null means "the project's".
  double? _tempoOverride;

  double? get _projectBpm =>
      (widget.bpm != null && widget.bpm! > 0) ? widget.bpm : null;

  /// What previews play at and saved `.mid` files carry: the user's pick,
  /// else the project's tempo, else 120.
  double get _tempo => _tempoOverride ?? _projectBpm ?? 120;

  void _setTempo(double bpm) {
    setState(() => _tempoOverride = bpm == _projectBpm ? null : bpm);
    // A playing preview follows the new tempo straight away.
    final playing = _playing;
    if (playing != null) _play(playing);
  }

  @override
  void didUpdateWidget(MidiClipsSection old) {
    super.didUpdateWidget(old);
    if (old.projectFilePath != widget.projectFilePath) {
      _stop();
      setState(() {
        _clips = null;
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clips = await MidiClipService.readClips(widget.projectFilePath);
      if (!mounted) return;
      setState(() => _clips = clips);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Directory> _tempDir(String name) async {
    final base = await getTemporaryDirectory();
    return Directory(p.join(base.path, 'daw_project_manager', name));
  }

  Future<void> _stop() async {
    await _player?.stop();
    if (mounted) setState(() => _playing = null);
  }

  Future<void> _togglePlay(int index) async {
    if (_playing == index) {
      await _stop();
      return;
    }
    await _play(index);
  }

  Future<void> _play(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final clip = _clips![index];
    final tempo = _tempo;
    setState(() => _preparing = index);
    try {
      final path = await MidiClipService.renderPreview(
        clip,
        bpm: tempo,
        directory: await _tempDir('midi_previews'),
      );
      // The tempo moved while this render ran: render again rather than
      // start a preview at the speed the user just left.
      if (mounted && tempo != _tempo) {
        await _play(index);
        return;
      }
      final player = _player ??= AudioPlayer();
      _completeSub ??= player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playing = null);
      });
      await player.stop();
      await player.play(DeviceFileSource(path));
      if (mounted) setState(() => _playing = index);
    } catch (e) {
      _snack(l10n.midiClipPreviewFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _preparing = null);
    }
  }

  Future<void> _save(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final clip = _clips![index];
    final fileName = midiClipFileName(clip);
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: l10n.midiClipSave,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['mid'],
      );
      if (path == null) return;
      final target = p.extension(path).isEmpty ? '$path.mid' : path;
      await MidiClipService.writeMidiFile(clip, target, bpm: _tempo);
      _snack(l10n.midiClipSaved(p.basename(target)));
    } catch (e) {
      _snack(l10n.midiClipSaveFailed(e.toString()));
    }
  }

  Future<void> _exportAll() async {
    final l10n = AppLocalizations.of(context)!;
    final clips = _clips;
    if (clips == null || clips.isEmpty) return;
    try {
      final folder = await FilePicker.getDirectoryPath(
        dialogTitle: l10n.midiClipsExportFolderTitle,
      );
      if (folder == null) return;
      final written = await MidiClipService.exportAll(
        clips,
        Directory(folder),
        bpm: _tempo,
      );
      _snack(l10n.midiClipsExported(written.length, folder));
    } catch (e) {
      _snack(l10n.midiClipSaveFailed(e.toString()));
    }
  }

  /// Writes the clip to a temp `.mid` for an OS drag. Each drag gets its own
  /// folder so a DAW that keeps referencing the dropped file never sees it
  /// overwritten by the next drag of a same-named clip.
  Future<String> _dragFile(int index) async {
    final clip = _clips![index];
    final dir = await _tempDir(
      p.join('midi_drag', DateTime.now().microsecondsSinceEpoch.toString()),
    );
    await dir.create(recursive: true);
    final path = p.join(dir.path, midiClipFileName(clip));
    await MidiClipService.writeMidiFile(clip, path, bpm: _tempo);
    return path;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final clips = _clips;
    final count = clips?.length ?? widget.knownClipCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.midiClipsTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
            const Spacer(),
            if (clips != null && clips.isNotEmpty)
              TextButton.icon(
                onPressed: _exportAll,
                icon: const Icon(Icons.drive_folder_upload_outlined, size: 18),
                label: Text(l10n.midiClipsExportAll),
              ),
          ],
        ),
        if (clips != null && clips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: MidiTempoControl(
              bpm: _tempo,
              projectBpm: _projectBpm,
              onChanged: _setTempo,
              labels: MidiTempoLabels(
                unit: l10n.bpm,
                tooltip: l10n.midiTempoTooltip,
                slower: l10n.midiTempoSlower,
                faster: l10n.midiTempoFaster,
                resetTo: l10n.midiTempoReset,
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (_loading)
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(l10n.midiClipsLoading, style: theme.textTheme.bodySmall),
            ],
          )
        else if (_error != null)
          Text(
            l10n.midiClipsError(_error!),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          )
        else if (clips == null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.piano, size: 18),
                label: Text(l10n.midiClipsLoad),
              ),
              const SizedBox(height: 6),
              Text(l10n.midiClipsLoadHint, style: theme.textTheme.bodySmall),
            ],
          )
        else if (clips.isEmpty)
          Text(l10n.midiClipsNone, style: theme.textTheme.bodySmall)
        else
          MidiClipList(
            clips: clips,
            playingIndex: _playing,
            preparingIndex: _preparing,
            onPlay: _togglePlay,
            onSave: _save,
            dragHandleBuilder: MobileUtils.isMobile()
                ? null
                : (context, index, handle) => DragItemWidget(
                      allowedOperations: () => [DropOperation.copy],
                      dragItemProvider: (request) async {
                        final path = await _dragFile(index);
                        final item = DragItem(suggestedName: p.basename(path));
                        item.add(Formats.fileUri(Uri.file(path)));
                        return item;
                      },
                      child: DraggableWidget(child: handle),
                    ),
            labels: MidiClipListLabels(
              play: l10n.midiClipPlay,
              stop: l10n.midiClipStop,
              save: l10n.midiClipSave,
              dragTooltip: l10n.midiClipDragTooltip,
              bars: l10n.midiClipBars,
              notes: l10n.midiClipNotes,
              usedTimes: l10n.midiClipUsedTimes,
              alsoAs: l10n.midiClipAlsoAs,
              noTrack: l10n.midiClipsNoTrack,
              expandTrack: l10n.midiClipsExpandTrack,
              collapseTrack: l10n.midiClipsCollapseTrack,
            ),
          ),
      ],
    );
  }
}
