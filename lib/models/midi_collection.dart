import 'dart:convert';

import 'midi_clip.dart';
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
    this.bpm,
    this.musicalKey,
    this.voice,
  });

  final String id;
  final MidiClip clip;
  final DateTime addedAt;

  /// The project the clip was copied from; it may no longer exist.
  final String? sourceProjectId;

  /// That project's name when the clip was copied, so the collection can
  /// still say where it came from after the project is gone.
  final String? sourceProjectName;

  /// The source project's tempo at copy time — what the clip previews and
  /// exports at unless the user picks another.
  final double? bpm;

  /// The source project's key at copy time ("A minor", "F#m"…), written
  /// into the clip's exported `.mid` file and its name.
  final String? musicalKey;

  /// The preview instrument chosen for this clip (a `SynthVoice` name), or
  /// null to infer one from the clip's names.
  final String? voice;

  MidiCollectionItem copyWith({String? voice, bool clearVoice = false}) =>
      MidiCollectionItem(
        id: id,
        clip: clip,
        addedAt: addedAt,
        sourceProjectId: sourceProjectId,
        sourceProjectName: sourceProjectName,
        bpm: bpm,
        musicalKey: musicalKey,
        voice: clearVoice ? null : (voice ?? this.voice),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clip': midiClipToMap(clip, bytes: base64Encode),
        'addedAt': addedAt.toIso8601String(),
        if (sourceProjectId != null) 'sourceProjectId': sourceProjectId,
        if (sourceProjectName != null) 'sourceProjectName': sourceProjectName,
        if (bpm != null) 'bpm': bpm,
        if (musicalKey != null) 'key': musicalKey,
        if (voice != null) 'voice': voice,
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
      bpm: (json['bpm'] as num?)?.toDouble(),
      musicalKey: json['key'] as String?,
      voice: json['voice'] as String?,
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

  MidiCollection copyWith({
    String? name,
    List<MidiCollectionItem>? items,
    bool? deleted,
    required DateTime updatedAt,
  }) =>
      MidiCollection(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        updatedAt: updatedAt,
        items: items ?? this.items,
        deleted: deleted ?? this.deleted,
      );

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
      };

  /// Null when [json] isn't a collection; unreadable items are skipped.
  static MidiCollection? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    if (id is! String || name is! String || createdAt == null || updatedAt == null) {
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
    );
  }
}

List<MidiCollection> midiCollectionsFromJson(Object? json) => [
      if (json is List)
        for (final raw in json) ?MidiCollection.tryParse(raw),
    ];
