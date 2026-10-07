import 'midi_collection.dart';

/// What is being dragged around the MIDI tab.
sealed class MidiDragData {
  const MidiDragData();

  /// What the drag shows under the pointer.
  String get label;
}

/// Clips of a collection, to move: into another of its folders, before
/// another of its clips, or into another collection.
class MidiItemDragData extends MidiDragData {
  const MidiItemDragData({
    required this.collectionId,
    required this.itemIds,
    required this.label,
  });

  final String collectionId;
  final List<String> itemIds;
  @override
  final String label;
}

/// A folder of a collection, to move into another of its folders (or to
/// its top level). Folders stay in their collection.
class MidiFolderDragData extends MidiDragData {
  const MidiFolderDragData({
    required this.collectionId,
    required this.folderId,
    required this.label,
  });

  final String collectionId;
  final String folderId;
  @override
  final String label;
}

/// A clip from "All clips", to copy into a collection: [item] is the copy,
/// made ready when the drag starts.
class MidiLibraryClipDragData extends MidiDragData {
  const MidiLibraryClipDragData({required this.item, required this.label});

  final MidiCollectionItem item;
  @override
  final String label;
}

/// Where a drag can land: collection [collectionId], in folder [folderId]
/// (null: its top level) — at its end, or just before clip [beforeItemId].
class MidiDropTarget {
  const MidiDropTarget(this.collectionId, {this.folderId, this.beforeItemId});

  final String collectionId;
  final String? folderId;
  final String? beforeItemId;

  @override
  bool operator ==(Object other) =>
      other is MidiDropTarget &&
      other.collectionId == collectionId &&
      other.folderId == folderId &&
      other.beforeItemId == beforeItemId;

  @override
  int get hashCode => Object.hash(collectionId, folderId, beforeItemId);
}

/// Whether [data] can be dropped on [target], in collection [into] (the
/// target's, null when it is gone). Refused: a clip before itself, a
/// folder into itself, anything inside it or where it already is, a folder
/// into another collection or between clips, and a library clip into a
/// collection that already plays it.
bool canDropMidi(
  MidiDragData data,
  MidiDropTarget target,
  MidiCollection? into,
) {
  if (into == null || into.deleted || into.id != target.collectionId) {
    return false;
  }
  if (target.folderId != null && into.folderById(target.folderId) == null) {
    return false;
  }
  switch (data) {
    case MidiItemDragData(:final collectionId, :final itemIds):
      if (itemIds.isEmpty) return false;
      if (target.beforeItemId != null) {
        if (collectionId != target.collectionId) return false;
        if (itemIds.contains(target.beforeItemId)) return false;
      }
      return true;
    case MidiFolderDragData(:final collectionId, :final folderId):
      if (collectionId != target.collectionId) return false;
      if (target.beforeItemId != null) return false;
      final folder = into.folderById(folderId);
      if (folder == null) return false;
      if (target.folderId != null &&
          into.folderAndDescendants(folderId).contains(target.folderId)) {
        return false;
      }
      return into.folderById(folder.parentId)?.id != target.folderId;
    case MidiLibraryClipDragData(:final item):
      return !into.containsClip(item.clip);
  }
}
