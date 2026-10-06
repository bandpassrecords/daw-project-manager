import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../models/midi_clip_naming.dart';
import '../models/midi_collection.dart';
import '../models/midi_collection_drag.dart';
import '../models/midi_library.dart';
import '../providers/providers.dart';
import '../repository/midi_collection_store.dart';
import '../services/midi/midi_clip_service.dart';
import '../services/midi/midi_file_writer.dart';
import '../services/midi/synth_voice.dart';
import '../services/midi_tree_state_store.dart';
import '../utils/mobile_utils.dart';
import '../utils/search_utils.dart';
import '../utils/time_signature.dart';
import 'midi_clip_share.dart';
import 'midi_collection_actions.dart';
import 'midi_collection_naming.dart';
import 'midi_piano_roll_dialog.dart';
import 'project_detail_page.dart';
import 'midi_preview_player.dart';
import 'widgets/midi_clip_list.dart';
import 'widgets/midi_collection_tree.dart';
import 'widgets/midi_clips_section.dart'
    show
        midiClipListLabelsOf,
        midiTempoLabelsOf,
        midiVolumeLabelsOf,
        synthVoiceName;
import 'widgets/midi_loop_toggle.dart';
import 'widgets/midi_volume_control.dart';
import 'widgets/midi_tempo_control.dart';

/// One row the page shows, whichever view it comes from: a library clip or a
/// collection item, flattened to what the list and the actions need.
class _Entry {
  const _Entry({
    required this.key,
    required this.clip,
    required this.bpm,
    required this.voice,
    this.musicalKey,
    this.projectId,
    this.projectName,
    this.item,
    this.fileName,
  });

  /// Player key: the clip's content in the library, the item id in a
  /// collection (one collection never holds the same notes twice, but ids
  /// are what removal goes by).
  final String key;
  final MidiClip clip;
  final double? bpm;
  final SynthVoice voice;

  /// The source project's key, for exported files.
  final String? musicalKey;
  final String? projectId;
  final String? projectName;
  final MidiCollectionItem? item;

  /// A collection item's file name by the collection's naming template.
  final String? fileName;
}

/// The MIDI tab: every unique clip across the profile's projects, and the
/// user's collections of them.
///
/// "All clips" lists the library grouped by project, with "Add to
/// collection" on each clip. A collection lists its copied clips flat, in the
/// order they were added, with remove, rename, delete, share all and export.
/// Both play through one [MidiPreviewPlayer], at each clip's own project
/// tempo unless the tempo control sets one for all.
class MidiLibraryPage extends ConsumerStatefulWidget {
  const MidiLibraryPage({super.key});

  @override
  ConsumerState<MidiLibraryPage> createState() => _MidiLibraryPageState();
}

class _MidiLibraryPageState extends ConsumerState<MidiLibraryPage> {
  final MidiPreviewPlayer _player = MidiPreviewPlayer();

  /// The collection on show; null for "All clips".
  String? _collectionId;

  /// The folder of it on show; null for its top level.
  String? _folderId;

  /// Shows collection [id] (null: all clips) from its top level, or from
  /// its folder [folderId].
  void _showCollection(String? id, {String? folderId}) => setState(() {
    _folderId = folderId;
    _collectionId = id;
  });

  /// What is open in the side list, a collection's tree and all clips'
  /// groups — kept between runs on this device.
  MidiTreeState get _tree => ref.watch(midiTreeStateProvider);

  void _updateTree(MidiTreeState Function(MidiTreeState tree) change) =>
      ref.read(midiTreeStateProvider.notifier).update(change);

  /// The key a group of all clips is kept under: by project and by tempo
  /// are different groupings.
  String _groupKey(String? label) => '${_byTempo ? 't' : 'p'}:${label ?? ''}';

  /// The heading [e] goes under in a grouped list: its project, or its tempo.
  String? _groupLabelOf(_Entry e, AppLocalizations l10n) {
    if (!_byTempo) return e.projectName;
    final bpm = e.bpm;
    return bpm == null
        ? l10n.midiLibraryTempoUnknown
        : l10n.midiLibraryTempoGroup(formatPreviewBpm(bpm));
  }

  /// Opens or closes everything in the list on show: [collection]'s
  /// folders when it shows its tree, else the groups of [entries].
  void _setAllOpen(
    List<_Entry> entries,
    MidiCollection? collection,
    bool open,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final query = ref.read(midiLibrarySearchProvider);
    if (collection != null && !_flat(query)) {
      _updateTree(
        (t) => t.setFolders([for (final f in collection.folders) f.id], open),
      );
    } else {
      _updateTree(
        (t) => t.setGroups({
          for (final e in entries) _groupKey(_groupLabelOf(e, l10n)),
        }, open),
      );
    }
  }

  SynthVoice? _voiceFilter;

  /// By project (or, in a collection, as added) or by tempo. Session-only,
  /// like the instrument filter.
  MidiLibraryArrangement _arrangement = MidiLibraryArrangement.project;

  bool get _byTempo => _arrangement == MidiLibraryArrangement.tempo;

  List<_Entry> _arranged(List<_Entry> entries) =>
      _byTempo ? sortByTempo(entries, (e) => e.bpm) : entries;

  /// One tempo for every preview and export; null plays each clip at its own
  /// project's tempo.
  double? _tempo;

  /// Instruments picked in "All clips", by clip content. (A collection item
  /// remembers its own pick.)
  final Map<String, SynthVoice> _libraryVoices = {};

  @override
  void initState() {
    super.initState();
    _player.addListener(_onPlayer);
    _player.volume = ref.read(midiPreviewVolumeProvider);
    _player.loop = ref.read(midiPreviewLoopProvider);
    // A request made before this tab was built (the Open action switched to
    // it) is waiting in the provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(midiCollectionToOpenProvider);
      if (pending != null) _showRequested(pending);
    });
  }

  void _showRequested(String collectionId) {
    _showCollection(collectionId);
    ref.read(midiCollectionToOpenProvider.notifier).consumed();
  }

  void _onPlayer() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayer);
    _player.dispose();
    super.dispose();
  }

  double _bpmOf(_Entry e) => _tempo ?? e.bpm ?? 120;

  MidiExport _exportOf(_Entry e) => MidiExport(
    e.clip,
    bpm: _bpmOf(e),
    musicalKey: e.musicalKey,
    timeSignature: _timeSignatureOf(e.item),
    name: e.fileName,
  );

  static TimeSignature _timeSignatureOf(MidiCollectionItem? item) =>
      TimeSignature.tryParse(item?.timeSignature) ?? TimeSignature.common;

  /// Where each of [c]'s clips goes in an export and what it is called,
  /// by the collection's folders and naming template.
  List<PlannedMidiFile> _plan(MidiCollection c) {
    final labels = midiNamingLabelsOf(AppLocalizations.of(context)!);
    return planCollectionExport(
      c,
      fileNameOf: (item, number, width) => midiItemFileName(
        c,
        item,
        labels: labels,
        voice: _voiceOfItem(item),
        number: number,
        width: width,
        bpm: _tempo ?? item.bpm,
      ),
    );
  }

  /// A collection's clips each at their own project's tempo and key, unless
  /// the user set one tempo for all of them — in its folders, named by its
  /// template.
  List<MidiExport> _collectionExports(MidiCollection c) => [
    for (final f in _plan(c))
      MidiExport(
        f.item.clip,
        bpm: _tempo ?? f.item.bpm,
        musicalKey: f.item.musicalKey,
        timeSignature: _timeSignatureOf(f.item),
        name: f.fileName,
        folders: f.folders,
      ),
  ];

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// A blank clip to draft an idea in, for collection [c]: the piano roll
  /// opens on it, editing, and saving puts it in [c] — the
  /// same item each time it's saved again, not a copy per save.
  Future<void> _newClip(MidiCollection c) async {
    final l10n = AppLocalizations.of(context)!;
    final name = l10n.midiNewClipName(c.items.length + 1);
    final clip = newMidiIdea(name);
    final itemId = MidiCollectionStore.newItemId();
    final playerKey = 'idea~$itemId';
    final addedAt = DateTime.now();
    // Saved into the folder on show, unless the save dialog says otherwise.
    final startFolder = _folderId;
    await showMidiPianoRoll(
      context,
      clip: clip,
      title: name,
      subtitle: c.name,
      player: _player,
      playerKey: playerKey,
      bpm: kNewIdeaBpm,
      onPlay: (voice, bpm) => _player
          .play(playerKey, clip, bpm: bpm, voice: voice)
          .catchError((Object _) {}),
      startEditing: true,
      lengthFollowsNotes: true,
      onSaveEdited: (edit) async {
        final repo = await ref.read(repositoryProvider.future);
        final current = await repo.midiCollections.get(c.id);
        if (current == null) return false;
        final made = collectionItemFor(
          edit.clip.copyWith(name: name),
          bpm: edit.bpm,
          musicalKey: edit.musicalKey,
          pickedVoice: edit.voice,
          timeSignature: edit.timeSignature,
        );
        final draft = MidiCollectionItem(
          id: itemId,
          clip: made.clip,
          addedAt: addedAt,
          bpm: made.bpm,
          musicalKey: made.musicalKey,
          voice: made.voice,
          timeSignature: made.timeSignature,
        );
        final saved = current.items.where((i) => i.id == itemId).firstOrNull;
        MidiCollectionItem item;
        if (saved != null) {
          item = ideaItemToSave(draft, saved: saved);
        } else {
          // The first save: the name, role and folder it goes in.
          if (!mounted) return false;
          final labels = midiNamingLabelsOf(l10n);
          final choice = await showDialog<MidiSaveClipChoice>(
            context: context,
            builder: (_) => MidiSaveClipDialog(
              initialName: name,
              suggestedRole: suggestMidiClipRole(draft.clip, voice: edit.voice),
              folders: midiFolderChoices(current),
              initialFolderId: startFolder,
              fileNameOf: (choice) {
                final folder = current.folderById(choice.folderId)?.id;
                return midiItemFileName(
                  current,
                  ideaItemToSave(
                    draft,
                    name: choice.name,
                    role: choice.role,
                    folderId: choice.folderId,
                  ),
                  labels: labels,
                  voice: edit.voice,
                  number: current.itemsIn(folder).length + 1,
                  bpm: edit.bpm,
                );
              },
            ),
          );
          if (choice == null) return false;
          item = ideaItemToSave(
            draft,
            name: choice.name,
            role: choice.role,
            folderId: choice.folderId,
          );
        }
        await repo.midiCollections.putItem(c.id, item);
        return true;
      },
    );
  }

  Future<void> _play(_Entry e, {SynthVoice? voice, double? bpm}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _player.toggle(
        e.key,
        e.clip,
        bpm: bpm ?? _bpmOf(e),
        voice: voice ?? e.voice,
      );
    } catch (err) {
      _snack(l10n.midiClipPreviewFailed(err.toString()));
    }
  }

  Future<void> _restartIfPlaying(List<_Entry> entries) async {
    final key = _player.playingKey;
    if (key == null) return;
    for (final e in entries) {
      if (e.key == key) {
        await _player.play(e.key, e.clip, bpm: _bpmOf(e), voice: e.voice);
        return;
      }
    }
  }

  Future<void> _save(_Entry e) async {
    final l10n = AppLocalizations.of(context)!;
    final export = _exportOf(e);
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
    } catch (err) {
      _snack(l10n.midiClipSaveFailed(err.toString()));
    }
  }

  /// Opens the project [e] came from — gone for a collection copy whose
  /// project has since been deleted, which is said rather than failed.
  void _openProject(_Entry e) {
    final l10n = AppLocalizations.of(context)!;
    final id = e.projectId;
    final projects = ref.read(allProjectsStreamProvider).value ?? const [];
    if (id == null || !projects.any((p) => p.id == id)) {
      _snack(l10n.midiSourceProjectGone);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: id)));
  }

  Future<String> _dragFile(_Entry e) async {
    final base = await getTemporaryDirectory();
    final dir = Directory(
      p.join(
        base.path,
        'daw_project_manager',
        'midi_drag',
        DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    );
    await dir.create(recursive: true);
    final export = _exportOf(e);
    final path = p.join(dir.path, export.fileName);
    await MidiClipService.writeMidiFile(export, path);
    return path;
  }

  Future<void> _share(_Entry e, Rect? origin) async {
    final l10n = AppLocalizations.of(context)!;
    await shareMidiClips(
      context,
      [_exportOf(e)],
      text: e.projectName == null
          ? e.clip.label
          : l10n.midiClipShareText(e.clip.label, e.projectName!),
      origin: origin,
    );
  }

  Future<void> _shareCollection(MidiCollection c, Rect? origin) async {
    final l10n = AppLocalizations.of(context)!;
    await shareMidiClips(
      context,
      _collectionExports(c),
      text: l10n.midiCollectionShareText(c.name),
      origin: origin,
    );
  }

  Future<void> _shareCollectionZip(MidiCollection c, Rect? origin) async {
    final l10n = AppLocalizations.of(context)!;
    await shareMidiClips(
      context,
      _collectionExports(c),
      text: l10n.midiCollectionShareText(c.name),
      origin: origin,
      zipName: c.name,
    );
  }

  Future<void> _exportCollection(MidiCollection c) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final folder = await FilePicker.getDirectoryPath(
        dialogTitle: l10n.midiClipsExportFolderTitle,
      );
      if (folder == null) return;
      final dir = Directory(p.join(folder, _safeFolderName(c.name)));
      final written = await MidiClipService.exportAll(
        _collectionExports(c),
        dir,
      );
      _snack(l10n.midiClipsExported(written.length, dir.path));
    } catch (err) {
      _snack(l10n.midiClipSaveFailed(err.toString()));
    }
  }

  static String _safeFolderName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .replaceFirst(RegExp(r'[. ]+$'), '')
        .trim();
    return cleaned.isEmpty ? 'MIDI' : cleaned;
  }

  Future<void> _newCollection() async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptCollectionName(
      context,
      title: l10n.midiCollectionNew,
      action: l10n.midiCollectionCreate,
    );
    if (name == null) return;
    final repo = await ref.read(repositoryProvider.future);
    final created = await repo.midiCollections.create(name);
    if (mounted) _showCollection(created.id);
  }

  Future<void> _renameCollection(MidiCollection c) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptCollectionName(
      context,
      title: l10n.midiCollectionRename,
      action: l10n.midiCollectionRename,
      initial: c.name,
    );
    if (name == null) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.midiCollections.rename(c.id, name);
  }

  Future<void> _deleteCollection(MidiCollection c) async {
    if (!await confirmDeleteCollection(context, c)) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.midiCollections.delete(c.id);
    if (mounted) _showCollection(null);
  }

  Future<void> _newFolder(MidiCollection c) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptCollectionName(
      context,
      title: l10n.midiFolderNew,
      action: l10n.create,
      hint: l10n.midiFolderName,
    );
    if (name == null) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.midiCollections.addFolder(c.id, name, parentId: _folderId);
  }

  Future<void> _renameFolder(MidiCollection c, MidiCollectionFolder f) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptCollectionName(
      context,
      title: l10n.midiFolderRename,
      action: l10n.midiFolderRename,
      initial: f.name,
      hint: l10n.midiFolderName,
    );
    if (name == null) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.midiCollections.renameFolder(c.id, f.id, name);
  }

  Future<void> _moveFolder(MidiCollection c, MidiCollectionFolder f) async {
    final target = await pickMidiFolder(
      context,
      c,
      current: f.parentId,
      exclude: c.folderAndDescendants(f.id),
    );
    if (target == null) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.midiCollections.moveFolder(c.id, f.id, target.id);
  }

  Future<void> _deleteFolder(MidiCollection c, MidiCollectionFolder f) async {
    if (!await confirmDeleteMidiFolder(context, f)) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.midiCollections.deleteFolder(c.id, f.id);
    // Was inside it: show where its contents went.
    if (mounted && c.folderPath(_folderId).any((p) => p.id == f.id)) {
      setState(() => _folderId = c.folderById(f.parentId)?.id);
    }
  }

  Future<void> _editNaming(MidiCollection c) async {
    final labels = midiNamingLabelsOf(AppLocalizations.of(context)!);
    final first = c.items.firstOrNull;
    final picked = await showDialog<MidiNamingTemplate>(
      context: context,
      builder: (_) => MidiNamingDialog(
        initial: c.naming,
        preview: (template) => first == null
            ? null
            : midiTemplateFileName(
                template,
                midiNameParts(
                  first,
                  labels: labels,
                  voice: _voiceOfItem(first),
                  bpm: _tempo ?? first.bpm,
                ),
                number: 1,
              ),
      ),
    );
    if (picked == null) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.midiCollections.setNaming(c.id, picked);
  }

  Future<void> _renameItem(MidiCollection c, MidiCollectionItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await promptCollectionName(
      context,
      title: l10n.midiItemRename,
      action: l10n.midiItemRename,
      initial: item.title ?? '',
      hint: item.clip.label,
      helper: l10n.midiItemNameHint,
      allowBlank: true,
      suggestion: _schemeNameOf(c, item),
      suggestionLabel: l10n.midiNameFromScheme,
    );
    if (name == null) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.midiCollections.renameItem(c.id, item.id, name);
  }

  /// [item]'s name made from [c]'s naming scheme.
  String _schemeNameOf(MidiCollection c, MidiCollectionItem item) =>
      midiSchemeName(
        c.naming,
        midiNameParts(
          item,
          labels: midiNamingLabelsOf(AppLocalizations.of(context)!),
          voice: _voiceOfItem(item),
          bpm: _tempo ?? item.bpm,
        ),
      );

  /// Renames the clips in [folderId] and every folder inside it (null: the
  /// whole collection) by the naming scheme, after the user has looked at —
  /// and corrected — every proposed name. Undoable.
  Future<void> _bulkRename(MidiCollection c, {String? folderId}) async {
    final l10n = AppLocalizations.of(context)!;
    final scope = folderId == null ? null : c.folderAndDescendants(folderId);
    final items = [
      for (final i in c.items)
        if (scope == null || scope.contains(c.folderById(i.folderId)?.id)) i,
    ];
    if (items.isEmpty) return;
    final proposed = uniqueClipNames([
      for (final i in items) _schemeNameOf(c, i),
    ]);
    final renames = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => MidiBulkRenameDialog(
        rows: [
          for (final (n, i) in items.indexed)
            MidiRenameRow(
              itemId: i.id,
              current: i.displayName,
              proposed: proposed[n],
              where: c.folderPath(i.folderId).map((f) => f.name).join(' / '),
            ),
        ],
      ),
    );
    if (renames == null || renames.isEmpty) return;
    final repo = await ref.read(repositoryProvider.future);
    final before = await repo.midiCollections.renameItems(c.id, renames);
    if (!mounted || before.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.midiBulkRenameDone(before.length)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => repo.midiCollections.renameItems(c.id, before),
        ),
      ),
    );
  }

  List<MidiClipRowAction> _folderActions(
    MidiCollection c,
    MidiCollectionFolder f,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return [
      MidiClipRowAction(
        id: 'rename',
        label: l10n.midiFolderRename,
        icon: Icons.drive_file_rename_outline,
        onSelected: () => _renameFolder(c, f),
      ),
      MidiClipRowAction(
        id: 'move',
        label: l10n.midiMoveTo,
        icon: Icons.drive_file_move_outline,
        onSelected: () => _moveFolder(c, f),
      ),
      MidiClipRowAction(
        id: 'bulk-rename',
        label: l10n.midiBulkRenameMenu,
        icon: Icons.auto_fix_high_outlined,
        onSelected: () => _bulkRename(c, folderId: f.id),
      ),
      MidiClipRowAction(
        id: 'delete',
        label: l10n.midiFolderDelete,
        icon: Icons.delete_outline,
        onSelected: () => _deleteFolder(c, f),
      ),
    ];
  }

  MidiCollection? _collectionById(String id) =>
      (ref.read(midiCollectionsProvider).value ?? const <MidiCollection>[])
          .where((c) => c.id == id)
          .firstOrNull;

  bool _canDrop(MidiDragData data, MidiDropTarget target) =>
      canDropMidi(data, target, _collectionById(target.collectionId));

  /// What a drop does: clips move (within a collection, or into another
  /// one), folders move, and a clip from all clips is copied in.
  Future<void> _drop(MidiDragData data, MidiDropTarget target) async {
    final l10n = AppLocalizations.of(context)!;
    final into = _collectionById(target.collectionId);
    if (into == null) return;
    final repo = await ref.read(repositoryProvider.future);
    final store = repo.midiCollections;
    switch (data) {
      case MidiItemDragData d when d.collectionId == target.collectionId:
        await store.moveItemsToFolder(
          target.collectionId,
          d.itemIds,
          target.folderId,
          beforeItemId: target.beforeItemId,
        );
      case MidiItemDragData d:
        final moved = await store.moveItemsToCollection(
          d.collectionId,
          target.collectionId,
          d.itemIds,
          target.folderId,
        );
        _snack(
          moved == 0
              ? l10n.midiCollectionAlreadyIn(into.name)
              : l10n.midiCollectionMoved(moved, into.name),
        );
      case MidiFolderDragData d:
        await store.moveFolder(d.collectionId, d.folderId, target.folderId);
      case MidiLibraryClipDragData d:
        final added = await store.addItems(target.collectionId, [
          d.item.copyWith(
            folderId: target.folderId,
            clearFolder: target.folderId == null,
          ),
        ]);
        _snack(
          added == 0
              ? l10n.midiCollectionAlreadyIn(into.name)
              : l10n.midiCollectionAdded(added, into.name),
        );
    }
    // Into a closed folder: open it, so what went in can be seen there.
    final folder = target.folderId;
    if (mounted &&
        folder != null &&
        !ref.read(midiTreeStateProvider).folders.contains(folder)) {
      _updateTree((t) => t.setFolders([folder], true));
    }
  }

  /// What dragging row [e] carries: the clip of a collection, to move; a
  /// clip of all clips, to copy into one.
  MidiDragData _dragDataOf(_Entry e, MidiCollection? collection) {
    final item = e.item;
    if (collection != null && item != null) {
      return MidiItemDragData(
        collectionId: collection.id,
        itemIds: [item.id],
        label: item.displayName,
      );
    }
    return MidiLibraryClipDragData(
      label: e.clip.label,
      item: collectionItemFor(
        e.clip,
        projectId: e.projectId,
        projectName: e.projectName,
        bpm: e.bpm,
        musicalKey: e.musicalKey,
        pickedVoice: _libraryVoices[e.key],
      ),
    );
  }

  Future<void> _pickRole(MidiCollection c, MidiCollectionItem item) async {
    final picked = await pickMidiClipRole(
      context,
      current: item.chosenRole,
      suggested: suggestMidiClipRole(item.clip, voice: _voiceOfItem(item)),
    );
    if (picked == null) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.midiCollections.setItemRole(c.id, item.id, picked.role);
  }

  Future<void> _moveItem(MidiCollection c, MidiCollectionItem item) async {
    final target = await pickMidiFolder(
      context,
      c,
      current: c.folderById(item.folderId)?.id,
    );
    if (target == null) return;
    final repo = await ref.read(repositoryProvider.future);
    await repo.midiCollections.moveItemsToFolder(c.id, [item.id], target.id);
  }

  Future<void> _shiftItem(
    MidiCollection c,
    MidiCollectionItem item,
    int by,
  ) async {
    final folder = c.folderById(item.folderId)?.id;
    final at = c.itemsIn(folder).indexWhere((i) => i.id == item.id);
    if (at < 0) return;
    final repo = await ref.read(repositoryProvider.future);
    // In ReorderableListView's terms: further down counts the clip itself.
    await repo.midiCollections.reorderInFolder(
      c.id,
      folder,
      at,
      by > 0 ? at + by + 1 : at + by,
    );
  }

  List<MidiClipRowAction> _itemActions(
    MidiCollection c,
    MidiCollectionItem item, {
    required bool ordered,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final siblings = c.itemsIn(c.folderById(item.folderId)?.id);
    final at = siblings.indexWhere((i) => i.id == item.id);
    final role =
        item.chosenRole ??
        suggestMidiClipRole(item.clip, voice: _voiceOfItem(item));
    return [
      MidiClipRowAction(
        id: 'rename',
        label: l10n.midiItemRename,
        icon: Icons.drive_file_rename_outline,
        onSelected: () => _renameItem(c, item),
      ),
      MidiClipRowAction(
        id: 'role',
        label: l10n.midiItemRoleMenu(midiRoleName(l10n, role)),
        icon: Icons.category_outlined,
        onSelected: () => _pickRole(c, item),
      ),
      MidiClipRowAction(
        id: 'move',
        label: l10n.midiMoveTo,
        icon: Icons.drive_file_move_outline,
        onSelected: () => _moveItem(c, item),
      ),
      if (ordered && at > 0)
        MidiClipRowAction(
          id: 'up',
          label: l10n.midiMoveUp,
          icon: Icons.arrow_upward,
          onSelected: () => _shiftItem(c, item, -1),
        ),
      if (ordered && at >= 0 && at < siblings.length - 1)
        MidiClipRowAction(
          id: 'down',
          label: l10n.midiMoveDown,
          icon: Icons.arrow_downward,
          onSelected: () => _shiftItem(c, item, 1),
        ),
    ];
  }

  Future<void> _removeItem(MidiCollection c, MidiCollectionItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = await ref.read(repositoryProvider.future);
    if (_player.playingKey == item.id) await _player.stop();
    await repo.midiCollections.removeItem(c.id, item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.midiCollectionRemoved(item.displayName, c.name)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => repo.midiCollections.addItems(c.id, [item]),
        ),
      ),
    );
  }

  // --- building ------------------------------------------------------------

  List<_Entry> _libraryEntries(List<LibraryClip> library, String query) => [
    for (final l in filterMidiLibrary(
      library,
      query: query,
      voice: _voiceFilter,
    ))
      _Entry(
        key: l.clip.contentKey,
        clip: l.clip,
        bpm: l.bpm,
        musicalKey: l.musicalKey,
        voice: _libraryVoices[l.clip.contentKey] ?? inferSynthVoice(l.clip),
        projectId: l.projectId,
        projectName: l.projectName,
      ),
  ];

  /// Whether a collection shows everything at once (searching, filtering
  /// or by tempo) rather than one folder at a time, in its order.
  bool _flat(String query) =>
      query.trim().isNotEmpty || _byTempo || _voiceFilter != null;

  List<_Entry> _collectionEntries(MidiCollection c, String query) {
    final q = query.trim();
    final names = {for (final f in _plan(c)) f.item.id: f.fileName};
    return [
      for (final item in c.items)
        if ((q.isEmpty ||
                fuzzyMatchAny([
                  item.title,
                  item.clip.name,
                  item.clip.trackName,
                  item.sourceProjectName,
                  item.sourceFileName,
                ], q)) &&
            (_voiceFilter == null || _voiceOfItem(item) == _voiceFilter))
          _Entry(
            key: item.id,
            clip: item.clip,
            bpm: item.bpm,
            musicalKey: item.musicalKey,
            voice: _voiceOfItem(item),
            projectId: item.sourceProjectId,
            // An imported clip says which file it came from instead.
            projectName: item.sourceProjectName ?? item.sourceFileName,
            item: item,
            fileName: names[item.id],
          ),
    ];
  }

  static SynthVoice _voiceOfItem(MidiCollectionItem item) =>
      SynthVoice.values.where((v) => v.name == item.voice).firstOrNull ??
      inferSynthVoice(item.clip);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MobileUtils.isMobile();
    ref.listen<String?>(midiCollectionToOpenProvider, (_, next) {
      if (next != null) _showRequested(next);
    });
    ref.listen<double>(
      midiPreviewVolumeProvider,
      (_, v) => _player.setVolume(v),
    );
    ref.listen<bool>(midiPreviewLoopProvider, (_, v) => _player.setLoop(v));
    final libraryAsync = ref.watch(midiLibraryProvider);
    final collections = ref.watch(midiCollectionsProvider).value ?? const [];
    final query = ref.watch(midiLibrarySearchProvider);
    final library = libraryAsync.value ?? const <LibraryClip>[];

    final selected = _collectionId == null
        ? null
        : collections.where((c) => c.id == _collectionId).firstOrNull;
    // The collection was deleted (here or by a sync): fall back to all clips.
    if (_collectionId != null && selected == null && collections.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCollection(null);
      });
    }

    final navigator = MidiCollectionNavigator(
      allClipsLabel: l10n.midiLibraryAllClips,
      allClipsCount: library.length,
      collectionsLabel: l10n.midiCollectionsTitle,
      newCollectionLabel: l10n.midiCollectionNew,
      collections: collections,
      selectedId: _collectionId,
      selectedFolderId: _folderId,
      onSelect: _showCollection,
      onSelectFolder: (c, f) => _showCollection(c, folderId: f),
      onNew: _newCollection,
      expanded: _tree.nav,
      onToggle: (id) => _updateTree((t) => t.toggleNav(id)),
      onExpandAll: () => _updateTree(
        (t) => t.setNav([
          for (final c in collections) ...[
            c.id,
            for (final f in c.folders) f.id,
          ],
        ], true),
      ),
      onCollapseAll: () => _updateTree(
        (t) => t.setNav([
          for (final c in collections) ...[
            c.id,
            for (final f in c.folders) f.id,
          ],
        ], false),
      ),
      expandAllLabel: l10n.midiExpandAll,
      collapseAllLabel: l10n.midiCollapseAll,
      canDrop: _canDrop,
      onDrop: _drop,
      expandLabel: l10n.expand,
      collapseLabel: l10n.collapse,
      longPressDrag: isMobile,
      horizontal: isMobile,
    );

    final content = selected == null
        ? _buildAllClips(
            context,
            libraryAsync.isLoading && library.isEmpty,
            library,
            query,
          )
        : _buildCollection(context, selected, query);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          navigator,
          const Divider(height: 1),
          Expanded(child: content),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 240, child: navigator),
        const VerticalDivider(width: 1),
        Expanded(child: content),
      ],
    );
  }

  Widget _toolbar(
    BuildContext context,
    List<_Entry> entries, {
    bool inCollection = false,
    MidiCollection? collection,
    bool canOpenAll = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (canOpenAll)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const ValueKey('midi-expand-all'),
                tooltip: l10n.midiExpandAll,
                icon: const Icon(Icons.unfold_more),
                onPressed: () => _setAllOpen(entries, collection, true),
              ),
              IconButton(
                key: const ValueKey('midi-collapse-all'),
                tooltip: l10n.midiCollapseAll,
                icon: const Icon(Icons.unfold_less),
                onPressed: () => _setAllOpen(entries, collection, false),
              ),
            ],
          ),
        DropdownButton<MidiLibraryArrangement>(
          key: const ValueKey('midi-library-arrangement'),
          value: _arrangement,
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem(
              value: MidiLibraryArrangement.project,
              child: Text(
                inCollection
                    ? l10n.midiLibraryArrangeAdded
                    : l10n.midiLibraryArrangeProject,
              ),
            ),
            DropdownMenuItem(
              value: MidiLibraryArrangement.tempo,
              child: Text(l10n.midiLibraryArrangeTempo),
            ),
          ],
          onChanged: (a) {
            if (a != null) setState(() => _arrangement = a);
          },
        ),
        DropdownButton<SynthVoice?>(
          value: _voiceFilter,
          underline: const SizedBox.shrink(),
          hint: Text(l10n.midiLibraryAllInstruments),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(l10n.midiLibraryAllInstruments),
            ),
            for (final v in SynthVoice.values)
              DropdownMenuItem(value: v, child: Text(synthVoiceName(l10n, v))),
          ],
          onChanged: (v) => setState(() => _voiceFilter = v),
        ),
        MidiTempoControl(
          bpm: _tempo,
          onChanged: (bpm) {
            setState(() => _tempo = bpm);
            _restartIfPlaying(entries);
          },
          onReset: _tempo == null
              ? null
              : () {
                  setState(() => _tempo = null);
                  _restartIfPlaying(entries);
                },
          resetTooltip: l10n.midiTempoResetAuto,
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
              volume: ref.watch(midiPreviewVolumeProvider),
              onChanged: ref.read(midiPreviewVolumeProvider.notifier).set,
              labels: midiVolumeLabelsOf(l10n),
            ),
          ],
        ),
      ],
    );
  }

  Widget _list(
    BuildContext context,
    List<_Entry> entries, {
    required bool grouped,
    MidiCollection? collection,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MobileUtils.isMobile();
    final clips = [for (final e in entries) e.clip];
    int? indexOfKey(String? key) {
      if (key == null) return null;
      final i = entries.indexWhere((e) => e.key == key);
      return i < 0 ? null : i;
    }

    final labels = midiClipListLabelsOf(l10n);
    // A clip's instrument, picked in its row or in its piano roll: kept on
    // the collection item, or for this session in the library.
    Future<void> setVoice(_Entry e, SynthVoice v) async {
      if (collection != null && e.item != null) {
        final repo = await ref.read(repositoryProvider.future);
        await repo.midiCollections.setItemVoice(
          collection.id,
          e.item!.id,
          v.name,
        );
      } else {
        setState(() => _libraryVoices[e.key] = v);
      }
    }

    // By tempo, every view is grouped under its BPM, and each row names
    // its project since the heading no longer does.
    final byProject = grouped && !_byTempo;
    final query = ref.read(midiLibrarySearchProvider);
    final flat = collection != null && _flat(query);
    return MidiClipList(
      clips: clips,
      labels: labels,
      compact: isMobile,
      grouped: grouped || _byTempo,
      expandAllUpTo: 40,
      groupLabelOf: (i) => _groupLabelOf(entries[i], l10n),
      groupOpen: (label) => _tree.groups[_groupKey(label)],
      onGroupToggled: (label, open) =>
          _updateTree((t) => t.setGroups([_groupKey(label)], open)),
      detailPrefixOf: (i) {
        if (byProject) return entries[i].clip.trackName;
        final item = entries[i].item;
        return [
          if (collection != null && item != null) ...[
            midiRoleName(
              l10n,
              item.chosenRole ??
                  suggestMidiClipRole(item.clip, voice: entries[i].voice),
            ),
            // Showing every folder at once: say which each clip is in.
            if (flat)
              collection
                  .folderPath(item.folderId)
                  .map((f) => f.name)
                  .join(' / '),
          ],
          entries[i].projectName,
          entries[i].clip.trackName,
        ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
      },
      titleOf: collection == null ? null : (i) => entries[i].item!.displayName,
      fileNameOf: collection == null ? null : (i) => entries[i].fileName,
      actionsOf: collection == null
          ? null
          : (i) => _itemActions(collection, entries[i].item!, ordered: !flat),
      playingIndex: indexOfKey(_player.playingKey),
      preparingIndex: indexOfKey(_player.preparingKey),
      onPlay: (i) => _play(entries[i]),
      onOpenProject: (i) => _openProject(entries[i]),
      canOpenProjectOf: (i) => entries[i].projectId != null,
      onOpen: (i) {
        final e = entries[i];
        showMidiPianoRoll(
          context,
          clip: e.clip,
          title: e.item?.displayName ?? e.clip.label,
          subtitle: e.projectName,
          player: _player,
          playerKey: e.key,
          bpm: _bpmOf(e),
          onPlay: (voice, bpm) => _play(e, voice: voice, bpm: bpm),
          timeSignature: _timeSignatureOf(e.item),
          onOpenProject: e.projectId == null ? null : () => _openProject(e),
          musicalKey: e.musicalKey,
          voice: e.voice,
          onVoiceChanged: (v) => setVoice(e, v),
          onSaveEdited: (edit) => addToCollectionFlow(context, ref, [
            collectionItemFor(
              edit.clip,
              projectId: e.projectId,
              projectName: e.projectName,
              bpm: edit.bpm,
              musicalKey: edit.musicalKey,
              pickedVoice: edit.voice,
              timeSignature: edit.timeSignature,
            ),
          ]),
        );
      },
      onShare: (i, origin) => _share(entries[i], origin),
      onSave: isMobile ? null : (i) => _save(entries[i]),
      voiceOf: (i) => entries[i].voice,
      onVoiceChanged: (i, v) async {
        final e = entries[i];
        await setVoice(e, v);
        if (_player.playingKey == e.key) {
          await _player.play(e.key, e.clip, bpm: _bpmOf(e), voice: v);
        }
      },
      onAddToCollection: collection != null
          ? null
          : (i, origin) {
              final e = entries[i];
              addToCollectionFlow(context, ref, [
                collectionItemFor(
                  e.clip,
                  projectId: e.projectId,
                  projectName: e.projectName,
                  bpm: e.bpm,
                  musicalKey: e.musicalKey,
                  pickedVoice: _libraryVoices[e.key],
                ),
              ], origin: origin);
            },
      onRemove: collection == null
          ? null
          : (i) => _removeItem(collection, entries[i].item!),
      grabWrapper: (context, i, child) => midiDragSource(
        data: _dragDataOf(entries[i], collection),
        longPress: isMobile,
        child: child,
      ),
      // Dropped on a row: in its folder, just before it. Not while every
      // folder shows at once, in an order that isn't the folders'.
      rowWrapper: collection == null || flat
          ? null
          : (context, i, row) {
              final item = entries[i].item!;
              return MidiDropZone(
                target: MidiDropTarget(
                  collection.id,
                  folderId: collection.folderById(item.folderId)?.id,
                  beforeItemId: item.id,
                ),
                canDrop: _canDrop,
                onDrop: _drop,
                lineAbove: true,
                child: row,
              );
            },
      dragHandleBuilder: isMobile
          ? null
          : (context, index, handle) => DragItemWidget(
              allowedOperations: () => [DropOperation.copy],
              dragItemProvider: (request) async {
                final path = await _dragFile(entries[index]);
                final item = DragItem(suggestedName: p.basename(path));
                item.add(Formats.fileUri(Uri.file(path)));
                return item;
              },
              child: DraggableWidget(child: handle),
            ),
    );
  }

  Widget _buildAllClips(
    BuildContext context,
    bool loading,
    List<LibraryClip> library,
    String query,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entries = _arranged(_libraryEntries(library, query));
    return ListView(
      padding: MobileUtils.getResponsivePadding(context),
      children: [
        Row(
          children: [
            Text(l10n.midiLibraryAllClips, style: theme.textTheme.titleMedium),
            const SizedBox(width: 8),
            Text('${entries.length}', style: theme.textTheme.bodySmall),
            const Spacer(),
            TextButton.icon(
              onPressed: () => importMidiFilesFlow(context, ref),
              icon: const Icon(Icons.file_open_outlined, size: 18),
              label: Text(l10n.midiImportFiles),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _toolbar(context, entries, canOpenAll: entries.isNotEmpty),
        const SizedBox(height: 8),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (library.isEmpty)
          _empty(context, l10n.midiLibraryEmpty)
        else if (entries.isEmpty)
          _empty(context, l10n.midiLibraryNoMatches)
        else
          _list(context, entries, grouped: true),
      ],
    );
  }

  Widget _buildCollection(
    BuildContext context,
    MidiCollection c,
    String query,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    // The folder on show went (deleted here or by a sync): its parent's
    // contents are where it was.
    if (_folderId != null && c.folderById(_folderId) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _folderId = null);
      });
    }
    final folderId = c.folderById(_folderId)?.id;
    final flat = _flat(query);
    final entries = _arranged(_collectionEntries(c, query));
    final path = c.folderPath(folderId);
    return ListView(
      padding: MobileUtils.getResponsivePadding(context),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dropped on the name: out of any folder, to the top level.
            Flexible(
              child: MidiDropZone(
                key: const ValueKey('midi-collection-top-drop'),
                target: MidiDropTarget(c.id),
                canDrop: _canDrop,
                onDrop: _drop,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.library_music_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          c.name,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${c.items.length}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              key: const ValueKey('midi-collection-new-clip'),
              tooltip: l10n.midiNewClip,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _newClip(c),
            ),
            IconButton(
              key: const ValueKey('midi-collection-new-folder'),
              tooltip: l10n.midiFolderNew,
              icon: const Icon(Icons.create_new_folder_outlined),
              onPressed: () => _newFolder(c),
            ),
            IconButton(
              tooltip: l10n.midiImportFiles,
              icon: const Icon(Icons.file_open_outlined),
              onPressed: () => importMidiFilesFlow(context, ref, into: c),
            ),
            IconButton(
              tooltip: l10n.midiCollectionRename,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _renameCollection(c),
            ),
            IconButton(
              tooltip: l10n.midiCollectionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteCollection(c),
            ),
          ],
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            if (c.items.isNotEmpty) ...[
              Builder(
                builder: (buttonContext) => TextButton.icon(
                  onPressed: () =>
                      _shareCollection(c, shareOriginOf(buttonContext)),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: Text(l10n.midiClipsShareAll),
                ),
              ),
              Builder(
                builder: (buttonContext) => TextButton.icon(
                  onPressed: () =>
                      _shareCollectionZip(c, shareOriginOf(buttonContext)),
                  icon: const Icon(Icons.folder_zip_outlined, size: 18),
                  label: Text(l10n.midiCollectionShareZip),
                ),
              ),
              if (!MobileUtils.isMobile())
                TextButton.icon(
                  onPressed: () => _exportCollection(c),
                  icon: const Icon(
                    Icons.drive_folder_upload_outlined,
                    size: 18,
                  ),
                  label: Text(l10n.midiClipsExportAll),
                ),
            ],
            TextButton.icon(
              key: const ValueKey('midi-collection-naming'),
              onPressed: () => _editNaming(c),
              icon: const Icon(Icons.label_outline, size: 18),
              label: Text(l10n.midiNamingTitle),
            ),
            if (c.items.isNotEmpty)
              TextButton.icon(
                key: const ValueKey('midi-collection-bulk-rename'),
                onPressed: () => _bulkRename(c, folderId: folderId),
                icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                label: Text(l10n.midiBulkRenameMenu),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _toolbar(
          context,
          entries,
          inCollection: true,
          collection: c,
          // Folders to open in the tree, or tempo groups while flat.
          canOpenAll: flat
              ? _byTempo && entries.isNotEmpty
              : c.folders.isNotEmpty,
        ),
        const SizedBox(height: 8),
        if (c.items.isEmpty && c.folders.isEmpty)
          _empty(context, l10n.midiCollectionEmpty)
        else if (flat)
          entries.isEmpty
              ? _empty(context, l10n.midiLibraryNoMatches)
              : _list(context, entries, grouped: false, collection: c)
        else ...[
          if (path.isNotEmpty) _breadcrumb(context, c, path),
          MidiCollectionTree(
            collection: c,
            rootFolderId: folderId,
            expanded: _tree.folders,
            onToggle: (id) => _updateTree((t) => t.toggleFolder(id)),
            clipsIn: (context, inFolder) {
              final here = [
                for (final e in entries)
                  if (c.folderById(e.item!.folderId)?.id == inFolder) e,
              ];
              return here.isEmpty
                  ? null
                  : _list(context, here, grouped: false, collection: c);
            },
            folderActions: (f) => _folderActions(c, f),
            canDrop: _canDrop,
            onDrop: _drop,
            expandLabel: l10n.expand,
            collapseLabel: l10n.collapse,
            moreLabel: l10n.midiClipMoreActions,
            longPressDrag: MobileUtils.isMobile(),
          ),
        ],
      ],
    );
  }

  /// Where in [c] the view is: the collection, then each folder down to
  /// the one on show; any but the last goes back there, and each takes
  /// drops into it.
  Widget _breadcrumb(
    BuildContext context,
    MidiCollection c,
    List<MidiCollectionFolder> path,
  ) {
    final theme = Theme.of(context);
    final steps = <(String?, String)>[
      (null, c.name),
      for (final f in path) (f.id, f.name),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (i, (id, name)) in steps.indexed) ...[
            if (i > 0)
              Icon(Icons.chevron_right, size: 18, color: theme.hintColor),
            MidiDropZone(
              target: MidiDropTarget(c.id, folderId: id),
              canDrop: _canDrop,
              onDrop: _drop,
              child: i == steps.length - 1
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : TextButton(
                      key: ValueKey('midi-breadcrumb-${id ?? 'top'}'),
                      onPressed: () => setState(() => _folderId = id),
                      child: Text(name),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}
