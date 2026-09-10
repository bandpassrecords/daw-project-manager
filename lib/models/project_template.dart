import 'package:hive_ce/hive.dart';

part 'project_template.g.dart';

/// A registered "starter kit" folder a new project can be created from —
/// the whole folder containing [mainFileRelativePath] gets copied to a new
/// location and the main file (plus the destination folder itself) renamed
/// to the new project's name; every other file is copied unchanged.
@HiveType(typeId: 12)
class ProjectTemplate extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  /// The folder that gets copied wholesale when instantiating this template
  /// — the parent folder of the file the user pointed to when registering it.
  @HiveField(2)
  final String sourceFolderPath;

  /// Path of the main DAW project file, relative to [sourceFolderPath] (e.g.
  /// `'Song Template.als'` or `'Renders/Song Template.als'` for a nested main
  /// file). Used to locate the same file post-copy so it can be renamed and
  /// opened.
  @HiveField(3)
  final String mainFileRelativePath;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  /// Beats per minute — auto-extracted from the main file when supported,
  /// otherwise left null for the user to fill in manually (same as
  /// `MusicProject.bpm`).
  @HiveField(6)
  final double? bpm;

  /// e.g. `C#m`, `F major` — auto-extracted when supported, otherwise
  /// user-editable (same as `MusicProject.musicalKey`).
  @HiveField(7)
  final String? musicalKey;

  /// DAW version string (e.g. `'12.0.4'`) — auto-extracted only, no manual
  /// entry UI, mirroring how `MusicProject.dawVersion` is read-only.
  @HiveField(8)
  final String? dawVersion;

  /// Free-text notes the user can attach to a template — e.g. reminders
  /// about its intended purpose or setup quirks. Editable (same as
  /// `MusicProject.notes`).
  @HiveField(9)
  final String? notes;

  /// Notes read straight out of the DAW project file itself (e.g. Reaper's
  /// Title/Author/Notes tab) when the format supports it — read-only, same
  /// as `MusicProject.projectNotes`. Distinct from [notes] above.
  @HiveField(10)
  final String? projectNotes;

  /// Hidden from the templates table unless the user asks to see hidden ones
  /// — the templates equivalent of `MusicProject.hidden`. Hiding, rather
  /// than deleting, is what a user gets for a template whose files are still
  /// on disk: the record stays, so a template-folder refresh recognizes the
  /// path as already registered instead of re-importing it as new.
  @HiveField(11)
  final bool hidden;

  ProjectTemplate({
    required this.id,
    required this.name,
    required this.sourceFolderPath,
    required this.mainFileRelativePath,
    required this.createdAt,
    required this.updatedAt,
    this.bpm,
    this.musicalKey,
    this.dawVersion,
    this.notes,
    this.projectNotes,
    this.hidden = false,
  });

  ProjectTemplate copyWith({
    String? id,
    String? name,
    String? sourceFolderPath,
    String? mainFileRelativePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? bpm,
    bool clearBpm = false,
    String? musicalKey,
    bool clearMusicalKey = false,
    String? dawVersion,
    String? notes,
    bool clearNotes = false,
    String? projectNotes,
    bool? hidden,
  }) {
    return ProjectTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceFolderPath: sourceFolderPath ?? this.sourceFolderPath,
      mainFileRelativePath: mainFileRelativePath ?? this.mainFileRelativePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bpm: clearBpm ? null : (bpm ?? this.bpm),
      musicalKey: clearMusicalKey ? null : (musicalKey ?? this.musicalKey),
      dawVersion: dawVersion ?? this.dawVersion,
      notes: clearNotes ? null : (notes ?? this.notes),
      projectNotes: projectNotes ?? this.projectNotes,
      hidden: hidden ?? this.hidden,
    );
  }
}
