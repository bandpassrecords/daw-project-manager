import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../models/ignored_path.dart';
import '../models/music_project.dart';
import '../models/playlist.dart';
import '../models/plugin_capture.dart';
import '../models/profile.dart';
import '../models/part_template.dart';
import '../models/project_event.dart';
import '../models/project_part.dart';
import '../models/project_template.dart';
import '../models/release.dart';
import '../models/release_file.dart';
import '../models/scan_root.dart';
import '../models/todo_item.dart';
import '../models/todo_template.dart';
import '../repository/profile_repository.dart';
import '../repository/project_repository.dart';
import '../services/plugin_bridge/plugin_protocol.dart' show dpmPluginPreviewFolderName;
import '../utils/app_paths.dart';

class _DawSpec {
  final String extension;
  final String dawType;
  final String dawVersion;
  const _DawSpec(this.extension, this.dawType, this.dawVersion);
}

/// Generates a large, varied catalog of fake projects/releases/playlists in a
/// dedicated Hive profile, so promotional screenshots never touch real user
/// data. Re-running [generate] reuses the same profile and replaces its
/// contents rather than accumulating duplicates.
class DemoDataService {
  static const demoProfileName = 'Demo — Screenshots';

  /// Two lighter-weight sibling profiles, populated with just a handful of
  /// projects each — their only purpose is giving the Profile Manager and
  /// profile switcher something realistic to show in screenshots instead of
  /// a single-profile list (or, worse, the user's own real profile name).
  static const _secondaryDemoProfileNames = ['Demo — Solo Artist', 'Demo — Studio B'];

  /// Prefix applied to every demo-generated entry in the *global*
  /// todoTemplates/projectTemplates boxes, so [remove] can find and delete
  /// exactly those entries without touching a real user template that
  /// happens to live in the same box (those boxes aren't profile-scoped).
  static const _demoNamePrefix = 'Demo — ';

  static const _daws = [
    _DawSpec('.als', 'Ableton Live', '11'),
    _DawSpec('.bwproject', 'Bitwig Studio', '5'),
    _DawSpec('.cpr', 'Cubase', '13'),
    _DawSpec('.flp', 'FL Studio', '21'),
    _DawSpec('.logicx', 'Logic Pro', '11'),
    _DawSpec('.maschine', 'Maschine', '2'),
    _DawSpec('.mgd', 'MAGDA', '0.15'),
    _DawSpec('.npr', 'Nuendo', '13'),
    _DawSpec('.ptx', 'Pro Tools', '2024'),
    _DawSpec('.rpp', 'Reaper', '7'),
    _DawSpec('.cwp', 'Sonar', '2024'),
    _DawSpec('.song', 'Studio One', '6'),
    _DawSpec('.tracktionedit', 'Waveform', '13'),
    _DawSpec('.luna', 'LUNA', '2'),
    _DawSpec('.ardour', 'Ardour', '7'),
    _DawSpec('.band', 'GarageBand', '10'),
    _DawSpec('.xrns', 'Renoise', '3.4'),
    _DawSpec('.mmp', 'LMMS', '1.2'),
    _DawSpec('.aup3', 'Audacity', '3.4'),
    _DawSpec('.qtr', 'Qtractor', '0.9'),
    _DawSpec('.rg', 'Rosegarden', '1.8'),
    _DawSpec('.reason', 'Reason', '12'),
    _DawSpec('.dpproj', 'Digital Performer', '11'),
    _DawSpec('.sesx', 'Adobe Audition', '2024'),
    _DawSpec('.vip', 'Samplitude / Sequoia', '2024'),
    _DawSpec('.acd', 'ACID Pro', '11'),
    _DawSpec('.mx9', 'Mixcraft', '9'),
  ];

  static const _statuses = ['Idea', 'Arranging', 'Mixing', 'Mastering', 'Finished'];

  static const _trackNames = [
    'Midnight Dreams', 'Solar Flare', 'Neon Horizon', 'Velvet Storm', 'Glass City',
    'Afterglow', 'Paper Planes', 'Electric Bloom', 'Wildfire', 'Lost Signal',
    'Golden Hour', 'Static Rain', 'Northern Lights', 'Broken Mirror', 'Deep Water',
    'Chrome Heart', 'Fever Dream', 'Silver Lining', 'Ghost Town', 'Ultraviolet',
    'Slow Burn', 'Crystal Echo', 'Night Drive', 'Paradise Lost', 'Analog Sky',
    'Empty Room', 'Falling Stars', 'Copper Sun', 'Distant Shore', 'Static Bloom',
    'Winter Light', 'Reckless', 'Halcyon',
  ];

  static const _keys = [
    'C major', 'G major', 'D major', 'A major', 'E major', 'F major',
    'Bb major', 'Eb major', 'Am', 'Em', 'F#m', 'Bm', 'Dm', 'Gm', 'C#m',
  ];

  static const _notes = [
    'Deep house track with atmospheric pads. Working on the breakdown section.',
    'Upbeat tropical house track. Need to add more percussion elements.',
    'Aggressive techno track. Final mix completed.',
    'Experimental ambient piece with field recordings.',
    'Dubstep track with heavy bass drops.',
    'Relaxing downtempo track.',
    'Uplifting progressive house track.',
    'Melodic techno with a driving bassline.',
    'Chill lofi beat for late-night sessions.',
    'Drum and bass roller with a rolling sub.',
    'Cinematic trailer-style piece with big risers.',
    'Garage-influenced groove with a swung hi-hat.',
  ];

  static const _todoPool = [
    'Finish arrangement', 'Record vocals', 'Mixdown', 'Master track',
    'Add automation', 'Clean up low end', 'Sample clearance check',
    'Export stems', 'Send to collab for feedback', 'Design cover art',
    'Upload to distributor', 'Write track description', 'Check phase alignment',
    'Layer additional percussion', 'Sidechain the bass',
  ];

  // Instrument/performer pairs for the per-song parts list. Cycled through so
  // each demo project shows a plausible lineup at a different stage.
  static const _partPool = [
    ('Drums', 'Alex Rivera'),
    ('Bass', 'Sam Okafor'),
    ('Rhythm Guitar', 'Jules Martin'),
    ('Lead Vocals', 'Nina Costa'),
    ('Backing Vocals', 'Nina Costa'),
    ('Synth Pads', 'Alex Rivera'),
    ('Percussion', 'Jules Martin'),
  ];

  static const _releaseTitles = [
    'Night Drive EP', 'Neon Collection', 'Afterglow Sessions',
    'Golden Hour Vol. 1', 'Deep Water Remixes',
  ];

  // One accent color per release, used to generate distinct placeholder
  // artwork so the Releases screenshots don't all show the same swatch.
  static const _releaseArtworkColors = [
    [0xE0, 0x78, 0x56],
    [0x5B, 0x8D, 0xBE],
    [0x6F, 0xAE, 0x79],
    [0x9B, 0x6F, 0xB0],
    [0xD4, 0xA2, 0x4C],
  ];

  static const _playlistNames = ['Favorites', 'Late Night Session', 'Ready to Master'];

  static const _projectTemplateSpecs = [
    ('Demo — House Template', '.als', 'Ableton Live', 124.0, 'Am'),
    ('Demo — Ambient Template', '.logicx', 'Logic Pro', 80.0, 'C major'),
  ];

  static const _todoTemplateSpecs = [
    ('Demo — Mixing Checklist', ['Check phase alignment', 'Sidechain the bass', 'Clean up low end', 'Reference against 2 commercial tracks']),
    ('Demo — Pre-Release Checklist', ['Master track', 'Export stems', 'Design cover art', 'Write track description', 'Upload to distributor']),
  ];

  static const _partTemplateSpecs = [
    ('Demo — Band Lineup', 'Drums — Alex Rivera\nBass — Sam Okafor\nRhythm Guitar — Jules Martin\nLead Vocals — Nina Costa'),
    ('Demo — Electronic Track', 'Kick & Drums\nBassline\nSynth Pads\nLead Synth\nVocal Chops'),
  ];

  // Extensions that are actually directories ("package bundles") on disk
  // rather than a single file — mirrors the special-casing in
  // ScannerService/MixdownDetectorService for Logic Pro and LUNA.
  static const _folderBasedExtensions = {'.logicx', '.luna', '.band'};

  // Pentatonic-scale frequencies (A2-D4) used to give each preview a distinct audible pitch.
  static const _previewFrequencies = [110.0, 130.8, 146.8, 164.8, 196.0, 220.0, 261.6, 293.7];

  final _uuid = const Uuid();
  final _random = Random(42);

  /// Creates (or reuses and clears) the demo profile, fills it with a varied
  /// catalog spanning every supported DAW and phase, and returns the profile.
  ///
  /// Also (re)creates two lighter-weight sibling profiles (see
  /// [_secondaryDemoProfileNames]) so the Profile Manager has more than one
  /// profile to show, and seeds a couple of globally-scoped Project/Todo
  /// Templates — none of this touches any of the user's own data.
  ///
  /// [previewSongsPathProvider] defaults to the real [getPreviewSongsPath]
  /// and [demoFilesPathProvider] to the real [getDemoProjectsPath] (both
  /// touch `path_provider`/the OS app-data dir); tests inject providers that
  /// resolve inside their own temp directory instead.
  ///
  /// Every generated project gets a real placeholder on disk at its
  /// `filePath` (an empty file, or an empty directory for package-bundle
  /// DAWs like Logic Pro/LUNA) so the app doesn't show a "source file not
  /// found" warning for demo projects.
  Future<Profile> generate(
    ProfileRepository profileRepo, {
    Future<String> Function() previewSongsPathProvider = getPreviewSongsPath,
    Future<String> Function() demoFilesPathProvider = getDemoProjectsPath,
  }) async {
    final demoProfile = await _getOrCreateProfile(profileRepo, demoProfileName);
    final previewSongsPath = await previewSongsPathProvider();
    final demoFilesPath = await demoFilesPathProvider();

    await _populateMainProfile(
      demoProfile,
      previewSongsPath: previewSongsPath,
      demoFilesPath: demoFilesPath,
    );

    for (final name in _secondaryDemoProfileNames) {
      final profile = await _getOrCreateProfile(profileRepo, name);
      await _populateSecondaryProfile(
        profile,
        seed: _secondaryDemoProfileNames.indexOf(name),
        demoFilesPath: demoFilesPath,
      );
    }

    await _seedGlobalTemplates(demoFilesPath);

    return demoProfile;
  }

  /// Work sessions adding up to exactly [totalSeconds], so a demo project's
  /// session history agrees with its "worked" total: one an evening on
  /// separate days between [createdAt] and [updatedAt], uneven lengths in
  /// whole quarter hours, each in the phase the song had reached by then
  /// ([phases] runs from the first to the current one).
  static List<SessionRecord> demoSessions({
    required int totalSeconds,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<String> phases,
    required int seed,
  }) {
    final days = updatedAt.difference(createdAt).inDays;
    if (totalSeconds <= 0 || days < 1 || phases.isEmpty) return const [];
    final random = Random(seed);
    final count = (totalSeconds / 5400).ceil().clamp(1, min(12, days)).toInt();
    final weights = List.generate(count, (_) => 2 + random.nextInt(5));
    final weightSum = weights.reduce((a, b) => a + b);
    const quarter = 900;
    final lengths = [
      for (final w in weights) max(quarter, (totalSeconds * w / weightSum / quarter).floor() * quarter),
    ];
    // Whatever rounding left over goes to the longest, which can take it.
    final longest = lengths.indexOf(lengths.reduce(max));
    lengths[longest] += totalSeconds - lengths.reduce((a, b) => a + b);

    return [
      for (var k = 0; k < count; k++)
        () {
          final day = createdAt.add(Duration(days: k * days ~/ count));
          final start = DateTime(day.year, day.month, day.day, 17 + random.nextInt(4), random.nextInt(4) * 15);
          return SessionRecord(
            id: start.toIso8601String(),
            startedAt: start,
            endedAt: start.add(Duration(seconds: lengths[k])),
            durationSeconds: lengths[k],
            // The first in the first phase, the last in the current one.
            phase: phases[count == 1 ? phases.length - 1 : (k * (phases.length - 1) / (count - 1)).round()],
          );
        }(),
    ];
  }

  Future<Profile> _getOrCreateProfile(ProfileRepository profileRepo, String name) async {
    final existing = profileRepo.getAllProfiles().where((p) => p.name == name);
    return existing.isNotEmpty ? existing.first : await profileRepo.createProfile(name);
  }

  Future<void> _populateMainProfile(
    Profile demoProfile, {
    required String previewSongsPath,
    required String demoFilesPath,
  }) async {
    final repo = await _openRepository(demoProfile.id);

    await repo.projectsBox.clear();
    await repo.releasesBox.clear();
    await repo.playlistsBox.clear();
    await repo.eventsBox.clear();

    final now = DateTime.now();
    const projectCount = 30;
    final projects = <MusicProject>[];

    for (var i = 0; i < projectCount; i++) {
      final daw = _daws[i % _daws.length];
      final statusIndex = i % _statuses.length;
      final status = _statuses[statusIndex];
      final name = _trackNames[i % _trackNames.length];

      final daysAgoCreated = (340 - i * 11).clamp(1, 340);
      final createdAt = now.subtract(Duration(days: daysAgoCreated));
      final daysAgoUpdated = (daysAgoCreated / 3).round().clamp(0, daysAgoCreated);
      final updatedAt = now.subtract(Duration(days: daysAgoUpdated));

      final numTodos = 2 + (i % 3);
      final completedCount = statusIndex == _statuses.length - 1
          ? numTodos
          : min(numTodos, statusIndex);
      final todos = List.generate(numTodos, (k) {
        final createdOffset = (updatedAt.difference(createdAt).inHours * (k + 1) / (numTodos + 1)).round();
        return TodoItem(
          id: _uuid.v4(),
          text: _todoPool[(i + k) % _todoPool.length],
          completed: k < completedCount,
          createdAt: createdAt.add(Duration(hours: createdOffset)),
        );
      });

      // Parts progress tracks the project's phase: an Idea has nothing
      // recorded, a Finished track has every part on its final take.
      final numParts = 3 + (i % 3);
      final parts = List.generate(numParts, (k) {
        final (instrument, performer) = _partPool[(i + k) % _partPool.length];
        final PartTakeStatus status;
        if (statusIndex >= _statuses.length - 1) {
          status = PartTakeStatus.finalTake;
        } else if (k < statusIndex) {
          status = PartTakeStatus.finalTake;
        } else if (k == statusIndex) {
          status = PartTakeStatus.earlyTake;
        } else if (k == statusIndex + 1) {
          status = PartTakeStatus.recording;
        } else {
          status = PartTakeStatus.needed;
        }
        return ProjectPart(
          id: _uuid.v4(),
          name: instrument,
          performer: performer,
          status: status,
        );
      });

      DateTime? deadline;
      if (i % 5 == 0) {
        deadline = now.subtract(Duration(days: 5 + i)); // overdue
      } else if (i % 5 == 2) {
        deadline = now.add(Duration(days: 5 + i)); // upcoming
      }

      final hidden = i % 8 == 5;
      final hasPreview = i % 2 == 0;
      final projectId = _uuid.v4();

      final fileName = '$name${daw.extension}';
      final filePath = path.join(demoFilesPath, fileName);
      if (_folderBasedExtensions.contains(daw.extension)) {
        await Directory(filePath).create(recursive: true);
      } else {
        await File(filePath).create(recursive: true);
      }

      final workSeconds = (statusIndex + 1) * 3600 * (2 + i % 4);
      var project = MusicProject(
        id: projectId,
        filePath: filePath,
        fileName: fileName,
        fileSizeBytes: 3000000 + i * 250000,
        lastModifiedAt: updatedAt,
        fileExtension: daw.extension,
        createdAt: createdAt,
        updatedAt: updatedAt,
        customDisplayName: name,
        status: status,
        bpm: (70 + _random.nextInt(106)).toDouble(),
        musicalKey: _keys[i % _keys.length],
        notes: _notes[i % _notes.length],
        dawType: daw.dawType,
        dawVersion: daw.dawVersion,
        todos: todos,
        parts: parts,
        hidden: hidden,
        fileCreatedAt: createdAt,
        deadline: deadline,
        statusChangedAt: statusIndex == 0 ? null : updatedAt,
        totalWorkSeconds: workSeconds,
        sessions: demoSessions(
          totalSeconds: workSeconds,
          createdAt: createdAt,
          updatedAt: updatedAt,
          phases: _statuses.sublist(0, statusIndex + 1),
          seed: i,
        ),
      );

      if (hasPreview) {
        final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
        final previewFileName = 'demo_main_${i}_${safeName}_preview.wav';
        final previewFile = File(path.join(previewSongsPath, previewFileName));
        await previewFile.writeAsBytes(_generatePreviewWavBytes(
          frequencyHz: _previewFrequencies[i % _previewFrequencies.length],
        ));
        project = project.copyWith(
          previewSongPath: previewFile.path,
          previewSongFileName: previewFileName,
        );
      }

      // Every third project also has a take captured by the DAW plugin, in its
      // own slot — so projects 0, 6, 12… have both a preview song and a
      // capture to choose between, and the others in this third only a capture.
      if (i % 3 == 0) {
        final captureFile = File(path.join(
          previewSongsPath,
          dpmPluginPreviewFolderName,
          projectId,
          'demo_capture_$i.wav',
        ));
        await captureFile.parent.create(recursive: true);
        const captureSeconds = 4;
        await captureFile.writeAsBytes(_generatePreviewWavBytes(
          frequencyHz: _previewFrequencies[(i + 3) % _previewFrequencies.length],
          durationSeconds: captureSeconds,
        ));
        project = project.copyWith(
          latestCapture: PluginCapture(
            path: captureFile.path,
            capturedAt: updatedAt,
            durationSeconds: captureSeconds.toDouble(),
          ),
        );
      }

      await repo.projectsBox.put(projectId, project);
      projects.add(project);

      // Status-change events: walk Idea -> ... -> status, spaced across the project's lifetime.
      if (statusIndex > 0) {
        final span = updatedAt.difference(createdAt);
        for (var k = 0; k < statusIndex; k++) {
          final occurredAt = createdAt.add(span * ((k + 1) / statusIndex));
          await repo.addEvent(ProjectEvent(
            id: _uuid.v4(),
            projectId: projectId,
            eventType: ProjectEvent.statusChange,
            occurredAt: occurredAt,
            payload: jsonEncode({'from': _statuses[k], 'to': _statuses[k + 1]}),
          ));
        }
      }

      // A completed todo becomes a todoCompleted event for chart variety.
      TodoItem? firstCompleted;
      for (final t in todos) {
        if (t.completed) {
          firstCompleted = t;
          break;
        }
      }
      if (firstCompleted != null) {
        await repo.addEvent(ProjectEvent(
          id: _uuid.v4(),
          projectId: projectId,
          eventType: ProjectEvent.todoCompleted,
          occurredAt: updatedAt,
          payload: jsonEncode({'todoId': firstCompleted.id, 'todoText': firstCompleted.text}),
        ));
      }

      // A handful of metadata-edit events for chart variety.
      if (i % 3 == 0) {
        final midpoint = createdAt.add(updatedAt.difference(createdAt) ~/ 2);
        await repo.addEvent(ProjectEvent(
          id: _uuid.v4(),
          projectId: projectId,
          eventType: ProjectEvent.metadataEdit,
          occurredAt: midpoint,
          payload: jsonEncode({'fields': ['bpm', 'musicalKey']}),
        ));
      }
    }

    // Releases: group Mixing/Mastering/Finished projects, each with cover
    // artwork and a couple of attached supporting files.
    final releaseCandidates = projects.where((p) => p.status != 'Idea' && p.status != 'Arranging').toList();
    var candidateIndex = 0;
    for (var r = 0; r < _releaseTitles.length && candidateIndex < releaseCandidates.length; r++) {
      final trackIds = <String>[];
      for (var t = 0; t < 3 && candidateIndex < releaseCandidates.length; t++, candidateIndex++) {
        trackIds.add(releaseCandidates[candidateIndex].id);
      }
      if (trackIds.isEmpty) break;

      final releaseDate = r.isEven
          ? now.add(Duration(days: 20 + r * 10))
          : now.subtract(Duration(days: 20 + r * 10));

      final color = _releaseArtworkColors[r % _releaseArtworkColors.length];
      final artworkFile = File(path.join(demoFilesPath, 'release_${r}_artwork.png'));
      await artworkFile.writeAsBytes(_generateSolidColorPng(
        red: color[0], green: color[1], blue: color[2],
      ));

      final releaseFilesDir = Directory(path.join(demoFilesPath, 'release_${r}_files'));
      await releaseFilesDir.create(recursive: true);

      final masterWav = File(path.join(releaseFilesDir.path, 'Final_Master.wav'));
      await masterWav.writeAsBytes(_generatePreviewWavBytes(
        frequencyHz: _previewFrequencies[r % _previewFrequencies.length],
        durationSeconds: 5,
      ));
      final notesFile = File(path.join(releaseFilesDir.path, 'Distribution_Notes.txt'));
      await notesFile.writeAsString(
        'Distribution notes for "${_releaseTitles[r]}".\nMastered and ready for upload.',
      );

      final release = Release(
        id: _uuid.v4(),
        title: _releaseTitles[r],
        releaseDate: releaseDate,
        description: 'A curated collection of tracks for the "${_releaseTitles[r]}" release.',
        trackIds: trackIds,
        artworkImagePath: artworkFile.path,
        files: [
          ReleaseFile(
            id: _uuid.v4(),
            fileName: path.basename(masterWav.path),
            filePath: masterWav.path,
            fileType: 'audio',
            fileSizeBytes: await masterWav.length(),
            addedAt: now.subtract(const Duration(days: 2)),
          ),
          ReleaseFile(
            id: _uuid.v4(),
            fileName: path.basename(notesFile.path),
            filePath: notesFile.path,
            fileType: 'document',
            fileSizeBytes: await notesFile.length(),
            addedAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        todos: [
          TodoItem(id: _uuid.v4(), text: 'Design cover art', completed: r.isOdd, createdAt: now),
          TodoItem(id: _uuid.v4(), text: 'Master all tracks', completed: false, createdAt: now),
          TodoItem(id: _uuid.v4(), text: 'Upload to streaming platforms', completed: false, createdAt: now),
        ],
      );
      await repo.releasesBox.put(release.id, release);
    }

    // Playlists: mixed subsets spanning different DAWs/statuses.
    for (var pl = 0; pl < _playlistNames.length; pl++) {
      final playlistProjects = [
        for (var i = pl; i < projects.length; i += _playlistNames.length) projects[i].id,
      ];
      final playlist = Playlist(
        id: _uuid.v4(),
        name: _playlistNames[pl],
        projectIds: playlistProjects,
        createdAt: now.subtract(Duration(days: 10 + pl)),
        updatedAt: now,
      );
      await repo.playlistsBox.put(playlist.id, playlist);
    }
  }

  /// Populates one of the [_secondaryDemoProfileNames] with a small,
  /// self-contained set of projects — just enough for the Profile Manager
  /// and profile switcher to look like a real multi-profile setup, without
  /// duplicating the full catalog generation.
  Future<void> _populateSecondaryProfile(
    Profile profile, {
    required int seed,
    required String demoFilesPath,
  }) async {
    final repo = await _openRepository(profile.id);
    await repo.projectsBox.clear();

    final now = DateTime.now();
    const projectCount = 6;
    final offset = (seed + 1) * projectCount;

    for (var i = 0; i < projectCount; i++) {
      final index = i + offset;
      final daw = _daws[index % _daws.length];
      final statusIndex = index % _statuses.length;
      final name = _trackNames[index % _trackNames.length];
      final createdAt = now.subtract(Duration(days: 60 - i * 7));
      final projectId = _uuid.v4();

      final fileName = '$name${daw.extension}';
      final filePath = path.join(demoFilesPath, 'secondary_${seed}_$fileName');
      if (_folderBasedExtensions.contains(daw.extension)) {
        await Directory(filePath).create(recursive: true);
      } else {
        await File(filePath).create(recursive: true);
      }

      final project = MusicProject(
        id: projectId,
        filePath: filePath,
        fileName: fileName,
        fileSizeBytes: 2500000 + i * 200000,
        lastModifiedAt: createdAt,
        fileExtension: daw.extension,
        createdAt: createdAt,
        updatedAt: createdAt,
        customDisplayName: name,
        status: _statuses[statusIndex],
        bpm: (80 + _random.nextInt(80)).toDouble(),
        musicalKey: _keys[index % _keys.length],
        dawType: daw.dawType,
        dawVersion: daw.dawVersion,
        fileCreatedAt: createdAt,
      );

      await repo.projectsBox.put(projectId, project);
    }
  }

  /// Adds a couple of Project Templates and Todo Templates, tagged with
  /// [_demoNamePrefix], to the *global* (not profile-scoped) templates
  /// boxes. Additive and idempotent: re-running [generate] replaces these
  /// specific entries by id rather than touching anything else already in
  /// the box, since a real user's own templates could live there too.
  Future<void> _seedGlobalTemplates(String demoFilesPath) async {
    final todoBox = await Hive.openBox<TodoTemplate>('todoTemplates');
    final now = DateTime.now();
    for (final spec in _todoTemplateSpecs) {
      final (name, items) = spec;
      final id = 'demo-todo-template-${_slug(name)}';
      await todoBox.put(id, TodoTemplate(
        id: id,
        name: name,
        items: items,
        createdAt: now,
        updatedAt: now,
      ));
    }

    final partBox = await Hive.openBox<PartTemplate>('partTemplates');
    for (final spec in _partTemplateSpecs) {
      final (name, itemsText) = spec;
      final id = 'demo-part-template-${_slug(name)}';
      await partBox.put(id, PartTemplate(
        id: id,
        name: name,
        items: PartTemplate.parseItems(itemsText),
        createdAt: now,
        updatedAt: now,
      ));
    }

    final templatesDir = Directory(path.join(demoFilesPath, '_templates'));
    final projectBox = await Hive.openBox<ProjectTemplate>('projectTemplates');
    for (final spec in _projectTemplateSpecs) {
      final (name, ext, dawType, bpm, key) = spec;
      final safeName = _slug(name);
      final sourceFolder = Directory(path.join(templatesDir.path, safeName));
      await sourceFolder.create(recursive: true);
      final mainFileName = 'Template$ext';
      final mainFile = File(path.join(sourceFolder.path, mainFileName));
      if (!_folderBasedExtensions.contains(ext)) {
        await mainFile.create(recursive: true);
      } else {
        await Directory(mainFile.path).create(recursive: true);
      }

      final id = 'demo-project-template-$safeName';
      await projectBox.put(id, ProjectTemplate(
        id: id,
        name: name,
        sourceFolderPath: sourceFolder.path,
        mainFileRelativePath: mainFileName,
        createdAt: now,
        updatedAt: now,
        bpm: bpm,
        musicalKey: key,
        dawVersion: _daws.firstWhere((d) => d.dawType == dawType).dawVersion,
      ));
    }
  }

  static String _slug(String name) =>
      name.replaceFirst(_demoNamePrefix, '').trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  /// Deletes all generated preview audio files, release artwork/files,
  /// project-template placeholder folders, and the demo profiles' boxes,
  /// then removes those profiles (unless one of them is the user's only
  /// remaining profile, in which case it's just left empty — the app always
  /// requires at least one profile to exist). Also removes the demo-tagged
  /// entries from the global Project/Todo Template boxes without touching
  /// any real ones the user created.
  ///
  /// [demoFilesPathProvider] defaults to the real [getDemoProjectsPath];
  /// tests inject a provider that resolves inside their own temp directory.
  ///
  /// Returns `true` if any demo profile was found and removed, `false` if
  /// there was nothing to remove.
  Future<bool> remove(
    ProfileRepository profileRepo, {
    Future<String> Function() demoFilesPathProvider = getDemoProjectsPath,
  }) async {
    final allNames = {demoProfileName, ..._secondaryDemoProfileNames};
    final demoProfiles = profileRepo.getAllProfiles().where((p) => allNames.contains(p.name)).toList();
    if (demoProfiles.isEmpty) return false;

    for (final demoProfile in demoProfiles) {
      final repo = await _openRepository(demoProfile.id);

      for (final project in repo.projectsBox.values) {
        final previewPath = project.previewSongPath;
        if (previewPath != null && previewPath.isNotEmpty && !previewPath.startsWith('drive://')) {
          final file = File(previewPath);
          if (await file.exists()) {
            try {
              await file.delete();
            } catch (_) {
              // Non-critical — leftover preview files are harmless.
            }
          }
        }
      }

      // Plugin captures live in a folder per project under the preview songs.
      for (final project in repo.projectsBox.values) {
        final capture = project.latestCapture?.path;
        if (capture == null || capture.isEmpty) continue;
        try {
          final folder = File(capture).parent;
          if (path.basename(path.dirname(folder.path)) == dpmPluginPreviewFolderName &&
              await folder.exists()) {
            await folder.delete(recursive: true);
          }
        } catch (_) {
          // Non-critical — leftover capture files are harmless.
        }
      }

      // Clear (rather than close+delete from disk) — closing a box with
      // active stream watchers can deadlock on iOS with Hive CE (see the
      // same tradeoff documented in google_drive_sync_service.dart around
      // its profile-cleanup path). Empty box files left on disk are harmless.
      await repo.projectsBox.clear();
      await repo.releasesBox.clear();
      await repo.playlistsBox.clear();
      await repo.eventsBox.clear();
      await repo.rootsBox.clear();
      await repo.ignoredPathsBox.clear();
    }

    // The demo-files directory is used exclusively by this service (unlike
    // preview_songs, which real projects also write into), so it's safe to
    // delete wholesale rather than walking each project's placeholder.
    final demoFilesDir = Directory(await demoFilesPathProvider());
    if (await demoFilesDir.exists()) {
      try {
        await demoFilesDir.delete(recursive: true);
      } catch (_) {
        // Non-critical — leftover placeholder files are harmless.
      }
    }

    final todoBox = await Hive.openBox<TodoTemplate>('todoTemplates');
    for (final spec in _todoTemplateSpecs) {
      await todoBox.delete('demo-todo-template-${_slug(spec.$1)}');
    }
    final partTemplateBox = await Hive.openBox<PartTemplate>('partTemplates');
    for (final spec in _partTemplateSpecs) {
      await partTemplateBox.delete('demo-part-template-${_slug(spec.$1)}');
    }
    final projectTemplateBox = await Hive.openBox<ProjectTemplate>('projectTemplates');
    for (final spec in _projectTemplateSpecs) {
      await projectTemplateBox.delete('demo-project-template-${_slug(spec.$1)}');
    }

    // Delete secondary profiles first so, if we hit the "at least one
    // profile must exist" floor, it's the main profile that survives
    // (emptied but kept) — matching the original single-profile behavior.
    final deletionOrder = [
      ...demoProfiles.where((p) => p.name != demoProfileName),
      ...demoProfiles.where((p) => p.name == demoProfileName),
    ];
    var remaining = profileRepo.getAllProfiles().length;
    for (final demoProfile in deletionOrder) {
      if (remaining <= 1) break;
      await profileRepo.deleteProfile(demoProfile.id);
      remaining--;
    }

    return true;
  }

  /// Opens the profile-scoped boxes directly, without going through
  /// [ProjectRepository.initWithProfile] — that factory calls
  /// `ensureHiveInitialized()`, which would re-point Hive at the real
  /// app-data directory when running under a test's isolated Hive instance.
  /// By the time this service runs (from the running app or from a test that
  /// has already called `Hive.init`), Hive is already initialized correctly,
  /// so opening boxes directly is both safe and test-friendly.
  Future<ProjectRepository> _openRepository(String profileId) async {
    final projects = await Hive.openBox<MusicProject>('${profileId}_projects');
    final roots = await Hive.openBox<ScanRoot>('${profileId}_roots');
    final ignoredPaths = await Hive.openBox<IgnoredPath>('${profileId}_ignored_paths');
    final releases = await Hive.openBox<Release>('${profileId}_releases');
    final playlists = await Hive.openBox<Playlist>('${profileId}_playlists');
    final events = await Hive.openBox<ProjectEvent>('${profileId}_events');
    final appSettings = await Hive.openBox<String>('app_settings');

    return ProjectRepository(
      profileId: profileId,
      projectsBox: projects,
      rootsBox: roots,
      ignoredPathsBox: ignoredPaths,
      releasesBox: releases,
      playlistsBox: playlists,
      eventsBox: events,
      appSettingsBox: appSettings,
    );
  }

  /// Generates a minimal valid mono PCM WAV with a sine wave tone and short fade in/out.
  static Uint8List _generatePreviewWavBytes({required double frequencyHz, int durationSeconds = 3}) {
    const sampleRate = 22050;
    const bitsPerSample = 16;
    final numSamples = sampleRate * durationSeconds;
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);
    int o = 0;

    void ascii(String s) { for (final c in s.codeUnits) { buffer.setUint8(o++, c); } }
    void u16(int v) { buffer.setUint16(o, v, Endian.little); o += 2; }
    void u32(int v) { buffer.setUint32(o, v, Endian.little); o += 4; }

    ascii('RIFF'); u32(36 + dataSize); ascii('WAVE');
    ascii('fmt '); u32(16); u16(1); u16(1); u32(sampleRate); u32(sampleRate * 2); u16(2); u16(bitsPerSample);
    ascii('data'); u32(dataSize);

    const fadeLen = 2000;
    for (int i = 0; i < numSamples; i++) {
      final fade = (i < fadeLen)
          ? i / fadeLen
          : (i > numSamples - fadeLen)
              ? (numSamples - i) / fadeLen
              : 1.0;
      final sample = (sin(2 * pi * frequencyHz * i / sampleRate) * 12000 * fade)
          .round()
          .clamp(-32768, 32767);
      buffer.setInt16(o, sample, Endian.little);
      o += 2;
    }

    return buffer.buffer.asUint8List();
  }

  /// Generates a minimal valid solid-color PNG (8-bit RGB, no interlacing)
  /// entirely by hand — no image/codec package needed, just the PNG chunk
  /// format plus `dart:io`'s ZLibEncoder for the (trivially compressible,
  /// since every pixel is identical) IDAT payload. Used as placeholder
  /// release artwork so Release screenshots show a real cover image instead
  /// of a broken-image icon.
  static Uint8List _generateSolidColorPng({
    required int red,
    required int green,
    required int blue,
    int size = 512,
  }) {
    final raw = BytesBuilder();
    for (var y = 0; y < size; y++) {
      raw.addByte(0); // filter type: none
      for (var x = 0; x < size; x++) {
        raw.addByte(red);
        raw.addByte(green);
        raw.addByte(blue);
      }
    }
    final idatData = ZLibEncoder().convert(raw.toBytes());

    final png = BytesBuilder();
    png.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]); // PNG signature

    void writeChunk(String type, List<int> data) {
      final typeBytes = ascii.encode(type);
      final lengthBytes = ByteData(4)..setUint32(0, data.length, Endian.big);
      final crc = _crc32([...typeBytes, ...data]);
      final crcBytes = ByteData(4)..setUint32(0, crc, Endian.big);
      png.add(lengthBytes.buffer.asUint8List());
      png.add(typeBytes);
      png.add(data);
      png.add(crcBytes.buffer.asUint8List());
    }

    final ihdr = ByteData(13)
      ..setUint32(0, size, Endian.big) // width
      ..setUint32(4, size, Endian.big) // height
      ..setUint8(8, 8) // bit depth
      ..setUint8(9, 2) // color type: truecolor (RGB)
      ..setUint8(10, 0) // compression method
      ..setUint8(11, 0) // filter method
      ..setUint8(12, 0); // interlace method
    writeChunk('IHDR', ihdr.buffer.asUint8List());
    writeChunk('IDAT', idatData);
    writeChunk('IEND', const []);

    return png.toBytes();
  }

  static int _crc32(List<int> data) {
    const poly = 0xEDB88320;
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1 != 0) ? (crc >> 1) ^ poly : crc >> 1;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}
