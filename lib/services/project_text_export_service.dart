import '../generated/l10n/app_localizations.dart';
import '../models/music_project.dart';
import '../utils/part_status_display.dart';

/// Formats [MusicProject] data as human-readable plain text, so a record of a
/// project survives even after its DAW file and library entry are gone.
class ProjectTextExportService {
  const ProjectTextExportService._();

  /// A single project's info as plain text.
  static String formatProject(MusicProject project, AppLocalizations l10n) {
    final buffer = StringBuffer();
    _writeProject(buffer, project, l10n);
    return buffer.toString();
  }

  /// Every project's info as one plain text document, in the given order.
  static String formatProjects(List<MusicProject> projects, AppLocalizations l10n) {
    final buffer = StringBuffer()
      ..writeln(l10n.projectExportHeaderTitle)
      ..writeln(l10n.projectExportExportedLabel(_formatDateTime(DateTime.now())))
      ..writeln(l10n.projectExportTotalProjectsLabel(projects.length))
      ..writeln();
    for (final project in projects) {
      buffer.writeln('=' * 80);
      _writeProject(buffer, project, l10n);
      buffer.writeln();
    }
    return buffer.toString();
  }

  static void _writeProject(StringBuffer buffer, MusicProject project, AppLocalizations l10n) {
    buffer
      ..writeln(l10n.projectExportProjectLabel(project.displayName))
      ..writeln('-' * 80);

    if (project.dawType != null && project.dawType!.isNotEmpty) {
      final version = project.dawVersion;
      buffer.writeln(
        version != null && version.isNotEmpty
            ? l10n.projectExportDawWithVersionLabel(project.dawType!, version)
            : l10n.projectExportDawLabel(project.dawType!),
      );
    }
    buffer.writeln(l10n.projectExportStatusLabel(project.status));
    if (project.bpm != null) {
      buffer.writeln(l10n.projectExportBpmLabel(_formatBpm(project.bpm!)));
    }
    if (project.musicalKey != null && project.musicalKey!.isNotEmpty) {
      final camelot = project.camelotCode;
      buffer.writeln(
        camelot != null
            ? l10n.projectExportKeyWithCamelotLabel(project.musicalKey!, camelot)
            : l10n.projectExportKeyLabel(project.musicalKey!),
      );
    }
    buffer
      ..writeln(l10n.projectExportFilePathLabel(project.filePath))
      ..writeln(l10n.projectExportFileSizeLabel(_formatFileSize(project.fileSizeBytes)));
    if (project.fileCreatedAt != null) {
      buffer.writeln(l10n.projectExportFileCreatedLabel(_formatDate(project.fileCreatedAt!)));
    }
    buffer
      ..writeln(l10n.projectExportAddedToLibraryLabel(_formatDate(project.createdAt)))
      ..writeln(l10n.projectExportLastModifiedLabel(_formatDate(project.lastModifiedAt)));
    if (project.deadline != null) {
      final status = project.deadlineStatus;
      buffer.writeln(
        status != null
            ? l10n.projectExportDeadlineWithStatusLabel(_formatDate(project.deadline!), status)
            : l10n.projectExportDeadlineLabel(_formatDate(project.deadline!)),
      );
    }
    if (project.totalWorkSeconds > 0) {
      buffer.writeln(l10n.projectExportTotalTimeWorkedLabel(_formatDuration(project.totalWorkSeconds)));
    }

    final notes = project.notes?.trim();
    if (notes != null && notes.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(l10n.projectExportNotesLabel);
      for (final line in notes.split('\n')) {
        buffer.writeln('  $line');
      }
    }

    if (project.parts.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(l10n.projectExportPartsLabel);
      for (final part in project.parts) {
        final performer = part.performer?.trim();
        final who = performer != null && performer.isNotEmpty
            ? performer
            : l10n.partsUnassignedPerformer;
        buffer.writeln('  ${part.name} — $who — ${part.status.label(l10n)}');
        final notes = part.notes?.trim();
        if (notes != null && notes.isNotEmpty) {
          for (final line in notes.split('\n')) {
            buffer.writeln('      $line');
          }
        }
      }
      buffer.writeln(
        '  ${l10n.partsProgress(project.partsDoneCount, project.parts.length)}',
      );
    }

    if (project.todos.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(l10n.projectExportTodosLabel);
      for (final todo in project.todos) {
        final due = todo.dueAt != null ? ' (${_formatDate(todo.dueAt!)})' : '';
        buffer.writeln('  [${todo.completed ? 'x' : ' '}] ${todo.text}$due');
      }
    }

    if (project.sessions.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(l10n.projectExportWorkSessionsLabel(project.sessions.length));
      for (final session in project.sessions) {
        final phase = session.phase != null && session.phase!.isNotEmpty ? ' [${session.phase}]' : '';
        buffer.writeln(
          '  ${_formatDateTime(session.startedAt)} - ${_formatDateTime(session.endedAt)} '
          '(${_formatDuration(session.durationSeconds)})$phase',
        );
      }
    }
  }

  static String _formatBpm(double bpm) =>
      bpm == bpm.roundToDouble() ? bpm.toStringAsFixed(0) : bpm.toStringAsFixed(2);

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatDateTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} $h:$min';
  }

  static String _formatFileSize(int bytes) {
    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;
    if (bytes < kb) return '$bytes B';
    if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / gb).toStringAsFixed(2)} GB';
  }

  static String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '${totalSeconds}s';
  }

  static String _sanitizeForFileName(String name) =>
      name.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_').trim();

  /// Suggested file name for a single-project export.
  static String suggestedFileNameFor(MusicProject project) {
    final safeName = _sanitizeForFileName(project.displayName);
    return '${safeName.isEmpty ? 'project' : safeName}_info.txt';
  }

  /// Suggested file name for a bulk, all-projects export.
  static String suggestedBulkFileName() =>
      'daw_project_manager_projects_${_formatDate(DateTime.now())}.txt';
}
