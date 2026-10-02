/// What is *inside* a DAW project: how many tracks of each kind it has and
/// which plug-ins it loads, read out of the project file by the extractors in
/// `lib/services/daw_parsers/`.
///
/// Stored inside `MusicProject` as a plain `Map` (see [toMap]/[fromMap]), the
/// same way `ProjectMarker` is, so it needs no Hive type id of its own.
///
/// A null `ProjectStats` on a project means "never extracted" (a lightweight
/// scan, or a DAW we can't read) — not "an empty project". An extractor that
/// actually read the file always returns a value, even when every count is 0.
class ProjectStats {
  const ProjectStats({
    this.audioTracks = 0,
    this.midiTracks = 0,
    this.instrumentTracks = 0,
    this.samplerTracks = 0,
    this.busTracks = 0,
    this.folderTracks = 0,
    this.plugins = const [],
    this.midiClipCount,
  });

  final int audioTracks;

  /// Plain MIDI tracks: they send notes to an external or separately-routed
  /// instrument rather than hosting one.
  final int midiTracks;

  /// Tracks that host their own instrument (Cubase/Studio One instrument
  /// tracks, Ableton MIDI tracks, REAPER tracks with a VSTi, FL generators).
  final int instrumentTracks;

  /// Cubase sampler tracks and FL Studio sampler channels.
  final int samplerTracks;

  /// Group, FX, return and bus channels — tracks that mix other tracks rather
  /// than holding material of their own.
  final int busTracks;

  final int folderTracks;

  /// Distinct plug-in names as the DAW shows them, sorted case-insensitively.
  /// Built-in channel-strip internals (Cubase's panner, input filter…) are
  /// left out by the extractors; stock effects the user inserted are kept.
  final List<String> plugins;

  /// Number of distinct MIDI clips in the project, or null when the
  /// extractor for this DAW doesn't read clips.
  final int? midiClipCount;

  /// Tracks that hold material: audio, MIDI, instrument and sampler.
  int get contentTracks =>
      audioTracks + midiTracks + instrumentTracks + samplerTracks;

  int get totalTracks => contentTracks + busTracks + folderTracks;

  bool get isEmpty =>
      totalTracks == 0 && plugins.isEmpty && (midiClipCount ?? 0) == 0;

  Map<String, dynamic> toMap() => {
        'audio': audioTracks,
        'midi': midiTracks,
        'instrument': instrumentTracks,
        'sampler': samplerTracks,
        'bus': busTracks,
        'folder': folderTracks,
        'plugins': plugins,
        if (midiClipCount != null) 'midiClips': midiClipCount,
      };

  /// Lenient on purpose: this runs inside Hive's adapter and on Drive/backup
  /// payloads, so a malformed field costs that field, never the project.
  factory ProjectStats.fromMap(Map map) {
    int count(String key) {
      final v = map[key];
      return v is num && v >= 0 ? v.toInt() : 0;
    }

    final rawPlugins = map['plugins'];
    final clips = map['midiClips'];
    return ProjectStats(
      audioTracks: count('audio'),
      midiTracks: count('midi'),
      instrumentTracks: count('instrument'),
      samplerTracks: count('sampler'),
      busTracks: count('bus'),
      folderTracks: count('folder'),
      plugins: rawPlugins is List
          ? List<String>.unmodifiable(rawPlugins.whereType<String>())
          : const [],
      midiClipCount: clips is num ? clips.toInt() : null,
    );
  }

  /// Reads a stored value that may be absent, null or not a map at all.
  static ProjectStats? tryFromMap(Object? value) =>
      value is Map ? ProjectStats.fromMap(value) : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectStats &&
          audioTracks == other.audioTracks &&
          midiTracks == other.midiTracks &&
          instrumentTracks == other.instrumentTracks &&
          samplerTracks == other.samplerTracks &&
          busTracks == other.busTracks &&
          folderTracks == other.folderTracks &&
          midiClipCount == other.midiClipCount &&
          _listEquals(plugins, other.plugins);

  @override
  int get hashCode => Object.hash(audioTracks, midiTracks, instrumentTracks,
      samplerTracks, busTracks, folderTracks, midiClipCount,
      Object.hashAll(plugins));

  @override
  String toString() => 'ProjectStats(audio: $audioTracks, midi: $midiTracks, '
      'instrument: $instrumentTracks, sampler: $samplerTracks, '
      'bus: $busTracks, folder: $folderTracks, plugins: ${plugins.length}, '
      'midiClips: $midiClipCount)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Turns raw plug-in names gathered from a project into [ProjectStats.plugins]:
/// trims, drops blanks and the architecture suffixes plug-ins carry in their
/// VST2 names ("Serum_x64", "OTT (x64)"), dedupes case-insensitively and sorts.
///
/// Deliberately doesn't try to merge "FabFilter Pro-Q 3" into "Pro-Q 3": a
/// suffix rule general enough for that would also merge "Tube Compressor"
/// into "Compressor".
List<String> normalizePluginNames(Iterable<String> raw) {
  final byKey = <String, String>{};
  for (final name in raw) {
    final cleaned = cleanPluginName(name);
    if (cleaned.isEmpty) continue;
    byKey.putIfAbsent(cleaned.toLowerCase(), () => cleaned);
  }
  final result = byKey.values.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return List.unmodifiable(result);
}

final _archSuffix = RegExp(r'(?:[ _\-]?\(?x(?:64|86)\)?)$', caseSensitive: false);

String cleanPluginName(String name) =>
    name.trim().replaceFirst(_archSuffix, '').trim();
