import 'dart:convert';

import 'midi_clip.dart';
import 'midi_clip_naming.dart';
import 'stored_midi_clips.dart';

/// One clip in a [MidiCollection]: a **copy** of the clip, not a link to it.
///
/// A copy keeps working after the source project is edited, re-extracted,
/// archived or deleted, and makes a collection self-contained to share. The
/// source is remembered only to show and open where the clip came from.
class MidiCollectionItem {
  const MidiCollectionItem({
    required this.id,
    required this.clip,
    required this.addedAt,
    this.sourceProjectId,
    this.sourceProjectName,
    this.sourceFileName,
    this.bpm,
    this.musicalKey,
    this.voice,
    this.timeSignature,
    this.title,
    this.role,
    this.folderId,
  });

  final String id;
  final MidiClip clip;
  final DateTime addedAt;

  /// The project the clip was copied from; it may no longer exist.
  final String? sourceProjectId;

  /// That project's name when the clip was copied, so the collection can
  /// still say where it came from after the project is gone.
  final String? sourceProjectName;

  /// For a clip imported from a `.mid` file rather than copied from a
  /// project: that file's name. Such an item has no source project.
  final String? sourceFileName;

  /// The source project's tempo at copy time — what the clip previews and
  /// exports at unless the user picks another.
  final double? bpm;

  /// The source project's key at copy time ("A minor", "F#m"…), written
  /// into the clip's exported `.mid` file and its name.
  final String? musicalKey;

  /// The preview instrument chosen for this clip (a `SynthVoice` name), or
  /// null to infer one from the clip's names.
  final String? voice;

  /// The time signature the clip was drafted or edited in ("3/4"), written
  /// into its exported file; null for 4/4 — every clip copied from a
  /// project, whose files don't say.
  final String? timeSignature;

  /// The name the user gave the clip in this collection, or null for the
  /// clip's own ("Track – Clip"). The clip itself is never renamed.
  final String? title;

  /// What the clip plays (a [MidiClipRole] name), or null to suggest one.
  final String? role;

  /// The [MidiCollectionFolder] the clip is in; null (or a folder that is
  /// gone) is the collection's top level.
  final String? folderId;

  /// The name shown and exported: [title], else the clip's label.
  String get displayName {
    final t = title?.trim() ?? '';
    return t.isEmpty ? clip.label : t;
  }

  /// The role the user chose, if it is one this build knows.
  MidiClipRole? get chosenRole =>
      MidiClipRole.values.where((r) => r.name == role).firstOrNull;

  MidiCollectionItem copyWith({
    String? voice,
    bool clearVoice = false,
    String? title,
    bool clearTitle = false,
    String? role,
    bool clearRole = false,
    String? folderId,
    bool clearFolder = false,
  }) => MidiCollectionItem(
    id: id,
    clip: clip,
    addedAt: addedAt,
    sourceProjectId: sourceProjectId,
    sourceProjectName: sourceProjectName,
    sourceFileName: sourceFileName,
    bpm: bpm,
    musicalKey: musicalKey,
    voice: clearVoice ? null : (voice ?? this.voice),
    timeSignature: timeSignature,
    title: clearTitle ? null : (title ?? this.title),
    role: clearRole ? null : (role ?? this.role),
    folderId: clearFolder ? null : (folderId ?? this.folderId),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'clip': midiClipToMap(clip, bytes: base64Encode),
    'addedAt': addedAt.toIso8601String(),
    if (sourceProjectId != null) 'sourceProjectId': sourceProjectId,
    if (sourceProjectName != null) 'sourceProjectName': sourceProjectName,
    if (sourceFileName != null) 'sourceFile': sourceFileName,
    if (bpm != null) 'bpm': bpm,
    if (musicalKey != null) 'key': musicalKey,
    if (voice != null) 'voice': voice,
    if (timeSignature != null) 'timeSig': timeSignature,
    if (title != null) 'title': title,
    if (role != null) 'role': role,
    if (folderId != null) 'folder': folderId,
  };

  static MidiCollectionItem? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final clip = midiClipFromMap(json['clip']);
    final addedAt = DateTime.tryParse(json['addedAt'] as String? ?? '');
    if (id is! String || clip == null || addedAt == null) return null;
    return MidiCollectionItem(
      id: id,
      clip: clip,
      addedAt: addedAt,
      sourceProjectId: json['sourceProjectId'] as String?,
      sourceProjectName: json['sourceProjectName'] as String?,
      sourceFileName: json['sourceFile'] as String?,
      bpm: (json['bpm'] as num?)?.toDouble(),
      musicalKey: json['key'] as String?,
      voice: json['voice'] as String?,
      timeSignature: json['timeSig'] as String?,
      title: json['title'] as String?,
      role: json['role'] as String?,
      folderId: json['folder'] as String?,
    );
  }
}

/// A folder inside a [MidiCollection]; folders nest through [parentId]
/// (null: at the top level). An export writes the same tree.
class MidiCollectionFolder {
  const MidiCollectionFolder({
    required this.id,
    required this.name,
    this.parentId,
  });

  final String id;
  final String name;
  final String? parentId;

  MidiCollectionFolder copyWith({
    String? name,
    String? parentId,
    bool clearParent = false,
  }) => MidiCollectionFolder(
    id: id,
    name: name ?? this.name,
    parentId: clearParent ? null : (parentId ?? this.parentId),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (parentId != null) 'parent': parentId,
  };

  static MidiCollectionFolder? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) return null;
    return MidiCollectionFolder(
      id: id,
      name: name,
      parentId: json['parent'] as String?,
    );
  }
}

/// A named set of MIDI clips the user put together across projects —
/// "Psytrance basslines", "Ideas for Reisser".
///
/// User data: syncs to Drive and goes into local backup, merged by
/// `MidiCollectionStore.mergeIncoming` — union by id, newer `updatedAt` wins,
/// nothing deleted (the `mergeCustomThemes` rule).
class MidiCollection {
  const MidiCollection({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.deleted = false,
    this.folders = const [],
    this.naming = MidiNamingTemplate.standard,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  /// Bumped by every change; the newer copy wins a merge.
  final DateTime updatedAt;
  final List<MidiCollectionItem> items;

  /// A tombstone: the collection was deleted at [updatedAt]. Kept (with no
  /// items) so the deletion syncs like any other change and wins over an
  /// older copy on another device, instead of that copy bringing it back.
  final bool deleted;

  /// The folders clips can be sorted into, in the order they were made.
  final List<MidiCollectionFolder> folders;

  /// How exported files are named.
  final MidiNamingTemplate naming;

  MidiCollection copyWith({
    String? name,
    List<MidiCollectionItem>? items,
    bool? deleted,
    List<MidiCollectionFolder>? folders,
    MidiNamingTemplate? naming,
    required DateTime updatedAt,
  }) => MidiCollection(
    id: id,
    name: name ?? this.name,
    createdAt: createdAt,
    updatedAt: updatedAt,
    items: items ?? this.items,
    deleted: deleted ?? this.deleted,
    folders: folders ?? this.folders,
    naming: naming ?? this.naming,
  );

  MidiCollectionFolder? folderById(String? id) =>
      id == null ? null : folders.where((f) => f.id == id).firstOrNull;

  /// The folders from the top level down to [folderId] (empty for the top
  /// level or a folder that is gone). A parent loop, which no edit makes
  /// but a merge of two devices' moves could, is cut where it repeats.
  List<MidiCollectionFolder> folderPath(String? folderId) {
    final path = <MidiCollectionFolder>[];
    final seen = <String>{};
    var folder = folderById(folderId);
    while (folder != null && seen.add(folder.id)) {
      path.insert(0, folder);
      folder = folderById(folder.parentId);
    }
    return path;
  }

  /// The folders directly inside [parentId] (null: the top level). A
  /// folder whose parent is gone counts as top level, and so does one
  /// caught in a parent loop.
  List<MidiCollectionFolder> foldersIn(String? parentId) => [
    for (final f in folders)
      if (_parentOf(f) == parentId) f,
  ];

  String? _parentOf(MidiCollectionFolder f) {
    final parent = folderById(f.parentId);
    if (parent == null) return null;
    // In a loop: the path up from the parent comes back to this folder.
    if (folderPath(parent.id).any((p) => p.id == f.id)) return null;
    return parent.id;
  }

  /// The clips directly in [folderId] (null: the top level, which also
  /// holds clips whose folder is gone), in the collection's order.
  List<MidiCollectionItem> itemsIn(String? folderId) => [
    for (final i in items)
      if ((folderById(i.folderId)?.id) == folderId) i,
  ];

  /// Every folder, depth first — each followed by what is inside it — with
  /// how deep it sits (0: the top level). What a folder picker lists.
  List<({MidiCollectionFolder folder, int depth})> folderTree() {
    final out = <({MidiCollectionFolder folder, int depth})>[];
    void walk(String? parentId, int depth) {
      for (final f in foldersIn(parentId)) {
        out.add((folder: f, depth: depth));
        walk(f.id, depth + 1);
      }
    }

    walk(null, 0);
    return out;
  }

  /// [folderId] and every folder inside it, at any depth.
  Set<String> folderAndDescendants(String folderId) {
    final found = {folderId};
    var grew = true;
    while (grew) {
      grew = false;
      for (final f in folders) {
        if (f.parentId != null &&
            found.contains(f.parentId) &&
            found.add(f.id)) {
          grew = true;
        }
      }
    }
    return found;
  }

  /// Whether a clip playing the same notes is already in here — adding it
  /// again would only make a duplicate.
  bool containsClip(MidiClip clip) {
    final key = clip.contentKey;
    return items.any((i) => i.clip.contentKey == key);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'items': [for (final i in items) i.toJson()],
    if (deleted) 'deleted': true,
    if (folders.isNotEmpty) 'folders': [for (final f in folders) f.toJson()],
    if (naming != MidiNamingTemplate.standard) 'naming': naming.toJson(),
  };

  /// Null when [json] isn't a collection; unreadable items are skipped.
  static MidiCollection? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    if (id is! String ||
        name is! String ||
        createdAt == null ||
        updatedAt == null) {
      return null;
    }
    return MidiCollection(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
      items: [
        for (final raw in (json['items'] as List?) ?? const [])
          ?MidiCollectionItem.tryParse(raw),
      ],
      deleted: json['deleted'] == true,
      folders: [
        for (final raw in (json['folders'] as List?) ?? const [])
          ?MidiCollectionFolder.tryParse(raw),
      ],
      naming: MidiNamingTemplate.fromJson(json['naming']),
    );
  }
}

List<MidiCollection> midiCollectionsFromJson(Object? json) => [
  if (json is List)
    for (final raw in json) ?MidiCollection.tryParse(raw),
];
