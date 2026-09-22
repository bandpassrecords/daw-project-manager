import 'package:path/path.dart' as p;

/// Whether an attachment points at something on disk or somewhere on the web.
///
/// Stored explicitly rather than re-derived on every read: the user says which
/// one they meant when they add it (file picker vs. paste a link), and a path
/// that happens to contain "://" — or a URL saved before it had a scheme —
/// must not silently change how it opens later.
enum ProjectAttachmentKind {
  /// A file or folder on this machine, opened with the default application.
  file,

  /// A URL, opened in the default browser.
  link,
}

/// One piece of material a song drags behind it: the reference track, the
/// stem-delivery Drive link, the lyric sheet, the contract, the client's
/// feedback doc.
///
/// Only the *reference* is stored — an absolute path or a URL — never a copy
/// of the file. Releases copy their attachments into an app-managed folder
/// (`ReleaseFile`); a project's attachments are pointers, the same way
/// `MusicProject.filePath` is a pointer, so attaching a 2 GB stem folder costs
/// nothing and Drive sync stays cheap.
///
/// Stored inside `MusicProject` as a plain `Map` (see [toMap]/[fromMap])
/// rather than as its own `@HiveType` — same approach as [ProjectMarker] and
/// `SessionRecord`, which avoids claiming a type id and registering another
/// adapter for what is really a value object.
class ProjectAttachment {
  const ProjectAttachment({
    required this.id,
    required this.kind,
    required this.target,
    this.label = '',
    required this.addedAt,
    this.note,
  });

  /// Unique within one project's list. Used as the identity for edit/remove,
  /// so it must survive a rename of [label] or [target].
  final String id;

  final ProjectAttachmentKind kind;

  /// The absolute file path, or the URL. Never empty in stored data.
  final String target;

  /// What the user wants to see in the list. May be empty, in which case
  /// [displayLabel] derives something readable from [target] — a label is a
  /// convenience, not a requirement, and forcing one would make "attach this
  /// file" a two-field form.
  final String label;

  final DateTime addedAt;

  /// Optional free text: "v3, before the vocal comp", "expires in 7 days".
  final String? note;

  bool get isLink => kind == ProjectAttachmentKind.link;

  /// The text to show for this attachment. Falls back to the file's base name
  /// or the URL's host+path, so an unlabelled entry still reads as something
  /// rather than as a 200-character path.
  String get displayLabel {
    final trimmed = label.trim();
    if (trimmed.isNotEmpty) return trimmed;
    if (kind == ProjectAttachmentKind.file) {
      final base = p.basename(target);
      return base.isEmpty ? target : base;
    }
    final uri = Uri.tryParse(target);
    if (uri == null || uri.host.isEmpty) return target;
    final path = uri.path == '/' ? '' : uri.path;
    return '${uri.host}$path';
  }

  /// Whether [raw] reads as a URL rather than a local path.
  ///
  /// Deliberately conservative: a Windows path (`C:\Stems\ref.wav`) has a
  /// colon but no `//`, and a UNC path (`\\nas\stems`) has no scheme, so
  /// neither is mistaken for a link.
  static bool looksLikeUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;
    if (value.toLowerCase().startsWith('www.')) return true;
    if (RegExp(r'^mailto:\S+@\S+', caseSensitive: false).hasMatch(value)) {
      return true;
    }
    final match = RegExp(r'^([a-zA-Z][a-zA-Z0-9+.\-]*)://').firstMatch(value);
    if (match == null) return false;
    // file:// URLs describe something on disk — treat them as paths so they
    // open in the file manager rather than in a browser tab.
    return match.group(1)!.toLowerCase() != 'file';
  }

  /// The URL to actually open for something the user typed or pasted.
  /// Adds the scheme a bare `www.example.com` is missing; otherwise returns
  /// [raw] trimmed, unchanged.
  static String normalizeUrl(String raw) {
    final value = raw.trim();
    if (value.toLowerCase().startsWith('www.')) return 'https://$value';
    return value;
  }

  ProjectAttachment copyWith({
    String? id,
    ProjectAttachmentKind? kind,
    String? target,
    String? label,
    DateTime? addedAt,
    String? note,
    bool clearNote = false,
  }) {
    return ProjectAttachment(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      target: target ?? this.target,
      label: label ?? this.label,
      addedAt: addedAt ?? this.addedAt,
      note: clearNote ? null : (note ?? this.note),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.name,
        'target': target,
        'label': label,
        'addedAt': addedAt.toIso8601String(),
        if (note != null) 'note': note,
      };

  factory ProjectAttachment.fromMap(Map map) {
    final target = map['target'] as String? ?? '';
    final rawKind = map['kind'] as String?;
    return ProjectAttachment(
      id: map['id'] as String? ?? '',
      // Anything unrecognized falls back to sniffing the target rather than
      // defaulting to one kind, so a record written by a future version (or
      // hand-edited in a backup file) still opens the right way.
      kind: _kindFromName(rawKind) ??
          (looksLikeUrl(target)
              ? ProjectAttachmentKind.link
              : ProjectAttachmentKind.file),
      target: target,
      label: map['label'] as String? ?? '',
      addedAt: DateTime.tryParse(map['addedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      note: map['note'] as String?,
    );
  }

  static ProjectAttachmentKind? _kindFromName(String? name) {
    for (final kind in ProjectAttachmentKind.values) {
      if (kind.name == name) return kind;
    }
    return null;
  }

  /// Value equality so sync can tell "the same attachments came back" from
  /// "the user added one" without comparing object identity.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectAttachment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          target == other.target &&
          label == other.label &&
          addedAt == other.addedAt &&
          note == other.note;

  @override
  int get hashCode => Object.hash(id, kind, target, label, addedAt, note);

  @override
  String toString() =>
      'ProjectAttachment($id, ${kind.name}, "$displayLabel", $target)';
}
