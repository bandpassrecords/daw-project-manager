import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import '../utils/name_date_parser.dart';
import 'project_attachment.dart';
import 'project_marker.dart';
import 'project_part.dart';
import 'todo_item.dart';

/// Converts a musical key (e.g. `'C#m'`, `'G#/Ab Major'`) to Camelot Wheel
/// notation. Returns null if [musicalKey] is null, empty, or not recognized.
/// Shared by [MusicProject.camelotCode] and anywhere else (e.g. project
/// templates) that wants the same badge without a `MusicProject` instance.
String? camelotCodeForKey(String? musicalKey) {
  if (musicalKey == null || musicalKey.isEmpty) return null;

  final key = musicalKey.toLowerCase().trim();

  // Map of musical keys to Camelot codes
  final Map<String, String> camelotMap = {
    // Major keys (B side)
    'c major': '8B', 'c': '8B', 'cmaj': '8B',
    'g major': '9B', 'g': '9B', 'gmaj': '9B',
    'd major': '10B', 'd': '10B', 'dmaj': '10B',
    'a major': '11B', 'a': '11B', 'amaj': '11B',
    'e major': '12B', 'e': '12B', 'emaj': '12B',
    'b major': '1B', 'b': '1B', 'bmaj': '1B',
    'f# major': '2B', 'f#': '2B', 'f#maj': '2B', 'gb major': '2B', 'gb': '2B',
    'c# major': '3B', 'c#': '3B', 'c#maj': '3B', 'db major': '3B', 'db': '3B',
    'ab major': '4B', 'ab': '4B', 'abmaj': '4B', 'g# major': '4B', 'g#': '4B',
    'eb major': '5B', 'eb': '5B', 'ebmaj': '5B', 'd# major': '5B', 'd#': '5B',
    'bb major': '6B', 'bb': '6B', 'bbmaj': '6B', 'a# major': '6B', 'a#': '6B',
    'f major': '7B', 'f': '7B', 'fmaj': '7B',

    // Minor keys (A side)
    'a minor': '8A', 'am': '8A', 'amin': '8A',
    'e minor': '9A', 'em': '9A', 'emin': '9A',
    'b minor': '10A', 'bm': '10A', 'bmin': '10A',
    'f# minor': '11A', 'f#m': '11A', 'f#min': '11A', 'gb minor': '11A', 'gbm': '11A',
    'c# minor': '12A', 'c#m': '12A', 'c#min': '12A', 'db minor': '12A', 'dbm': '12A',
    'g# minor': '1A', 'g#m': '1A', 'g#min': '1A', 'ab minor': '1A', 'abm': '1A',
    'd# minor': '2A', 'd#m': '2A', 'd#min': '2A', 'eb minor': '2A', 'ebm': '2A',
    'a# minor': '3A', 'a#m': '3A', 'a#min': '3A', 'bb minor': '3A', 'bbm': '3A',
    'f minor': '4A', 'fm': '4A', 'fmin': '4A',
    'c minor': '5A', 'cm': '5A', 'cmin': '5A',
    'g minor': '6A', 'gm': '6A', 'gmin': '6A',
    'd minor': '7A', 'dm': '7A', 'dmin': '7A',
  };

  // Try direct mapping first
  String? result = camelotMap[key];
  if (result != null) return result;

  // Handle enharmonic notation (e.g., "G#/Ab Major" or "C#/Db Minor")
  if (key.contains('/')) {
    // Split by space to separate note from scale
    // "g#/ab major" -> ["g#/ab", "major"]
    final parts = key.split(' ');
    if (parts.isEmpty) return null;

    // Get the enharmonic notes part (before the space)
    final notePart = parts[0]; // "g#/ab"
    // Get the scale/mode part (after the space, if it exists)
    final scalePart = parts.length > 1 ? ' ${parts.sublist(1).join(' ')}' : '';

    // Split enharmonic notes
    // "g#/ab" -> ["g#", "ab"]
    final enharmonicNotes = notePart.split('/');

    // Try first enharmonic variant (e.g., "g# major")
    if (enharmonicNotes.isNotEmpty) {
      result = camelotMap[enharmonicNotes[0] + scalePart];
      if (result != null) return result;
    }

    // Try second enharmonic variant (e.g., "ab major")
    if (enharmonicNotes.length > 1) {
      result = camelotMap[enharmonicNotes[1] + scalePart];
      if (result != null) return result;
    }
  }

  return null;
}

/// A single work session on a project.
class SessionRecord {
  /// Unique ID for this session — ISO8601 string of startedAt (millisecond precision).
  /// Existing records without an 'id' field fall back to startedAt string on deserialization.
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  /// The project phase (status) that was active when this session was recorded.
  final String? phase;

  const SessionRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    this.phase,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        if (phase != null) 'phase': phase,
      };

  factory SessionRecord.fromMap(Map map) {
    final startedAt = DateTime.parse(map['startedAt'] as String);
    return SessionRecord(
      id: map['id'] as String? ?? startedAt.toIso8601String(),
      startedAt: startedAt,
      endedAt: DateTime.parse(map['endedAt'] as String),
      durationSeconds: map['durationSeconds'] as int,
      phase: map['phase'] as String?,
    );
  }
}

@HiveType(typeId: 1)
class MusicProject {
  @HiveField(0)
  final String id; // UUID primary key

  @HiveField(1)
  final String filePath; // absolute path

  @HiveField(2)
  final String fileName; // derived from path at scan time

  @HiveField(3)
  final int fileSizeBytes;

  @HiveField(4)
  final DateTime lastModifiedAt;

  @HiveField(5)
  final String? customDisplayName;

  @HiveField(6)
  final String? thumbnailPath;

  @HiveField(7)
  final String status; // Default: Idea (was 'Draft' in older versions)

  @HiveField(8)
  final String fileExtension; // e.g., .als, .cpr, .flp, .logicx

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  // Optional musical metadata
  @HiveField(11)
  final double? bpm; // Beats per minute, user editable

  @HiveField(12)
  final String? musicalKey; // e.g., C#m, F major, user editable

  // NOVO CAMPO
  @HiveField(13)
  final String? notes; // Notes about the project, user editable

  @HiveField(14)
  final String? dawType; // DAW type: Ableton, Cubase, FL Studio, Logic Pro, etc.

  @HiveField(15)
  final String? dawVersion; // DAW version (major version number)

  @HiveField(16)
  final List<TodoItem> todos; // TODO list for the track

  @HiveField(17)
  final bool hidden; // Whether the project is hidden from the list

  @HiveField(18)
  final String? previewSongPath; // Path to preview audio file (local path or "drive://fileId" as fallback if download failed)

  @HiveField(19)
  final DateTime? fileCreatedAt; // Actual file creation date from filesystem (never changes once set)

  @HiveField(20)
  final DateTime? statusChangedAt; // When the status was last changed (for tracking completion time)

  @HiveField(21)
  final String? previewSongFileName; // Original filename of the preview song (for display purposes)

  @HiveField(22)
  final String? uploadedPreviewSongHash; // MD5 hash of the preview song file that was successfully uploaded to Drive (for change detection)

  @HiveField(23)
  final DateTime? deadline; // Project deadline date

  @HiveField(24)
  final String? previewSongAutoPath; // Auto-detected mixdown path (not manually set by user)

  @HiveField(25)
  final String? parentProjectId; // Parent project ID when using shallow scan with depth ≥ 2

  @HiveField(26)
  final int totalWorkSeconds; // Cumulative seconds; derived from sessions sum

  @HiveField(27)
  final List<SessionRecord> sessions; // Ordered list of work sessions

  @HiveField(28)
  final bool metadataScanned; // True once a full metadata (deep) scan has been run

  @HiveField(29)
  final String? ignoredNewerSongPath; // Path offered as "newer" that the user explicitly rejected

  @HiveField(30)
  final String? projectNotes; // Read-only notes extracted from the DAW project file itself (e.g. Reaper's Title/Author/Notes tab)

  @HiveField(31)
  final String? sourceTemplateId; // ProjectTemplate.id this project was created from, if any (dangling if the template was later deleted)

  @HiveField(32)
  final List<ProjectPart> parts; // Instruments/roles the song needs, who plays them and how far along each take is

  // Version stacking (#94).

  @HiveField(33)
  /// True when this row is a *stack* rather than a scanned file: a virtual
  /// project that owns the shared metadata for several version files and has
  /// no file of its own on disk.
  ///
  /// Virtual projects synthesize [filePath]/[fileName] from the folder they
  /// represent, so anything that treats a non-resolving path as "the file went
  /// away" must exclude them — see `isMissingFileCandidate`.
  final bool isVirtual;

  @HiveField(34)
  /// Ids of the real projects this stack contains, in display order. Empty for
  /// real projects.
  final List<String> memberProjectIds;

  @HiveField(35)
  /// Member nominated to launch when the user hits "Launch in DAW" on the
  /// stack itself. Null means ask which version to open.
  final String? defaultLaunchMemberId;

  @HiveField(36)
  /// For a real project, the id of the stack it belongs to. Null when it
  /// stands alone.
  ///
  /// Denormalized against [memberProjectIds] on purpose: the projects grid has
  /// to decide "is this row nested under a stack?" for every row on every
  /// rebuild, and walking every virtual project's member list to answer that
  /// is quadratic in library size.
  final String? stackId;

  @HiveField(37)
  final List<ProjectMarker> markers; // Timeline markers/regions read from the DAW project file (Reaper only so far)

  @HiveField(38)
  /// Files and links the user has attached to this song (#112) — the reference
  /// track, the stem-delivery link, the lyric sheet, the contract.
  ///
  /// References only, never copies: see [ProjectAttachment].
  final List<ProjectAttachment> attachments;

  const MusicProject({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.lastModifiedAt,
    required this.fileExtension,
    required this.createdAt,
    required this.updatedAt,
    this.customDisplayName,
    this.thumbnailPath,
    this.status = 'Idea',
    this.bpm,
    this.musicalKey,
    this.notes, // NOVO CAMPO NO CONSTRUTOR
    this.dawType,
    this.dawVersion,
    this.todos = const [],
    this.hidden = false,
    this.previewSongPath,
    this.fileCreatedAt,
    this.statusChangedAt,
    this.previewSongFileName,
    this.uploadedPreviewSongHash,
    this.deadline,
    this.previewSongAutoPath,
    this.parentProjectId,
    this.totalWorkSeconds = 0,
    this.sessions = const [],
    this.metadataScanned = false,
    this.ignoredNewerSongPath,
    this.projectNotes,
    this.sourceTemplateId,
    this.parts = const [],
    this.isVirtual = false,
    this.memberProjectIds = const [],
    this.defaultLaunchMemberId,
    this.stackId,
    this.markers = const [],
    this.attachments = const [],
  });

  /// Number of version files this stack holds. 0 for a real project.
  int get versionCount => isVirtual ? memberProjectIds.length : 0;

  /// True when this project is a version inside a stack.
  bool get isStackMember => stackId != null;

  /// Whether the user has put anything into this project that stacking could
  /// hide behind another version's copy.
  ///
  /// Only fields a person types or curates count. Scanned facts (DAW type,
  /// version, file dates, `projectNotes` read out of the DAW file) are
  /// excluded: every version of a project has those, they are identical across
  /// versions, and counting them would make every stack look like a
  /// metadata conflict.
  ///
  /// Drives whether stacking has to *ask* which version's details the song
  /// should inherit — with at most one such version there is nothing to
  /// choose between.
  bool get hasUserMetadata =>
      bpm != null ||
      (musicalKey?.trim().isNotEmpty ?? false) ||
      (notes?.trim().isNotEmpty ?? false) ||
      (customDisplayName?.trim().isNotEmpty ?? false) ||
      deadline != null ||
      todos.isNotEmpty ||
      parts.isNotEmpty ||
      attachments.isNotEmpty ||
      totalWorkSeconds > 0;

  /// Whether a non-resolving [filePath] on this project means "the file was
  /// deleted or moved".
  ///
  /// False for stacks: their path is synthesized from the folder they
  /// represent and may never resolve to a file. Without this, "Delete Missing"
  /// would offer to delete the one row holding a stack's metadata — deleting
  /// the shared notes, todos and accumulated work time for every version in it.
  bool get isMissingFileCandidate => !isVirtual;

  /// Whether [displayName] hides date stamps DAWs bake into file names (see
  /// `lib/utils/name_date_parser.dart`). Off by default; mirrored here from
  /// `nameDateStrippingProvider` because [displayName] is read from roughly a
  /// hundred call sites — grid cells, mobile list, search, text export,
  /// playlists, releases — and none of them have a `Ref` to consult.
  ///
  /// The provider is the single writer; tests set it directly and must reset
  /// it in `tearDown`.
  static bool stripDatesFromNames = false;

  /// A user-set [customDisplayName] is never date-stripped: the user typed
  /// that name themselves, so any date in it is there on purpose.
  String get displayName =>
      (customDisplayName != null && customDisplayName!.trim().isNotEmpty)
      ? customDisplayName!.trim()
      : _maybeStripDate(p.basenameWithoutExtension(fileName));

  static String _maybeStripDate(String name) =>
      stripDatesFromNames ? stripNameDate(name) : name;

  static final _uuidPreviewRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}_preview\.',
    caseSensitive: false,
  );

  static String _sanitizeForFileName(String name) =>
      name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();

  /// Best filename to use when sharing or exporting the preview song.
  /// Prefers the stored original filename; falls back to the sanitized project
  /// display name + extension when the stored name is absent or UUID-based.
  /// Returns null when no preview path is available or it is a Drive reference.
  ///
  /// Date stamps are stripped here regardless of [stripDatesFromNames]: that
  /// flag is about what this app shows on screen, whereas this name is what
  /// the recipient sees in WhatsApp, and a bounce dated eight months ago
  /// reads as a stale file to them no matter how it's displayed locally.
  String? get previewShareFileName {
    final effectivePath = previewSongPath;
    if (effectivePath == null || effectivePath.isEmpty || effectivePath.startsWith('drive://')) return null;
    final stored = previewSongFileName;
    if (stored != null && stored.isNotEmpty && !_uuidPreviewRe.hasMatch(stored)) {
      return stripNameDateKeepingExtension(stored);
    }
    final ext = p.extension(effectivePath);
    // displayName may already be stripped; stripNameDate is idempotent, and
    // running it here covers the flag-off case.
    return '${stripNameDate(_sanitizeForFileName(displayName))}$ext';
  }

  /// Returns the project age based on file creation date
  /// Falls back to lastModifiedAt if fileCreatedAt is not available
  Duration get projectAge {
    final startDate = fileCreatedAt ?? lastModifiedAt;
    return DateTime.now().difference(startDate);
  }

  /// Returns a human-readable project age string
  String get projectAgeFormatted {
    final age = projectAge;
    final years = age.inDays ~/ 365;
    final months = (age.inDays % 365) ~/ 30;
    final days = age.inDays % 30;
    
    if (years > 0) {
      if (months > 0) {
        return '$years year${years > 1 ? 's' : ''}, $months month${months > 1 ? 's' : ''}';
      }
      return '$years year${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      if (days > 0) {
        return '$months month${months > 1 ? 's' : ''}, $days day${days > 1 ? 's' : ''}';
      }
      return '$months month${months > 1 ? 's' : ''}';
    } else if (days > 0) {
      return '$days day${days > 1 ? 's' : ''}';
    } else if (age.inHours > 0) {
      return '${age.inHours} hour${age.inHours > 1 ? 's' : ''}';
    } else {
      return 'Just now';
    }
  }

  /// Returns the number of days remaining until the deadline
  /// Returns null if no deadline is set
  /// Positive: days remaining, Negative: days overdue, Zero: due today
  int? get daysUntilDeadline {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return deadlineDay.difference(today).inDays;
  }

  /// Converts musical key to Camelot Wheel notation
  /// Returns null if musicalKey is null or not recognized
  /// Handles enharmonic notations like "G#/Ab Major"
  String? get camelotCode => camelotCodeForKey(musicalKey);

  /// Returns compatible Camelot codes for harmonic mixing
  /// Returns null if musicalKey is null or not recognized
  List<String>? get compatibleCamelotCodes {
    final current = camelotCode;
    if (current == null) return null;
    
    // Extract number and letter from Camelot code (e.g., "8B" -> 8, "B")
    final number = int.tryParse(current.substring(0, current.length - 1));
    final letter = current[current.length - 1];
    
    if (number == null) return null;
    
    // Calculate compatible codes:
    // 1. Same number (relative major/minor)
    // 2. +1 or -1 (adjacent on wheel)
    // 3. +7 or -7 (energy boost/drop)
    final compatible = <String>[];
    
    // Same number, opposite letter (relative major/minor)
    compatible.add('$number${letter == 'A' ? 'B' : 'A'}');
    
    // Adjacent codes (+1, -1)
    final next = number == 12 ? 1 : number + 1;
    final prev = number == 1 ? 12 : number - 1;
    compatible.add('$next$letter');
    compatible.add('$prev$letter');
    
    // Energy boost/drop (+7, -7)
    final boost = number + 7 > 12 ? number + 7 - 12 : number + 7;
    final drop = number - 7 < 1 ? number - 7 + 12 : number - 7;
    compatible.add('$boost$letter');
    compatible.add('$drop$letter');
    
    return compatible;
  }

  /// Returns a human-readable deadline status string
  String? get deadlineStatus {
    final days = daysUntilDeadline;
    if (days == null) return null;

    if (days < 0) {
      final overdueDays = days.abs();
      if (overdueDays == 1) return '1 day overdue';
      return '$overdueDays days overdue';
    } else if (days == 0) {
      return 'Due today';
    } else if (days == 1) {
      return '1 day left';
    } else if (days <= 7) {
      return '$days days left';
    } else if (days <= 30) {
      final weeks = days ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''} left';
    } else {
      final months = days ~/ 30;
      if (months == 1) return '1 month left';
      return '$months months left';
    }
  }

  /// Returns the time it took to complete the project (from creation to finished status).
  /// [finishedPhase] is the phase name that counts as "done" (defaults to 'Finished').
  Duration? timeToCompletion([Set<String>? finishedPhases]) {
    final phases = finishedPhases ?? {'Finished'};
    if (!phases.contains(status) || statusChangedAt == null) {
      return null;
    }
    final startDate = fileCreatedAt ?? createdAt;
    return statusChangedAt!.difference(startDate);
  }

  /// Returns a human-readable time to completion string
  String? timeToCompletionFormatted([Set<String>? finishedPhases]) {
    final duration = timeToCompletion(finishedPhases);
    if (duration == null) return null;
    
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = duration.inDays % 30;
    
    if (years > 0) {
      if (months > 0) {
        return '$years year${years > 1 ? 's' : ''}, $months month${months > 1 ? 's' : ''}';
      }
      return '$years year${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      if (days > 0) {
        return '$months month${months > 1 ? 's' : ''}, $days day${days > 1 ? 's' : ''}';
      }
      return '$months month${months > 1 ? 's' : ''}';
    } else if (days > 0) {
      return '$days day${days > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return 'Less than an hour';
    }
  }

  MusicProject copyWith({
    String? id,
    String? filePath,
    String? fileName,
    int? fileSizeBytes,
    DateTime? lastModifiedAt,
    String? customDisplayName,
    bool clearCustomDisplayName = false,
    String? thumbnailPath,
    String? status,
    String? fileExtension,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? bpm,
    bool clearBpm = false,
    String? musicalKey,
    bool clearMusicalKey = false,
    String? notes,
    bool clearNotes = false,
    String? dawType,
    bool clearDawType = false,
    String? dawVersion,
    bool clearDawVersion = false,
    List<TodoItem>? todos,
    bool? hidden,
    String? previewSongPath,
    bool clearPreviewSongPath = false,
    DateTime? fileCreatedAt,
    DateTime? statusChangedAt,
    String? previewSongFileName,
    bool clearPreviewSongFileName = false,
    String? uploadedPreviewSongHash,
    bool clearUploadedPreviewSongHash = false,
    DateTime? deadline,
    bool clearDeadline = false,
    String? previewSongAutoPath,
    bool clearPreviewSongAutoPath = false,
    String? parentProjectId,
    bool clearParentProjectId = false,
    int? totalWorkSeconds,
    List<SessionRecord>? sessions,
    bool? metadataScanned,
    String? ignoredNewerSongPath,
    bool clearIgnoredNewerSongPath = false,
    String? projectNotes,
    String? sourceTemplateId,
    bool clearSourceTemplateId = false,
    List<ProjectPart>? parts,
    bool? isVirtual,
    List<String>? memberProjectIds,
    String? defaultLaunchMemberId,
    bool clearDefaultLaunchMemberId = false,
    String? stackId,
    bool clearStackId = false,
    List<ProjectMarker>? markers,
    List<ProjectAttachment>? attachments,
  }) {
    return MusicProject(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      customDisplayName: clearCustomDisplayName ? null : (customDisplayName ?? this.customDisplayName),
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      status: status ?? this.status,
      fileExtension: fileExtension ?? this.fileExtension,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bpm: clearBpm ? null : (bpm ?? this.bpm),
      musicalKey: clearMusicalKey ? null : (musicalKey ?? this.musicalKey),
      notes: clearNotes ? null : (notes ?? this.notes),
      dawType: clearDawType ? null : (dawType ?? this.dawType),
      dawVersion: clearDawVersion ? null : (dawVersion ?? this.dawVersion),
      todos: todos ?? this.todos,
      hidden: hidden ?? this.hidden,
      previewSongPath: clearPreviewSongPath ? null : (previewSongPath ?? this.previewSongPath),
      fileCreatedAt: fileCreatedAt ?? this.fileCreatedAt,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      previewSongFileName: clearPreviewSongFileName ? null : (previewSongFileName ?? this.previewSongFileName),
      uploadedPreviewSongHash: clearUploadedPreviewSongHash ? null : (uploadedPreviewSongHash ?? this.uploadedPreviewSongHash),
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      previewSongAutoPath: clearPreviewSongAutoPath ? null : (previewSongAutoPath ?? this.previewSongAutoPath),
      parentProjectId: clearParentProjectId ? null : (parentProjectId ?? this.parentProjectId),
      totalWorkSeconds: totalWorkSeconds ?? this.totalWorkSeconds,
      sessions: sessions ?? this.sessions,
      metadataScanned: metadataScanned ?? this.metadataScanned,
      ignoredNewerSongPath: clearIgnoredNewerSongPath ? null : (ignoredNewerSongPath ?? this.ignoredNewerSongPath),
      projectNotes: projectNotes ?? this.projectNotes,
      sourceTemplateId: clearSourceTemplateId ? null : (sourceTemplateId ?? this.sourceTemplateId),
      parts: parts ?? this.parts,
      isVirtual: isVirtual ?? this.isVirtual,
      memberProjectIds: memberProjectIds ?? this.memberProjectIds,
      defaultLaunchMemberId: clearDefaultLaunchMemberId
          ? null
          : (defaultLaunchMemberId ?? this.defaultLaunchMemberId),
      stackId: clearStackId ? null : (stackId ?? this.stackId),
      markers: markers ?? this.markers,
      attachments: attachments ?? this.attachments,
    );
  }

  /// Recording progress across [parts]: how many are on their final take.
  int get partsDoneCount => ProjectPart.doneCount(parts);

  /// Everyone credited on this song, in part order, without duplicates.
  List<String> get performers => ProjectPart.performers(parts);
}

class MusicProjectAdapter extends TypeAdapter<MusicProject> {
  @override
  final int typeId = 1;

  @override
  MusicProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return MusicProject(
      id: fields[0] as String,
      filePath: fields[1] as String,
      fileName: fields[2] as String,
      fileSizeBytes: fields[3] as int,
      lastModifiedAt: fields[4] as DateTime,
      customDisplayName: fields[5] as String?,
      thumbnailPath: fields[6] as String?,
      // Migrate old "Draft" status to "Idea" for backward compatibility
      status: (fields[7] as String) == 'Draft' ? 'Idea' : (fields[7] as String),
      fileExtension: fields[8] as String,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      bpm: fields[11] as double?,
      musicalKey: fields[12] as String?,
      notes: fields.containsKey(13) ? fields[13] as String? : null, // NOVO CAMPO
      dawType: fields.containsKey(14) ? fields[14] as String? : null,
      dawVersion: fields.containsKey(15) ? fields[15] as String? : null,
      todos: fields.containsKey(16) && fields[16] != null 
          ? (fields[16] as List).cast<TodoItem>()
          : const [],
      hidden: fields.containsKey(17) ? (fields[17] as bool) : false,
      previewSongPath: fields.containsKey(18) ? fields[18] as String? : null,
      fileCreatedAt: fields.containsKey(19) ? fields[19] as DateTime? : null,
      statusChangedAt: fields.containsKey(20) ? fields[20] as DateTime? : null,
      previewSongFileName: fields.containsKey(21) ? fields[21] as String? : null,
      uploadedPreviewSongHash: fields.containsKey(22) ? fields[22] as String? : null,
      deadline: fields.containsKey(23) ? fields[23] as DateTime? : null,
      previewSongAutoPath: fields.containsKey(24) ? fields[24] as String? : null,
      parentProjectId: fields.containsKey(25) ? fields[25] as String? : null,
      totalWorkSeconds: fields.containsKey(26) ? (fields[26] as int? ?? 0) : 0,
      sessions: fields.containsKey(27)
          ? (fields[27] as List? ?? [])
              .map((e) => SessionRecord.fromMap(e as Map))
              .toList()
          : const [],
      metadataScanned: fields.containsKey(28) ? (fields[28] as bool? ?? false) : false,
      ignoredNewerSongPath: fields.containsKey(29) ? fields[29] as String? : null,
      projectNotes: fields.containsKey(30) ? fields[30] as String? : null,
      sourceTemplateId: fields.containsKey(31) ? fields[31] as String? : null,
      parts: fields.containsKey(32) && fields[32] != null
          ? (fields[32] as List).cast<ProjectPart>()
          : const [],
      isVirtual: fields.containsKey(33) ? (fields[33] as bool? ?? false) : false,
      memberProjectIds: fields.containsKey(34)
          ? ((fields[34] as List?)?.cast<String>() ?? const <String>[])
          : const <String>[],
      defaultLaunchMemberId: fields.containsKey(35) ? fields[35] as String? : null,
      stackId: fields.containsKey(36) ? fields[36] as String? : null,
      markers: fields.containsKey(37)
          ? ((fields[37] as List?) ?? const [])
              .map((e) => ProjectMarker.fromMap(e as Map))
              .toList()
          : const [],
      attachments: fields.containsKey(38)
          ? ((fields[38] as List?) ?? const [])
              .map((e) => ProjectAttachment.fromMap(e as Map))
              .toList()
          : const [],
    );
  }

  @override
  void write(BinaryWriter writer, MusicProject obj) {
    writer
      ..writeByte(39) // 39 fields (0-38)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.fileSizeBytes)
      ..writeByte(4)
      ..write(obj.lastModifiedAt)
      ..writeByte(5)
      ..write(obj.customDisplayName)
      ..writeByte(6)
      ..write(obj.thumbnailPath)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.fileExtension)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.bpm)
      ..writeByte(12)
      ..write(obj.musicalKey)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.dawType)
      ..writeByte(15)
      ..write(obj.dawVersion)
      ..writeByte(16)
      ..write(obj.todos)
      ..writeByte(17)
      ..write(obj.hidden)
      ..writeByte(18)
      ..write(obj.previewSongPath)
      ..writeByte(19)
      ..write(obj.fileCreatedAt)
      ..writeByte(20)
      ..write(obj.statusChangedAt)
      ..writeByte(21)
      ..write(obj.previewSongFileName)
      ..writeByte(22)
      ..write(obj.uploadedPreviewSongHash)
      ..writeByte(23)
      ..write(obj.deadline)
      ..writeByte(24)
      ..write(obj.previewSongAutoPath)
      ..writeByte(25)
      ..write(obj.parentProjectId)
      ..writeByte(26)
      ..write(obj.totalWorkSeconds)
      ..writeByte(27)
      ..write(obj.sessions.map((s) => s.toMap()).toList())
      ..writeByte(28)
      ..write(obj.metadataScanned)
      ..writeByte(29)
      ..write(obj.ignoredNewerSongPath)
      ..writeByte(30)
      ..write(obj.projectNotes)
      ..writeByte(31)
      ..write(obj.sourceTemplateId)
      ..writeByte(32)
      ..write(obj.parts)
      ..writeByte(33)
      ..write(obj.isVirtual)
      ..writeByte(34)
      ..write(obj.memberProjectIds)
      ..writeByte(35)
      ..write(obj.defaultLaunchMemberId)
      ..writeByte(36)
      ..write(obj.stackId)
      ..writeByte(37)
      ..write(obj.markers.map((m) => m.toMap()).toList())
      ..writeByte(38)
      ..write(obj.attachments.map((a) => a.toMap()).toList());
  }
}
