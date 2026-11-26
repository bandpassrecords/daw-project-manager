import 'package:path/path.dart' as p;

import '../models/music_project.dart';
import '../models/todo_item.dart';
import '../repository/root_relocations.dart';
import '../utils/project_tags.dart';
import 'project_move_service.dart';

/// One file, one row: what a merge does with a row arriving from elsewhere
/// (Drive, a local backup) whose id this profile doesn't have.
///
/// Two rows for the same file happen when the file was scanned twice under
/// different ids — a row deleted before deletions were recorded and then
/// brought back by a merge, or two computers scanning one folder — and when
/// a row from before a "Relocate folder" comes back still naming the old
/// place. In May 2026 a library got 68 of them: the old copies pointing at
/// the emptied folder, the new ones (without the user's details) at the
/// moved files.
///
/// The row already here is always the one kept, and the arriving row's
/// details are folded into it ([foldSameFileRow]). Nothing records a
/// deletion: every computer keeps its own row, so two computers can never
/// delete each other's — the arriving id simply isn't added here.

/// The key two rows for one file share: compared the way the platform
/// compares paths (case-insensitively on Windows), as `rebasePath` does.
String sameFileKey(String path) => p.canonicalize(path);

/// Whether [row] stands for one file a second row could also stand for. A
/// stack's path is a folder, an archived row's file was zipped away, and a
/// Drive reference is not a path.
bool matchesByFile(MusicProject row) =>
    !row.isVirtual &&
    !row.isArchived &&
    row.filePath.isNotEmpty &&
    !row.filePath.startsWith('drive://');

/// [row] carried through [relocations] (oldest first): each that holds its
/// path moves it on, so a folder relocated twice still lands at the end.
MusicProject relocatedRow(MusicProject row, List<RootRelocation> relocations) {
  var out = row;
  for (final r in relocations) {
    final moved = repathProject(out, from: r.from, to: r.to);
    if (moved.filePath != out.filePath) out = moved;
  }
  return out;
}

/// What to do with an arriving row.
sealed class IncomingRowPlan {
  const IncomingRowPlan();
}

/// Add it — at the place relocations say, which may differ from where it
/// arrived naming.
class AddIncomingRow extends IncomingRowPlan {
  const AddIncomingRow(this.row);
  final MusicProject row;
}

/// The file already has a row here, [keptId]. [updated] is that row with the
/// arriving one's details folded in, or null when it had nothing to add.
class FoldIncomingRow extends IncomingRowPlan {
  const FoldIncomingRow({required this.keptId, required this.updated});
  final String keptId;
  final MusicProject? updated;
}

/// The plan for [incoming]. [localByFile] holds this profile's rows by
/// [sameFileKey] (only those [matchesByFile]); the caller adds a row it adds
/// to it, so two arriving rows for one file become one too.
IncomingRowPlan planIncomingRow(
  MusicProject incoming, {
  required Map<String, MusicProject> localByFile,
  required List<RootRelocation> relocations,
}) {
  final row = relocatedRow(incoming, relocations);
  if (!matchesByFile(row)) return AddIncomingRow(row);
  final kept = localByFile[sameFileKey(row.filePath)];
  if (kept == null || kept.id == row.id) return AddIncomingRow(row);
  return FoldIncomingRow(keptId: kept.id, updated: foldSameFileRow(kept, row));
}

const _defaultStatus = 'Idea';
const _notesSeparator = '\n\n-----\n\n';

/// [kept] with what [other] — a second row for the same file — knows and it
/// doesn't, or null when [other] adds nothing.
///
/// Something set beats something unset; where both set a value and they
/// differ, the row changed more recently wins. To-dos, sessions, tags,
/// attachments and custom fields are united; notes that differ are both
/// kept, one under the other, as the DAW plugin's notes are. What a scan
/// reads (tempo, key, stats, clips) stays [kept]'s: it read the same file.
/// Stacks, releases and playlists are repointed by the caller
/// ([repointProjectIds]), never here.
///
/// Folding the same row in again changes nothing, so a merge that brings it
/// back every time doesn't write every time.
MusicProject? foldSameFileRow(MusicProject kept, MusicProject other) {
  final otherNewer = other.updatedAt.isAfter(kept.updatedAt);
  var changed = false;

  T? pick<T>(T? mine, T? theirs, {bool Function(T? v)? isSet}) {
    final set =
        isSet ?? (T? v) => v != null && (v is! String || v.trim().isNotEmpty);
    if (!set(theirs) || theirs == mine) return mine;
    if (!set(mine) || otherNewer) {
      changed = true;
      return theirs;
    }
    return mine;
  }

  final name = pick(kept.customDisplayName, other.customDisplayName);
  final deadline = pick(kept.deadline, other.deadline);
  final thumbnail = pick(kept.thumbnailPath, other.thumbnailPath);
  final accent = pick(kept.accentColor, other.accentColor);
  final icon = pick(kept.iconKey, other.iconKey);
  final initials = pick(kept.cardInitials, other.cardInitials);
  final template = pick(kept.sourceTemplateId, other.sourceTemplateId);
  final status = pick(
    kept.status,
    other.status,
    isSet: (v) => v != null && v != _defaultStatus,
  )!;
  final statusChangedAt = status == kept.status
      ? kept.statusChangedAt
      : other.statusChangedAt;
  final hidden = kept.hidden || other.hidden;
  if (hidden != kept.hidden) changed = true;

  // The preview song travels with its name and uploaded hash.
  final preview = pick(kept.previewSongPath, other.previewSongPath);
  final previewFrom = preview == kept.previewSongPath ? kept : other;

  final capture = switch ((kept.latestCapture, other.latestCapture)) {
    (null, final theirs?) => theirs,
    (final mine?, final theirs?)
        when theirs.capturedAt.isAfter(mine.capturedAt) =>
      theirs,
    (final mine, _) => mine,
  };
  if (capture != kept.latestCapture) changed = true;

  String? notes = kept.notes;
  final theirNotes = other.notes?.trim() ?? '';
  final myNotes = kept.notes?.trim() ?? '';
  if (theirNotes.isNotEmpty && !myNotes.contains(theirNotes)) {
    changed = true;
    notes = myNotes.isEmpty
        ? other.notes
        : theirNotes.contains(myNotes)
        ? other.notes
        : '${kept.notes}$_notesSeparator${other.notes}';
  }

  final todos = [...kept.todos];
  final todoIds = {for (final t in todos) t.id};
  final todoTexts = {for (final t in todos) t.text.trim()};
  for (final TodoItem t in other.todos) {
    if (todoIds.contains(t.id) || todoTexts.contains(t.text.trim())) continue;
    todos.add(t);
    changed = true;
  }

  final sessions = [...kept.sessions];
  final sessionIds = {for (final s in sessions) s.id};
  for (final s in other.sessions) {
    if (sessionIds.add(s.id)) {
      sessions.add(s);
      changed = true;
    }
  }
  sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
  final sessionSeconds = sessions.fold(0, (sum, s) => sum + s.durationSeconds);
  final workSeconds = [
    kept.totalWorkSeconds,
    other.totalWorkSeconds,
    sessionSeconds,
  ].reduce((a, b) => a > b ? a : b);
  if (workSeconds != kept.totalWorkSeconds) changed = true;

  var tags = kept.tags;
  for (final tag in other.tags) {
    final next = addTag(tags, tag);
    if (next.length != tags.length) {
      tags = next;
      changed = true;
    }
  }

  final attachments = [...kept.attachments];
  final attachmentIds = {for (final a in attachments) a.id};
  for (final a in other.attachments) {
    if (attachmentIds.add(a.id)) {
      attachments.add(a);
      changed = true;
    }
  }

  final customFields = {...kept.customFields};
  other.customFields.forEach((key, value) {
    final mine = customFields[key];
    if (value.trim().isEmpty || mine == value) return;
    if (mine == null || mine.trim().isEmpty || otherNewer) {
      customFields[key] = value;
      changed = true;
    }
  });

  final parts = kept.parts.isEmpty && other.parts.isNotEmpty
      ? other.parts
      : kept.parts;
  if (!identical(parts, kept.parts)) changed = true;

  // The song existed since the earlier of the two scans.
  final createdAt = other.createdAt.isBefore(kept.createdAt)
      ? other.createdAt
      : kept.createdAt;
  if (createdAt != kept.createdAt) changed = true;

  if (!changed) return null;
  return kept.copyWith(
    customDisplayName: name,
    deadline: deadline,
    thumbnailPath: thumbnail,
    accentColor: accent,
    iconKey: icon,
    cardInitials: initials,
    sourceTemplateId: template,
    status: status,
    statusChangedAt: statusChangedAt,
    hidden: hidden,
    previewSongPath: preview,
    previewSongFileName: previewFrom.previewSongFileName,
    uploadedPreviewSongHash: previewFrom.uploadedPreviewSongHash,
    latestCapture: capture,
    notes: notes,
    todos: todos,
    sessions: sessions,
    totalWorkSeconds: workSeconds,
    tags: tags,
    attachments: attachments,
    customFields: customFields,
    parts: parts,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
