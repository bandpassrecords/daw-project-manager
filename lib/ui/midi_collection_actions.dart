import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/midi_clip.dart';
import '../models/midi_collection.dart';
import '../providers/providers.dart';
import '../repository/midi_collection_store.dart';
import '../services/midi/synth_voice.dart';

/// A copy of [clip] ready to go into a collection, remembering where it came
/// from and the tempo and instrument it was being heard with.
MidiCollectionItem collectionItemFor(
  MidiClip clip, {
  String? projectId,
  String? projectName,
  double? bpm,
  SynthVoice? pickedVoice,
}) =>
    MidiCollectionItem(
      id: MidiCollectionStore.newItemId(),
      clip: clip,
      addedAt: DateTime.now(),
      sourceProjectId: projectId,
      sourceProjectName: projectName,
      bpm: bpm,
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
  messenger.showSnackBar(SnackBar(
    content: Text(
      added == 0
          ? l10n.midiCollectionAlreadyIn(target.name)
          : l10n.midiCollectionAdded(added, target.name),
    ),
  ));
}

/// A name for a new or renamed collection, or null if cancelled. Blank names
/// can't be confirmed.
Future<String?> promptCollectionName(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
}) {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final valid = controller.text.trim().isNotEmpty;
        void submit() {
          if (controller.text.trim().isNotEmpty) {
            Navigator.of(context).pop(controller.text.trim());
          }
        }

        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.midiCollectionNameHint),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: valid ? submit : null,
              child: Text(action),
            ),
          ],
        );
      },
    ),
  ).whenComplete(controller.dispose);
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
