import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/midi_clip.dart';
import '../../models/music_project.dart';
import '../../models/stored_midi_clips.dart';
import '../../providers/providers.dart';
import '../../repository/project_repository.dart';
import '../../services/midi/midi_clip_service.dart';
import '../../services/midi/midi_file_writer.dart';
import '../../services/midi/synth_voice.dart';
import '../../utils/mobile_utils.dart';
import '../midi_clip_share.dart';
import '../midi_collection_actions.dart';
import 'midi_clip_list.dart';
import '../midi_piano_roll_dialog.dart';
import '../midi_preview_player.dart';
import 'midi_tempo_control.dart';
import 'midi_loop_toggle.dart';
import 'midi_volume_control.dart';

/// A project's MIDI clips: the ones stored by the last extraction (see
/// `MidiClipStore`), previewed through the built-in synth, saved, shared or
/// dragged out as `.mid`.
///
/// The glue around [MidiClipList] — it owns the player, the temp files, the
/// pickers and the store subscription, and is the only part that needs the
/// platform.
///
/// [canReadFile] is whether this device can (re)read the project file: a
/// desktop with the file in a supported format. Without it the section shows
/// whatever Drive sync or a backup brought in, and says how to get clips
/// when there are none.
class MidiClipsSection extends ConsumerStatefulWidget {
  const MidiClipsSection({
    super.key,
    required this.project,
    required this.canReadFile,
  });

  final MusicProject project;
  final bool canReadFile;

  @override
  ConsumerState<MidiClipsSection> createState() => _MidiClipsSectionState();
}

class _MidiClipsSectionState extends ConsumerState<MidiClipsSection> {
  ProjectRepository? _repo;
  StoredMidiClips? _stored;
  bool _loaded = false;
  bool _reading = false;
  bool _stale = false;
  final MidiPreviewPlayer _player = MidiPreviewPlayer();
  StreamSubscription<String>? _storeSub;

  /// Instruments picked by hand, by clip content — so a refresh that reorders
  /// the list keeps each pick on its clip.
  final Map<String, SynthVoice> _voiceOverrides = {};

  /// A tempo the user picked; null means "the project's".
  double? _tempoOverride;

  List<MidiClip> get _clips => _stored?.clips ?? const [];

  double? get _projectBpm {
    final bpm = widget.project.bpm;
    return (bpm != null && bpm > 0) ? bpm : null;
  }

  double get _tempo => _tempoOverride ?? _projectBpm ?? 120;

  SynthVoice _voiceOf(int index) {
    final clip = _clips[index];
    return _voiceOverrides[clip.contentKey] ?? inferSynthVoice(clip);
  }

  /// Where clip [index] sits in [_clips] by the player's key, for the list.
  int? _indexOfKey(String? key) {
    if (key == null) return null;
    final i = _clips.indexWhere((c) => c.contentKey == key);
    return i < 0 ? null : i;
  }

  @override
  void initState() {
    super.initState();
    _player.addListener(_onPlayer);
    _player.volume = ref.read(midiPreviewVolumeProvider);
    _player.loop = ref.read(midiPreviewLoopProvider);
    _attach();
  }

  void _onPlayer() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(MidiClipsSection old) {
    super.didUpdateWidget(old);
    if (old.project.id != widget.project.id) {
      _stop();
      _storeSub?.cancel();
      _voiceOverrides.clear();
      setState(() {
        _stored = null;
        _loaded = false;
        _stale = false;
      });
      _attach();
    }
  }

  @override
  void dispose() {
    _storeSub?.cancel();
    _player.removeListener(_onPlayer);
    _player.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    final repo = await ref.read(repositoryProvider.future);
    if (!mounted) return;
    _repo = repo;
    final projectId = widget.project.id;
    _storeSub = repo.midiClips.watch().listen((id) {
      if (id == projectId) _reload();
    });
    await _reload();
  }

  Future<void> _reload() async {
    final repo = _repo;
    if (repo == null) return;
    final stored = await repo.midiClips.get(widget.project.id);
    var stale = false;
    if (stored != null && widget.canReadFile) {
      try {
        stale = stored.isStaleFor(
          await File(widget.project.filePath).lastModified(),
        );
      } catch (_) {}
    }
    if (!mounted) return;
    await _stop();
    setState(() {
      _stored = stored;
      _stale = stale;
      _loaded = true;
    });
  }

  /// Re-reads the project file through the normal metadata extraction, which
  /// stores the clips (the store subscription then reloads this section) and
  /// refreshes the stats and everything else alongside.
  Future<void> _read() async {
    final repo = _repo;
    if (repo == null) return;
    setState(() => _reading = true);
    try {
      await repo.extractFullMetadataForProject(widget.project.id);
      ref.invalidate(allProjectsStreamProvider);
      await _reload();
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  void _setTempo(double bpm) {
    setState(() => _tempoOverride = bpm == _projectBpm ? null : bpm);
    // A playing preview follows the new tempo straight away.
    final playing = _indexOfKey(_player.playingKey);
    if (playing != null) _play(playing);
  }

  void _setVoice(int index, SynthVoice voice) {
    setState(() => _voiceOverrides[_clips[index].contentKey] = voice);
    if (_player.playingKey == _clips[index].contentKey) _play(index);
  }

  Future<Directory> _tempDir(String name) async {
    final base = await getTemporaryDirectory();
    return Directory(p.join(base.path, 'daw_project_manager', name));
  }

  Future<void> _stop() => _player.stop();

  Future<void> _togglePlay(int index) async {
    final clip = _clips[index];
    if (_player.playingKey == clip.contentKey) return _stop();
    await _play(index);
  }

  Future<void> _play(int index, {SynthVoice? voice, double? bpm}) async {
    final l10n = AppLocalizations.of(context)!;
    final clip = _clips[index];
    try {
      await _player.play(
        clip.contentKey,
        clip,
        bpm: bpm ?? _tempo,
        voice: voice ?? _voiceOf(index),
      );
    } catch (e) {
      _snack(l10n.midiClipPreviewFailed(e.toString()));
    }
  }

  /// The project's key, which exported files carry in their name and as a
  /// key signature.
  String? get _projectKey {
    final key = widget.project.musicalKey?.trim();
    return key == null || key.isEmpty ? null : key;
  }

  MidiExport _export(MidiClip clip) =>
      MidiExport(clip, bpm: _tempo, musicalKey: _projectKey);

  Future<void> _save(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final export = _export(_clips[index]);
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: l10n.midiClipSave,
        fileName: export.fileName,
        type: FileType.custom,
        allowedExtensions: ['mid'],
      );
      if (path == null) return;
      final target = p.extension(path).isEmpty ? '$path.mid' : path;
      await MidiClipService.writeMidiFile(export, target);
      _snack(l10n.midiClipSaved(p.basename(target)));
    } catch (e) {
      _snack(l10n.midiClipSaveFailed(e.toString()));
    }
  }

  Future<void> _exportAll() async {
    final l10n = AppLocalizations.of(context)!;
    if (_clips.isEmpty) return;
    try {
      final folder = await FilePicker.getDirectoryPath(
        dialogTitle: l10n.midiClipsExportFolderTitle,
      );
      if (folder == null) return;
      final written = await MidiClipService.exportAll(
        [for (final c in _clips) _export(c)],
        Directory(folder),
      );
      _snack(l10n.midiClipsExported(written.length, folder));
    } catch (e) {
      _snack(l10n.midiClipSaveFailed(e.toString()));
    }
  }

  Future<void> _share(int index, Rect? origin) async {
    final l10n = AppLocalizations.of(context)!;
    final clip = _clips[index];
    await shareMidiClips(
      context,
      [_export(clip)],
      text: l10n.midiClipShareText(clip.label, widget.project.displayName),
      origin: origin,
    );
  }

  Future<void> _shareAll(Rect? origin) async {
    final l10n = AppLocalizations.of(context)!;
    await shareMidiClips(
      context,
      [for (final c in _clips) _export(c)],
      text: l10n.midiClipsShareAllText(widget.project.displayName),
      origin: origin,
    );
  }

  /// Writes the clip to a temp `.mid` for an OS drag. Each drag gets its own
  /// folder so a DAW that keeps referencing the dropped file never sees it
  /// overwritten by the next drag of a same-named clip.
  Future<String> _dragFile(int index) async {
    final clip = _clips[index];
    final dir = await _tempDir(
      p.join('midi_drag', DateTime.now().microsecondsSinceEpoch.toString()),
    );
    await dir.create(recursive: true);
    final export = _export(clip);
    final path = p.join(dir.path, export.fileName);
    await MidiClipService.writeMidiFile(export, path);
    return path;
  }

  /// The last part of a path, whichever separator the project was saved
  /// with — a REAPER project from Windows names its files with backslashes.
  static String _fileNameOf(String path) =>
      path.split(RegExp(r'[\\/]')).last;

  /// The button that reads the project file — everything a full extraction
  /// reads, clips included — with what it does beneath it.
  Widget _readButton({
    required IconData icon,
    required String label,
    required String hint,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _read,
            icon: Icon(icon, size: 18),
            label: Text(label),
          ),
          const SizedBox(height: 6),
          Text(hint, style: Theme.of(context).textTheme.bodySmall),
        ],
      );

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final stored = _stored;
    final clips = _clips;
    final isMobile = MobileUtils.isMobile();
    final count = stored?.clips.length ?? widget.project.stats?.midiClipCount;
    // One volume for every MIDI preview in the app; follow it live.
    ref.listen<double>(midiPreviewVolumeProvider, (_, v) => _player.setVolume(v));
    ref.listen<bool>(midiPreviewLoopProvider, (_, v) => _player.setLoop(v));
    final volume = ref.watch(midiPreviewVolumeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showsMidiClipsHeading(
          clipsStored: stored != null,
          contentsRead: widget.project.stats != null,
        ))
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
            if (stored != null && widget.canReadFile)
              _reading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: l10n.midiClipsRefresh,
                      icon: const Icon(Icons.refresh),
                      onPressed: _read,
                    ),
          ],
        ),
        // Actions wrap onto their own line(s) rather than overflow the
        // header on a narrow page or in a long translation.
        if (clips.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Builder(
                builder: (buttonContext) => TextButton.icon(
                  onPressed: () => _shareAll(shareOriginOf(buttonContext)),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(l10n.midiClipsShareAll),
                ),
              ),
              if (!isMobile)
                TextButton.icon(
                  onPressed: _exportAll,
                  icon: const Icon(Icons.drive_folder_upload_outlined, size: 18),
                  label: Text(l10n.midiClipsExportAll),
                ),
            ],
          ),
        if (_stale && !_reading)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.update, size: 16, color: theme.colorScheme.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l10n.midiClipsStale, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
        // Referenced .mid files that weren't there at the last read (#143):
        // said out loud, so fewer clips than expected has a reason.
        if (stored != null && stored.missingFiles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Tooltip(
              message: stored.missingFiles.join('\n'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.midiClipsMissingFiles(
                        stored.missingFiles.length,
                        stored.missingFiles.map(_fileNameOf).join(', '),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (clips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MidiTempoControl(
                  bpm: _tempo,
                  onChanged: _setTempo,
                  onReset: (_tempoOverride != null && _projectBpm != null)
                      ? () => _setTempo(_projectBpm!)
                      : null,
                  resetTooltip: _projectBpm == null
                      ? null
                      : l10n.midiTempoReset(formatPreviewBpm(_projectBpm!)),
                  labels: midiTempoLabelsOf(l10n),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MidiLoopToggle(
                      loop: ref.watch(midiPreviewLoopProvider),
                      onChanged: ref.read(midiPreviewLoopProvider.notifier).set,
                      tooltip: l10n.midiPreviewLoop,
                    ),
                    MidiVolumeControl(
                      volume: volume,
                      onChanged: ref.read(midiPreviewVolumeProvider.notifier).set,
                      labels: midiVolumeLabelsOf(l10n),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (!_loaded || (_reading && stored == null))
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              if (_reading)
                Text(l10n.midiClipsLoading, style: theme.textTheme.bodySmall),
            ],
          )
        else if (stored == null)
          switch (midiClipsEmptyState(
            contentsRead: widget.project.stats != null,
            canReadFile: widget.canReadFile,
          )) {
            MidiClipsEmptyState.readContents => _readButton(
                icon: Icons.inventory_2_outlined,
                label: l10n.projectContentsRead,
                hint: l10n.projectContentsReadHint,
              ),
            MidiClipsEmptyState.nothingReadYet => Text(
                l10n.projectContentsNoneRead,
                style: theme.textTheme.bodySmall,
              ),
            MidiClipsEmptyState.loadClips => _readButton(
                icon: Icons.piano,
                label: l10n.midiClipsLoad,
                hint: l10n.midiClipsLoadHint,
              ),
            MidiClipsEmptyState.noClipsStored => Text(
                l10n.midiClipsNoneStored,
                style: theme.textTheme.bodySmall,
              ),
          }
        else if (clips.isEmpty)
          Text(l10n.midiClipsNone, style: theme.textTheme.bodySmall)
        else
          MidiClipList(
            clips: clips,
            playingIndex: _indexOfKey(_player.playingKey),
            preparingIndex: _indexOfKey(_player.preparingKey),
            onPlay: _togglePlay,
            onShare: _share,
            onSave: isMobile ? null : _save,
            compact: isMobile,
            onOpen: (index) {
              final clip = _clips[index];
              showMidiPianoRoll(
                context,
                clip: clip,
                title: clip.label,
                subtitle: widget.project.displayName,
                player: _player,
                playerKey: clip.contentKey,
                bpm: _tempo,
                onPlay: (voice, bpm) => _play(index, voice: voice, bpm: bpm),
                musicalKey: _projectKey,
                voice: _voiceOf(index),
                onVoiceChanged: (v) => setState(
                    () => _voiceOverrides[clip.contentKey] = v),
                // An edit is saved as a new clip in a collection; the
                // project's own clips are re-read from its file.
                onSaveEdited: (edit) => addToCollectionFlow(
                  context,
                  ref,
                  [
                    collectionItemFor(
                      edit.clip,
                      projectId: widget.project.id,
                      projectName: widget.project.displayName,
                      bpm: edit.bpm,
                      musicalKey: edit.musicalKey,
                      pickedVoice: edit.voice,
                      timeSignature: edit.timeSignature,
                    ),
                  ],
                ),
              );
            },
            onAddToCollection: (index, origin) => addToCollectionFlow(
              context,
              ref,
              [
                collectionItemFor(
                  _clips[index],
                  projectId: widget.project.id,
                  projectName: widget.project.displayName,
                  // The project's own tempo, not an audition tempo picked on
                  // this page — the same thing the MIDI tab saves, so a
                  // collection clip plays at its project's BPM either way.
                  bpm: _projectBpm,
                  musicalKey: _projectKey,
                  pickedVoice: _voiceOverrides[_clips[index].contentKey],
                ),
              ],
              origin: origin,
            ),
            voiceOf: _voiceOf,
            onVoiceChanged: _setVoice,
            dragHandleBuilder: isMobile
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
            labels: midiClipListLabelsOf(l10n),
          ),
      ],
    );
  }
}

MidiVolumeLabels midiVolumeLabelsOf(AppLocalizations l10n) => MidiVolumeLabels(
      volume: l10n.midiPreviewVolume,
      mute: l10n.volumeMute,
      unmute: l10n.volumeUnmute,
    );

MidiTempoLabels midiTempoLabelsOf(AppLocalizations l10n) => MidiTempoLabels(
      unit: l10n.bpm,
      tooltip: l10n.midiTempoTooltip,
      slower: l10n.midiTempoSlower,
      faster: l10n.midiTempoFaster,
      auto: l10n.midiTempoAuto,
    );

/// Every string [MidiClipList] needs. Shared with the MIDI library page.
MidiClipListLabels midiClipListLabelsOf(AppLocalizations l10n) =>
    MidiClipListLabels(
      play: l10n.midiClipPlay,
      stop: l10n.midiClipStop,
      save: l10n.midiClipSave,
      share: l10n.midiClipShare,
      instrument: l10n.midiClipInstrumentTooltip,
      voiceName: (v) => synthVoiceName(l10n, v),
      dragTooltip: l10n.midiClipDragTooltip,
      bars: l10n.midiClipBars,
      notes: l10n.midiClipNotes,
      usedTimes: l10n.midiClipUsedTimes,
      alsoAs: l10n.midiClipAlsoAs,
      noTrack: l10n.midiClipsNoTrack,
      expandTrack: l10n.midiClipsExpandTrack,
      collapseTrack: l10n.midiClipsCollapseTrack,
      addToCollection: l10n.midiCollectionAddTo,
      removeFromCollection: l10n.midiCollectionRemoveFrom,
      more: l10n.midiClipMoreActions,
      openPianoRoll: l10n.midiPianoRollOpen,
      openProject: l10n.midiOpenSourceProject,
    );

String synthVoiceName(AppLocalizations l10n, SynthVoice v) => switch (v) {
      SynthVoice.lead => l10n.synthVoiceLead,
      SynthVoice.bass => l10n.synthVoiceBass,
      SynthVoice.pad => l10n.synthVoicePad,
      SynthVoice.pluck => l10n.synthVoicePluck,
      SynthVoice.keys => l10n.synthVoiceKeys,
      SynthVoice.organ => l10n.synthVoiceOrgan,
      SynthVoice.strings => l10n.synthVoiceStrings,
      SynthVoice.brass => l10n.synthVoiceBrass,
      SynthVoice.bell => l10n.synthVoiceBell,
      SynthVoice.drumKit => l10n.synthVoiceDrumKit,
      SynthVoice.kick => l10n.synthVoiceKick,
      SynthVoice.snare => l10n.synthVoiceSnare,
      SynthVoice.clap => l10n.synthVoiceClap,
      SynthVoice.hiHat => l10n.synthVoiceHiHat,
      SynthVoice.percussion => l10n.synthVoicePercussion,
    };


/// What the section shows when no clips are stored for its project.
enum MidiClipsEmptyState {
  /// Nothing read from the file yet, and this device can read it: one button
  /// for everything the project holds — tracks, plug-ins and MIDI clips.
  readContents,

  /// Nothing read yet, and no file here to read (a phone, an archived
  /// project): say where it can be done.
  nothingReadYet,

  /// The contents were read but no clips came with them (an older read, or
  /// clips not synced yet), and the file is here: read the clips.
  loadClips,

  /// As [loadClips], with no file here to read.
  noClipsStored,
}

/// Picks the empty state. "Read" goes by the project's stats: they are
/// written by every full extraction, so null means nothing has been read
/// from the file at all — the empty state is then the whole of Project
/// Contents, not a MIDI one.
MidiClipsEmptyState midiClipsEmptyState({
  required bool contentsRead,
  required bool canReadFile,
}) {
  if (!contentsRead) {
    return canReadFile
        ? MidiClipsEmptyState.readContents
        : MidiClipsEmptyState.nothingReadYet;
  }
  return canReadFile
      ? MidiClipsEmptyState.loadClips
      : MidiClipsEmptyState.noClipsStored;
}

/// Whether the section heads itself "MIDI clips". Not while nothing at all
/// has been read: the empty state then speaks for all of Project Contents,
/// and a "MIDI clips" heading over it would say it is about MIDI only.
bool showsMidiClipsHeading({
  required bool clipsStored,
  required bool contentsRead,
}) =>
    clipsStored || contentsRead;
