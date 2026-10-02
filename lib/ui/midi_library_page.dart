import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../models/midi_collection.dart';
import '../models/midi_library.dart';
import '../providers/providers.dart';
import '../services/midi/midi_clip_service.dart';
import '../services/midi/midi_file_writer.dart';
import '../services/midi/synth_voice.dart';
import '../utils/mobile_utils.dart';
import '../utils/search_utils.dart';
import 'midi_clip_share.dart';
import 'midi_collection_actions.dart';
import 'midi_piano_roll_dialog.dart';
import 'project_detail_page.dart';
import 'midi_preview_player.dart';
import 'widgets/midi_clip_list.dart';
import 'widgets/midi_clips_section.dart'
    show midiClipListLabelsOf, midiTempoLabelsOf, midiVolumeLabelsOf, synthVoiceName;
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
    this.projectId,
    this.projectName,
    this.item,
  });

  /// Player key: the clip's content in the library, the item id in a
  /// collection (one collection never holds the same notes twice, but ids
  /// are what removal goes by).
  final String key;
  final MidiClip clip;
  final double? bpm;
  final SynthVoice voice;
  final String? projectId;
  final String? projectName;
  final MidiCollectionItem? item;
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
  SynthVoice? _voiceFilter;

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
    // A request made before this tab was built (the Open action switched to
    // it) is waiting in the provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(midiCollectionToOpenProvider);
      if (pending != null) _showRequested(pending);
    });
  }

  void _showRequested(String collectionId) {
    setState(() => _collectionId = collectionId);
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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _play(_Entry e) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _player.toggle(e.key, e.clip, bpm: _bpmOf(e), voice: e.voice);
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
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: l10n.midiClipSave,
        fileName: midiClipFileName(e.clip),
        type: FileType.custom,
        allowedExtensions: ['mid'],
      );
      if (path == null) return;
      final target = p.extension(path).isEmpty ? '$path.mid' : path;
      await MidiClipService.writeMidiFile(e.clip, target, bpm: _bpmOf(e));
      _snack(l10n.midiClipSaved(p.basename(target)));
    } catch (err) {
      _snack(l10n.midiClipSaveFailed(err.toString()));
    }
  }

  Future<void> _copy(_Entry e) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final ok = await copyMidiClipToClipboard(e.clip, bpm: _bpmOf(e));
      _snack(ok
          ? l10n.midiClipCopied(midiClipFileName(e.clip))
          : l10n.midiClipCopyUnavailable);
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProjectDetailPage(projectId: id)),
    );
  }

  Future<String> _dragFile(_Entry e) async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, 'daw_project_manager', 'midi_drag',
        DateTime.now().microsecondsSinceEpoch.toString()));
    await dir.create(recursive: true);
    final path = p.join(dir.path, midiClipFileName(e.clip));
    await MidiClipService.writeMidiFile(e.clip, path, bpm: _bpmOf(e));
    return path;
  }

  Future<void> _share(_Entry e, Rect? origin) async {
    final l10n = AppLocalizations.of(context)!;
    await shareMidiClips(
      context,
      [e.clip],
      text: e.projectName == null
          ? e.clip.label
          : l10n.midiClipShareText(e.clip.label, e.projectName!),
      bpm: _bpmOf(e),
      origin: origin,
    );
  }

  Future<void> _shareCollection(MidiCollection c, Rect? origin) async {
    final l10n = AppLocalizations.of(context)!;
    await shareMidiClips(
      context,
      [for (final i in c.items) i.clip],
      text: l10n.midiCollectionShareText(c.name),
      // A collection mixes tempos; one shared tempo only if the user set it.
      bpm: _tempo,
      origin: origin,
    );
  }

  Future<void> _shareCollectionZip(MidiCollection c, Rect? origin) async {
    final l10n = AppLocalizations.of(context)!;
    await shareMidiClips(
      context,
      [for (final i in c.items) i.clip],
      text: l10n.midiCollectionShareText(c.name),
      bpm: _tempo,
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
      final names = uniqueFileNames(c.items.map((i) => midiClipFileName(i.clip)).toList());
      await dir.create(recursive: true);
      for (var i = 0; i < c.items.length; i++) {
        final item = c.items[i];
        await MidiClipService.writeMidiFile(
          item.clip,
          p.join(dir.path, names[i]),
          bpm: _tempo ?? item.bpm,
        );
      }
      _snack(l10n.midiClipsExported(c.items.length, dir.path));
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
    if (mounted) setState(() => _collectionId = created.id);
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
    if (mounted) setState(() => _collectionId = null);
  }

  Future<void> _removeItem(MidiCollection c, MidiCollectionItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = await ref.read(repositoryProvider.future);
    if (_player.playingKey == item.id) await _player.stop();
    await repo.midiCollections.removeItem(c.id, item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n.midiCollectionRemoved(item.clip.label, c.name)),
      action: SnackBarAction(
        label: l10n.undo,
        onPressed: () => repo.midiCollections.addItems(c.id, [item]),
      ),
    ));
  }

  // --- building ------------------------------------------------------------

  List<_Entry> _libraryEntries(List<LibraryClip> library, String query) => [
        for (final l in filterMidiLibrary(library, query: query, voice: _voiceFilter))
          _Entry(
            key: l.clip.contentKey,
            clip: l.clip,
            bpm: l.bpm,
            voice: _libraryVoices[l.clip.contentKey] ?? inferSynthVoice(l.clip),
            projectId: l.projectId,
            projectName: l.projectName,
          ),
      ];

  List<_Entry> _collectionEntries(MidiCollection c, String query) {
    final q = query.trim();
    return [
      for (final item in c.items)
        if ((q.isEmpty ||
                fuzzyMatchAny([
                  item.clip.name,
                  item.clip.trackName,
                  item.sourceProjectName,
                ], q)) &&
            (_voiceFilter == null || _voiceOfItem(item) == _voiceFilter))
          _Entry(
            key: item.id,
            clip: item.clip,
            bpm: item.bpm,
            voice: _voiceOfItem(item),
            projectId: item.sourceProjectId,
            projectName: item.sourceProjectName,
            item: item,
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
    ref.listen<double>(midiPreviewVolumeProvider, (_, v) => _player.setVolume(v));
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
        if (mounted) setState(() => _collectionId = null);
      });
    }

    final navigator = MidiCollectionNavigator(
      allClipsLabel: l10n.midiLibraryAllClips,
      allClipsCount: library.length,
      collectionsLabel: l10n.midiCollectionsTitle,
      newCollectionLabel: l10n.midiCollectionNew,
      collections: [for (final c in collections) (id: c.id, name: c.name, count: c.items.length)],
      selectedId: _collectionId,
      onSelect: (id) => setState(() => _collectionId = id),
      onNew: _newCollection,
      horizontal: isMobile,
    );

    final content = selected == null
        ? _buildAllClips(context, libraryAsync.isLoading && library.isEmpty, library, query)
        : _buildCollection(context, selected, query);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [navigator, const Divider(height: 1), Expanded(child: content)],
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

  Widget _toolbar(BuildContext context, List<_Entry> entries) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<SynthVoice?>(
          value: _voiceFilter,
          underline: const SizedBox.shrink(),
          hint: Text(l10n.midiLibraryAllInstruments),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.midiLibraryAllInstruments)),
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
        MidiVolumeControl(
          volume: ref.watch(midiPreviewVolumeProvider),
          onChanged: ref.read(midiPreviewVolumeProvider.notifier).set,
          labels: midiVolumeLabelsOf(l10n),
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
    return MidiClipList(
      clips: clips,
      labels: labels,
      compact: isMobile,
      grouped: grouped,
      expandAllUpTo: 40,
      groupLabelOf: (i) => entries[i].projectName,
      detailPrefixOf: (i) => grouped
          ? entries[i].clip.trackName
          : [entries[i].projectName, entries[i].clip.trackName]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .join(' · '),
      playingIndex: indexOfKey(_player.playingKey),
      preparingIndex: indexOfKey(_player.preparingKey),
      onPlay: (i) => _play(entries[i]),
      onCopy: isMobile ? null : (i) => _copy(entries[i]),
      onOpenProject: (i) => _openProject(entries[i]),
      onOpen: (i) {
        final e = entries[i];
        showMidiPianoRoll(
          context,
          clip: e.clip,
          title: e.clip.label,
          subtitle: e.projectName,
          player: _player,
          playerKey: e.key,
          bpm: _bpmOf(e),
          onPlay: () => _play(e),
          onCopy: MobileUtils.isMobile() ? null : () => _copy(e),
          onOpenProject: e.projectId == null ? null : () => _openProject(e),
        );
      },
      onShare: (i, origin) => _share(entries[i], origin),
      onSave: isMobile ? null : (i) => _save(entries[i]),
      voiceOf: (i) => entries[i].voice,
      onVoiceChanged: (i, v) async {
        final e = entries[i];
        if (collection != null && e.item != null) {
          final repo = await ref.read(repositoryProvider.future);
          await repo.midiCollections.setItemVoice(collection.id, e.item!.id, v.name);
        } else {
          setState(() => _libraryVoices[e.key] = v);
        }
        if (_player.playingKey == e.key) {
          await _player.play(e.key, e.clip, bpm: _bpmOf(e), voice: v);
        }
      },
      onAddToCollection: collection != null
          ? null
          : (i, origin) {
              final e = entries[i];
              addToCollectionFlow(
                context,
                ref,
                [
                  collectionItemFor(
                    e.clip,
                    projectId: e.projectId,
                    projectName: e.projectName,
                    bpm: e.bpm,
                    pickedVoice: _libraryVoices[e.key],
                  ),
                ],
                origin: origin,
              );
            },
      onRemove: collection == null
          ? null
          : (i) => _removeItem(collection, entries[i].item!),
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
    final entries = _libraryEntries(library, query);
    return ListView(
      padding: MobileUtils.getResponsivePadding(context),
      children: [
        Row(
          children: [
            Text(l10n.midiLibraryAllClips, style: theme.textTheme.titleMedium),
            const SizedBox(width: 8),
            Text('${entries.length}', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        _toolbar(context, entries),
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

  Widget _buildCollection(BuildContext context, MidiCollection c, String query) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entries = _collectionEntries(c, query);
    return ListView(
      padding: MobileUtils.getResponsivePadding(context),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.library_music_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                c.name,
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('${c.items.length}', style: theme.textTheme.bodySmall),
            const Spacer(),
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
        if (c.items.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              Builder(
                builder: (buttonContext) => TextButton.icon(
                  onPressed: () => _shareCollection(c, shareOriginOf(buttonContext)),
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
                  icon: const Icon(Icons.drive_folder_upload_outlined, size: 18),
                  label: Text(l10n.midiClipsExportAll),
                ),
            ],
          ),
        const SizedBox(height: 8),
        _toolbar(context, entries),
        const SizedBox(height: 8),
        if (c.items.isEmpty)
          _empty(context, l10n.midiCollectionEmpty)
        else if (entries.isEmpty)
          _empty(context, l10n.midiLibraryNoMatches)
        else
          _list(context, entries, grouped: false, collection: c),
      ],
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

/// "All clips" plus every collection, and a way to make a new one — a side
/// list on desktop, a row of chips on a phone ([horizontal]).
///
/// A plain view: names, counts and callbacks, no Hive.
class MidiCollectionNavigator extends StatelessWidget {
  const MidiCollectionNavigator({
    super.key,
    required this.allClipsLabel,
    required this.allClipsCount,
    required this.collectionsLabel,
    required this.newCollectionLabel,
    required this.collections,
    required this.selectedId,
    required this.onSelect,
    required this.onNew,
    this.horizontal = false,
  });

  final String allClipsLabel;
  final int allClipsCount;
  final String collectionsLabel;
  final String newCollectionLabel;
  final List<({String id, String name, int count})> collections;

  /// The collection on show, or null for all clips.
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onNew;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ChoiceChip(
              label: Text('$allClipsLabel ($allClipsCount)'),
              selected: selectedId == null,
              onSelected: (_) => onSelect(null),
            ),
            for (final c in collections) ...[
              const SizedBox(width: 8),
              ChoiceChip(
                avatar: const Icon(Icons.library_music_outlined, size: 16),
                label: Text('${c.name} (${c.count})'),
                selected: selectedId == c.id,
                onSelected: (_) => onSelect(c.id),
              ),
            ],
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text(newCollectionLabel),
              onPressed: onNew,
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.piano),
          title: Text(allClipsLabel),
          trailing: Text('$allClipsCount', style: theme.textTheme.bodySmall),
          selected: selectedId == null,
          onTap: () => onSelect(null),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  collectionsLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                tooltip: newCollectionLabel,
                icon: const Icon(Icons.add, size: 20),
                onPressed: onNew,
              ),
            ],
          ),
        ),
        for (final c in collections)
          ListTile(
            dense: true,
            leading: const Icon(Icons.library_music_outlined),
            title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text('${c.count}', style: theme.textTheme.bodySmall),
            selected: selectedId == c.id,
            onTap: () => onSelect(c.id),
          ),
      ],
    );
  }
}
