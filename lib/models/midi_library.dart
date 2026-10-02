import '../services/midi/synth_voice.dart';
import '../utils/search_utils.dart';
import 'midi_clip.dart';
import 'music_project.dart';
import 'stored_midi_clips.dart';

/// One unique clip in the MIDI library, across every project of a profile.
class LibraryClip {
  const LibraryClip({
    required this.clip,
    required this.projectId,
    required this.projectName,
    this.bpm,
    this.musicalKey,
    this.otherProjectIds = const [],
    this.otherProjectNames = const [],
  });

  /// The clip as first found, its [MidiClip.occurrences] summed over every
  /// project that holds it.
  final MidiClip clip;

  /// The project it is listed under (where it was first found).
  final String projectId;
  final String projectName;

  /// That project's tempo, which the clip previews and exports at by default.
  final double? bpm;

  /// That project's key, written into the clip's exported `.mid` file.
  final String? musicalKey;

  /// Other projects holding the same notes — typically other versions of the
  /// same song.
  final List<String> otherProjectIds;
  final List<String> otherProjectNames;
}

/// The profile's unique MIDI clips, from each project's stored clips.
///
/// Projects are visited by name; a clip already seen in an earlier project
/// (same [MidiClip.contentKey]) is folded into that entry rather than listed
/// again — the same riff in "Song v1" and "Song v2" is one clip. Stored clips
/// whose project no longer exists, and stacks (which own no file), are left
/// out.
List<LibraryClip> buildMidiLibrary(
  Map<String, StoredMidiClips> stored,
  Map<String, MusicProject> projects,
) {
  final ids = stored.keys
      .where((id) => projects[id] != null && !projects[id]!.isVirtual)
      .toList()
    ..sort((a, b) => projects[a]!
        .displayName
        .toLowerCase()
        .compareTo(projects[b]!.displayName.toLowerCase()));

  final byKey = <String, LibraryClip>{};
  for (final id in ids) {
    final project = projects[id]!;
    for (final clip in stored[id]!.clips) {
      final key = clip.contentKey;
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = LibraryClip(
          clip: clip,
          projectId: id,
          projectName: project.displayName,
          bpm: project.bpm,
          musicalKey: _keyOf(project),
        );
        continue;
      }
      if (existing.projectId == id || existing.otherProjectIds.contains(id)) {
        continue;
      }
      byKey[key] = LibraryClip(
        clip: existing.clip.copyWith(
          occurrences: existing.clip.occurrences + clip.occurrences,
        ),
        projectId: existing.projectId,
        projectName: existing.projectName,
        bpm: existing.bpm,
        musicalKey: existing.musicalKey,
        otherProjectIds: [...existing.otherProjectIds, id],
        otherProjectNames: [...existing.otherProjectNames, project.displayName],
      );
    }
  }
  return byKey.values.toList();
}

String? _keyOf(MusicProject project) {
  final key = project.musicalKey?.trim();
  return key == null || key.isEmpty ? null : key;
}

/// The library narrowed by the search box and the instrument filter.
///
/// Search matches the clip's and track's names, the projects it is in, and
/// the names it was merged from — one entry each, so every query word has to
/// hit the same name. [voice] keeps clips whose inferred instrument is that
/// voice; null keeps all.
List<LibraryClip> filterMidiLibrary(
  List<LibraryClip> library, {
  String query = '',
  SynthVoice? voice,
}) {
  final q = query.trim();
  return [
    for (final item in library)
      if ((voice == null || inferSynthVoice(item.clip) == voice) &&
          (q.isEmpty ||
              fuzzyMatchAny([
                item.clip.name,
                item.clip.trackName,
                item.projectName,
                ...item.otherProjectNames,
                ...item.clip.otherNames,
              ], q)))
        item,
  ];
}

/// How the MIDI tab arranges its clips: under the project each came from,
/// or by tempo — the way to pick loops for a track at a given BPM (#143).
enum MidiLibraryArrangement { project, tempo }

/// [items] slowest first, those with no known tempo last. Stable: clips at
/// one tempo keep the order they had (by project, then as found).
List<T> sortByTempo<T>(List<T> items, double? Function(T) bpmOf) {
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  indexed.sort((a, b) {
    final x = bpmOf(a.$2), y = bpmOf(b.$2);
    if (x != y) {
      if (x == null) return 1;
      if (y == null) return -1;
      final c = x.compareTo(y);
      if (c != 0) return c;
    }
    return a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}
