import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../models/midi_collection.dart';
import '../providers/providers.dart';
import '../repository/midi_collection_store.dart';
import '../services/midi/synth_voice.dart';

/// A copy of [clip] ready to go into a collection, remembering where it came
/// from, its project's tempo and key, and the instrument it was being heard
/// with.
MidiCollectionItem collectionItemFor(
  MidiClip clip, {
  String? projectId,
  String? projectName,
  double? bpm,
  String? musicalKey,
  SynthVoice? pickedVoice,
}) =>
    MidiCollectionItem(
      id: MidiCollectionStore.newItemId(),
      clip: clip,
      addedAt: DateTime.now(),
      sourceProjectId: projectId,
      sourceProjectName: projectName,
      bpm: bpm,
      musicalKey: musicalKey,
      voice: pickedVoice?.name,
    );

/// Asks which collection to put [items] in — every existing one, or a new
/// one — and adds them there. Shows what happened in a snackbar.
Future<void> addToCollectionFlow(
  BuildContext context,
  WidgetRef ref,
  List<MidiCollectionItem> items, {
  Rect? origin,
}) async {
  if (items.isEmpty) return;
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  // Captured now: by the time the snackbar's Open is pressed this context
  // may be gone (a closed dialog, a page popped).
  final navigator = Navigator.of(context, rootNavigator: true);
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final repo = await ref.read(repositoryProvider.future);
  final collections = await repo.midiCollections.all();
  if (!context.mounted) return;

  const newChoice = '\u0000new';
  final anchor = origin ??
      Rect.fromCenter(
        center: overlay.size.center(Offset.zero),
        width: 1,
        height: 1,
      );
  final picked = await showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(anchor, Offset.zero & overlay.size),
    items: [
      for (final c in collections)
        PopupMenuItem(
          value: c.id,
          child: Row(
            children: [
              const Icon(Icons.library_music_outlined, size: 18),
              const SizedBox(width: 10),
              Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      if (collections.isNotEmpty) const PopupMenuDivider(),
      PopupMenuItem(
        value: newChoice,
        child: Row(
          children: [
            const Icon(Icons.add, size: 18),
            const SizedBox(width: 10),
            Text(l10n.midiCollectionNew),
          ],
        ),
      ),
    ],
  );
  if (picked == null || !context.mounted) return;

  MidiCollection? target;
  if (picked == newChoice) {
    final name = await promptCollectionName(
      context,
      title: l10n.midiCollectionNew,
      action: l10n.midiCollectionCreate,
    );
    if (name == null) return;
    target = await repo.midiCollections.create(name);
  } else {
    target = collections.firstWhere((c) => c.id == picked);
  }

  final added = await repo.midiCollections.addItems(target.id, items);
  final collectionId = target.id;
  // Only when there is a MIDI tab to open it in (the user may hide it).
  final canOpen = ref.read(visibleTabsProvider).contains(AppTab.midi);
  messenger.showSnackBar(SnackBar(
    content: Text(
      added == 0
          ? l10n.midiCollectionAlreadyIn(target.name)
          : l10n.midiCollectionAdded(added, target.name),
    ),
    action: canOpen
        ? SnackBarAction(
            label: l10n.midiCollectionOpen,
            onPressed: () {
              // Back to the dashboard (from a project page, say), then let
              // it and the MIDI tab take the request.
              navigator.popUntil((route) => route.isFirst);
              ref.read(midiCollectionToOpenProvider.notifier).open(collectionId);
            },
          )
        : null,
  ));
}

/// A name for a new or renamed collection, or null if cancelled. Blank names
/// can't be confirmed.
Future<String?> promptCollectionName(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
}) =>
    showDialog<String>(
      context: context,
      builder: (_) => CollectionNameDialog(
        title: title,
        action: action,
        initial: initial,
      ),
    );

/// The dialog behind [promptCollectionName].
///
/// A widget of its own so it owns its text controller: the dialog is still
/// on screen for its closing animation after the result is returned, so a
/// controller disposed by the caller on return was used after disposal.
class CollectionNameDialog extends StatefulWidget {
  const CollectionNameDialog({
    super.key,
    required this.title,
    required this.action,
    this.initial = '',
  });

  final String title;
  final String action;
  final String initial;

  @override
  State<CollectionNameDialog> createState() => _CollectionNameDialogState();
}

class _CollectionNameDialogState extends State<CollectionNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => _controller.text.trim();

  void _submit() {
    if (_name.isNotEmpty) Navigator.of(context).pop(_name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.midiCollectionNameHint),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _name.isEmpty ? null : _submit,
          child: Text(widget.action),
        ),
      ],
    );
  }
}

/// Confirms deleting [collection]. Its clips are copies, so nothing in any
/// project is touched — the message says so.
Future<bool> confirmDeleteCollection(
  BuildContext context,
  MidiCollection collection,
) async {
  final l10n = AppLocalizations.of(context)!;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.midiCollectionDelete),
      content: Text(l10n.midiCollectionDeleteConfirm(collection.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}
