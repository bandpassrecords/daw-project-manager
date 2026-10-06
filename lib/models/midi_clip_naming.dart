import 'dart:math' as math;

import '../services/midi/synth_voice.dart';
import '../utils/time_signature.dart';
import 'midi_clip.dart';
import 'midi_collection.dart';

/// What part a clip plays in a track — what a file name says it is, so a
/// folder of exported clips reads like a sample pack.
enum MidiClipRole { melody, bass, chords, arp, lead, pad, drums, fx, other }

/// Name words that say a clip's role, checked in this order: drums first
/// ("bass drum" is a drum), then the more specific roles.
const _roleWords = <(MidiClipRole, List<String>)>[
  (
    MidiClipRole.drums,
    [
      'drum',
      'drums',
      'kick',
      'snare',
      'hat',
      'hats',
      'hihat',
      'clap',
      'perc',
      'beat',
      'groove',
      'kit',
      'cymbal',
      'tom',
      'toms',
    ],
  ),
  (
    MidiClipRole.fx,
    ['fx', 'sfx', 'riser', 'sweep', 'impact', 'noise', 'uplifter'],
  ),
  (MidiClipRole.arp, ['arp', 'arps', 'arpeggio', 'seq', 'sequence']),
  (MidiClipRole.bass, ['bass', 'sub', '808', 'reese', 'bassline']),
  (
    MidiClipRole.chords,
    ['chord', 'chords', 'stab', 'stabs', 'keys', 'piano', 'rhodes', 'organ'],
  ),
  (MidiClipRole.pad, ['pad', 'pads', 'atmo', 'drone', 'strings', 'choir']),
  (MidiClipRole.lead, ['lead', 'leads', 'solo', 'hook', 'topline']),
  (MidiClipRole.melody, ['melody', 'mel', 'melo', 'theme', 'motif']),
];

List<String> _words(String? name) => (name ?? '')
    .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((w) => w.isNotEmpty)
    .toList();

/// The role [clip] most likely plays: what its names say, then what its
/// [voice] is, then what its notes do — several at once is chords, all low
/// is a bass, the rest a melody.
MidiClipRole suggestMidiClipRole(MidiClip clip, {SynthVoice? voice}) {
  final words = {..._words(clip.trackName), ..._words(clip.name)};
  for (final (role, hints) in _roleWords) {
    if (hints.any(words.contains)) return role;
  }
  switch (voice) {
    case SynthVoice.bass:
      return MidiClipRole.bass;
    case SynthVoice.pad || SynthVoice.strings:
      return MidiClipRole.pad;
    case SynthVoice.lead || SynthVoice.brass:
      return MidiClipRole.lead;
    case SynthVoice.pluck:
      return MidiClipRole.arp;
    case SynthVoice.keys || SynthVoice.organ:
      return MidiClipRole.chords;
    case SynthVoice.bell:
      return MidiClipRole.melody;
    case final v? when v.isDrum:
      return MidiClipRole.drums;
    default:
      break;
  }
  final notes = clip.notes;
  if (notes.isEmpty) return MidiClipRole.other;
  var together = 0;
  for (var i = 1; i < notes.length; i++) {
    if (notes[i].startTick == notes[i - 1].startTick) together++;
  }
  if (together * 3 >= notes.length) return MidiClipRole.chords;
  if (notes.every((n) => n.pitch < 48)) return MidiClipRole.bass;
  return MidiClipRole.melody;
}

/// The finest grid every note of [clip] starts on, as a file name writes
/// it — "1-4", "1-8", "1-16", "1-8T" (triplets), "1-32" — or null when the
/// notes keep to none of them (played in, unquantized) or there are none.
String? midiClipGrid(MidiClip clip) {
  if (clip.notes.isEmpty) return null;
  final ppq = clip.ppq;
  final grids = <(String, double)>[
    ('1-4', ppq.toDouble()),
    ('1-8', ppq / 2),
    ('1-16', ppq / 4),
    ('1-8T', ppq / 3),
    ('1-16T', ppq / 6),
    ('1-32', ppq / 8),
  ];
  for (final (name, step) in grids) {
    if (step < 1) continue;
    final onIt = clip.notes.every((n) {
      final r = n.startTick / step;
      return (r - r.round()).abs() < 1e-6;
    });
    if (onIt) return name;
  }
  return null;
}

/// How many bars [clip] lasts in [timeSignature]: at least one.
int midiClipBars(MidiClip clip, TimeSignature timeSignature) {
  final bar = timeSignature.barTicks(clip.ppq);
  if (bar <= 0) return 1;
  return math.max(1, (clip.lengthTicks / bar).ceil());
}

/// The pieces a file name can carry, in a template's order.
enum MidiNameField {
  name,
  role,
  bpm,
  key,
  bars,
  timeSignature,
  grid,
  instrument,
}

/// How a collection names the files it exports: whether each starts with
/// its number in its folder (so a file explorer keeps the order), which
/// pieces follow and in what order, and what goes between them.
class MidiNamingTemplate {
  const MidiNamingTemplate({
    this.numbered = true,
    this.fields = defaultFields,
    this.separator = ' - ',
  });

  static const defaultFields = [
    MidiNameField.name,
    MidiNameField.role,
    MidiNameField.bpm,
    MidiNameField.key,
    MidiNameField.bars,
    MidiNameField.timeSignature,
  ];

  /// What a collection uses until it is given its own.
  static const standard = MidiNamingTemplate();

  final bool numbered;
  final List<MidiNameField> fields;
  final String separator;

  MidiNamingTemplate copyWith({
    bool? numbered,
    List<MidiNameField>? fields,
    String? separator,
  }) => MidiNamingTemplate(
    numbered: numbered ?? this.numbered,
    fields: fields ?? this.fields,
    separator: separator ?? this.separator,
  );

  Map<String, dynamic> toJson() => {
    'numbered': numbered,
    'fields': [for (final f in fields) f.name],
    'separator': separator,
  };

  /// Fields this build doesn't know are skipped; anything unreadable is
  /// the standard template.
  static MidiNamingTemplate fromJson(Object? json) {
    if (json is! Map) return standard;
    final names = json['fields'];
    return MidiNamingTemplate(
      numbered: json['numbered'] != false,
      fields: names is List
          ? [
              for (final n in names)
                ...MidiNameField.values.where((f) => f.name == n),
            ]
          : defaultFields,
      separator: json['separator'] is String
          ? json['separator'] as String
          : ' - ',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MidiNamingTemplate &&
      other.numbered == numbered &&
      other.separator == separator &&
      other.fields.length == fields.length &&
      [
        for (var i = 0; i < fields.length; i++) other.fields[i] == fields[i],
      ].every((same) => same);

  @override
  int get hashCode => Object.hash(numbered, separator, Object.hashAll(fields));
}

/// The words a file name is built from, in the user's language.
class MidiNamingLabels {
  const MidiNamingLabels({
    required this.roleName,
    required this.instrumentName,
    required this.bars,
    required this.free,
  });

  final String Function(MidiClipRole role) roleName;
  final String Function(SynthVoice voice) instrumentName;

  /// "4 bars".
  final String Function(int count) bars;

  /// The grid of notes on none: "free".
  final String free;
}

/// Each piece of a collection item's file name, written out — null where
/// there is nothing to say (no key, a 4/4 time signature).
Map<MidiNameField, String?> midiNameParts(
  MidiCollectionItem item, {
  required MidiNamingLabels labels,
  required SynthVoice voice,
  double? bpm,
}) {
  final clip = item.clip;
  final signature =
      TimeSignature.tryParse(item.timeSignature) ?? TimeSignature.common;
  final tempo = bpm ?? item.bpm;
  final key = item.musicalKey?.trim();
  return {
    MidiNameField.name: item.displayName.trim().isEmpty
        ? null
        : item.displayName.trim(),
    MidiNameField.role: labels.roleName(
      item.chosenRole ?? suggestMidiClipRole(clip, voice: voice),
    ),
    MidiNameField.bpm: tempo == null || tempo <= 0
        ? null
        : '${_bpmText(tempo)}BPM',
    MidiNameField.key: key == null || key.isEmpty ? null : key,
    MidiNameField.bars: labels.bars(midiClipBars(clip, signature)),
    MidiNameField.timeSignature: signature == TimeSignature.common
        ? null
        : '${signature.beats}-${signature.unit}',
    MidiNameField.grid: midiClipGrid(clip) ?? labels.free,
    MidiNameField.instrument: labels.instrumentName(voice),
  };
}

String _bpmText(double bpm) {
  if (bpm == bpm.roundToDouble()) return bpm.round().toString();
  return bpm
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// The words of [name] as a file name piece can repeat them: split on
/// [separator] and the usual " - " and "_", lowercased.
Set<String> _saidIn(String name, String separator) {
  var pieces = [name];
  for (final sep in {separator, ' - ', '_'}) {
    if (sep.isEmpty) continue;
    pieces = [for (final p in pieces) ...p.split(sep)];
  }
  return {
    for (final p in pieces)
      if (p.trim().isNotEmpty) p.trim().toLowerCase(),
  };
}

/// A file name from [parts] by [template]: its number first when it has
/// one ([number], zero-padded to [width] so files sort in order), then the
/// template's pieces that have something to say, joined by its separator.
/// A piece the name already says — a clip named after the scheme ("Bass -
/// 140BPM") — is not said twice. Safe on every desktop filesystem.
String midiTemplateFileName(
  MidiNamingTemplate template,
  Map<MidiNameField, String?> parts, {
  int? number,
  int width = 2,
}) {
  final name = template.fields.contains(MidiNameField.name)
      ? parts[MidiNameField.name]?.trim()
      : null;
  final said = name == null ? const <String>{} : _saidIn(name, template.separator);
  final pieces = [
    for (final field in template.fields)
      if (parts[field] case final value? when value.trim().isNotEmpty)
        if (field == MidiNameField.name ||
            !said.contains(value.trim().toLowerCase()))
          value.trim(),
  ];
  var base = pieces.isEmpty ? 'MIDI clip' : pieces.join(template.separator);
  if (template.numbered && number != null) {
    base = '${number.toString().padLeft(width, '0')} $base';
  }
  base = safeFileNamePart(base);
  if (base.length > 150) base = base.substring(0, 150).trim();
  if (base.isEmpty) base = 'MIDI clip';
  return '$base.mid';
}

/// A name for a clip made from the naming scheme: [template]'s pieces
/// other than the name itself, joined by its separator, with no number —
/// "Bass - 140BPM - A minor - 4 bars". For a clip whose own name says
/// nothing ("MIDI 01", an imported track). Its role when the template
/// says nothing else.
String midiSchemeName(
  MidiNamingTemplate template,
  Map<MidiNameField, String?> parts,
) {
  final pieces = [
    for (final field in template.fields)
      if (field != MidiNameField.name)
        if (parts[field] case final value? when value.trim().isNotEmpty)
          value.trim(),
  ];
  if (pieces.isNotEmpty) return pieces.join(template.separator);
  return parts[MidiNameField.role]?.trim() ?? 'MIDI clip';
}

/// [names] made unique, ignoring case, by numbering the repeats: "Bass",
/// "Bass 2", "Bass 3" — what two clips proposed the same scheme name get.
List<String> uniqueClipNames(List<String> names) {
  final used = <String>{};
  return [
    for (final name in names)
      () {
        var candidate = name;
        var n = 2;
        while (!used.add(candidate.toLowerCase())) {
          candidate = '$name $n';
          n++;
        }
        return candidate;
      }(),
  ];
}

/// [name] with what Windows, macOS and Linux reject in a file or folder
/// name replaced, and trailing dots and spaces (invalid on Windows) gone.
String safeFileNamePart(String name) => name
    .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
    .trim()
    .replaceFirst(RegExp(r'[. ]+$'), '');

/// The item a clip drafted from nothing is saved as: [draft] — the clip as
/// it is now — with a name, role and folder. The first save takes them
/// from what the user chose ([name], [role], [folderId]); every save after
/// keeps those of [saved], the copy already in the collection, which the
/// user may have renamed or moved since.
MidiCollectionItem ideaItemToSave(
  MidiCollectionItem draft, {
  MidiCollectionItem? saved,
  String? name,
  MidiClipRole? role,
  String? folderId,
}) {
  if (saved != null) {
    return MidiCollectionItem(
      id: draft.id,
      clip: draft.clip.copyWith(name: saved.clip.name),
      addedAt: saved.addedAt,
      bpm: draft.bpm,
      musicalKey: draft.musicalKey,
      voice: draft.voice,
      timeSignature: draft.timeSignature,
      title: saved.title,
      role: saved.role,
      folderId: saved.folderId,
    );
  }
  final typed = name?.trim() ?? '';
  return MidiCollectionItem(
    id: draft.id,
    clip: typed.isEmpty ? draft.clip : draft.clip.copyWith(name: typed),
    addedAt: draft.addedAt,
    bpm: draft.bpm,
    musicalKey: draft.musicalKey,
    voice: draft.voice,
    timeSignature: draft.timeSignature,
    role: role?.name,
    folderId: folderId,
  );
}

/// The file name [item] exports as from [collection] by its naming
/// template — numbered as the [number]th clip of its folder.
String midiItemFileName(
  MidiCollection collection,
  MidiCollectionItem item, {
  required MidiNamingLabels labels,
  required SynthVoice voice,
  required int number,
  int? width,
  double? bpm,
}) => midiTemplateFileName(
  collection.naming,
  midiNameParts(item, labels: labels, voice: voice, bpm: bpm),
  number: number,
  width: width ?? math.max(2, number.toString().length),
);

/// One file of a collection's export: where it goes ([folders], outermost
/// first, already safe as names) and what it's called.
class PlannedMidiFile {
  const PlannedMidiFile(this.item, this.folders, this.fileName);
  final MidiCollectionItem item;
  final List<String> folders;
  final String fileName;

  /// The path inside the export, with forward slashes.
  String get relativePath => [...folders, fileName].join('/');
}

/// Where each of [collection]'s clips goes when it is exported: into its
/// folder's place in the tree, named by [fileNameOf] with its number in
/// that folder (its place in the collection's order, counting from 1) and
/// the width numbers there need. Names are made unique within a folder.
List<PlannedMidiFile> planCollectionExport(
  MidiCollection collection, {
  required String Function(MidiCollectionItem item, int number, int width)
  fileNameOf,
}) {
  final byFolder = <String?, List<MidiCollectionItem>>{};
  for (final item in collection.items) {
    final folder = collection.folderById(item.folderId)?.id;
    byFolder.putIfAbsent(folder, () => []).add(item);
  }
  final planned = <PlannedMidiFile>[];
  for (final MapEntry(key: folderId, value: items) in byFolder.entries) {
    final folders = [
      for (final f in collection.folderPath(folderId))
        safeFileNamePart(f.name).isEmpty ? '_' : safeFileNamePart(f.name),
    ];
    final width = math.max(2, items.length.toString().length);
    final used = <String>{};
    for (var i = 0; i < items.length; i++) {
      var name = fileNameOf(items[i], i + 1, width);
      final stem = name.endsWith('.mid')
          ? name.substring(0, name.length - 4)
          : name;
      var n = 2;
      while (!used.add(name.toLowerCase())) {
        name = '$stem ($n).mid';
        n++;
      }
      planned.add(PlannedMidiFile(items[i], folders, name));
    }
  }
  return planned;
}
