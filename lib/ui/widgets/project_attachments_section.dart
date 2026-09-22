import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/project_attachment.dart';

/// The list of files and links attached to a song (#112).
///
/// A plain view widget on purpose — same shape as [ProjectMarkersSection] and
/// [ProjectVersionsSection]: it takes a list of attachments plus already
/// localized labels and callbacks, never a `MusicProject` or a `Ref`, so every
/// state here (empty, missing file, link, note) can be widget-tested without
/// opening Hive or standing up providers.
class ProjectAttachmentsSection extends StatelessWidget {
  const ProjectAttachmentsSection({
    super.key,
    required this.attachments,
    required this.missingTargets,
    required this.addFileLabel,
    required this.addLinkLabel,
    required this.exportLabel,
    required this.exportTooltip,
    required this.emptyTitle,
    required this.emptyDescription,
    required this.missingLabel,
    required this.openTooltip,
    required this.editTooltip,
    required this.removeTooltip,
    required this.onAddFile,
    required this.onAddLink,
    required this.onExport,
    required this.onOpen,
    required this.onEdit,
    required this.onRemove,
    this.padding = EdgeInsets.zero,
  });

  final List<ProjectAttachment> attachments;

  /// Ids of file attachments whose path no longer resolves. Passed in rather
  /// than stat-ed here so the widget stays synchronous and testable — a
  /// missing entry is flagged in place, the way a missing project file is,
  /// instead of failing silently when the user clicks it.
  final Set<String> missingTargets;

  final String addFileLabel;
  final String addLinkLabel;
  final String exportLabel;
  final String exportTooltip;
  final String emptyTitle;
  final String emptyDescription;
  final String missingLabel;
  final String openTooltip;
  final String editTooltip;
  final String removeTooltip;

  final VoidCallback onAddFile;
  final VoidCallback onAddLink;

  /// Saves the attachments somewhere the user can hand on — one file, one
  /// text file of links, or a ZIP of both. Hidden while there is nothing to
  /// save.
  final VoidCallback onExport;
  final void Function(ProjectAttachment attachment) onOpen;
  final void Function(ProjectAttachment attachment) onEdit;
  final void Function(ProjectAttachment attachment) onRemove;

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onAddFile,
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(addFileLabel),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onAddLink,
                icon: const Icon(Icons.link, size: 18),
                label: Text(addLinkLabel),
              ),
              if (attachments.isNotEmpty) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: exportTooltip,
                  child: OutlinedButton.icon(
                    onPressed: onExport,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(exportLabel),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (attachments.isEmpty)
            _EmptyState(title: emptyTitle, description: emptyDescription)
          else
            for (final attachment in attachments)
              _AttachmentRow(
                key: ValueKey(attachment.id),
                attachment: attachment,
                missing: missingTargets.contains(attachment.id),
                missingLabel: missingLabel,
                openTooltip: openTooltip,
                editTooltip: editTooltip,
                removeTooltip: removeTooltip,
                onOpen: () => onOpen(attachment),
                onEdit: () => onEdit(attachment),
                onRemove: () => onRemove(attachment),
              ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    super.key,
    required this.attachment,
    required this.missing,
    required this.missingLabel,
    required this.openTooltip,
    required this.editTooltip,
    required this.removeTooltip,
    required this.onOpen,
    required this.onEdit,
    required this.onRemove,
  });

  final ProjectAttachment attachment;
  final bool missing;
  final String missingLabel;
  final String openTooltip;
  final String editTooltip;
  final String removeTooltip;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = theme.textTheme.bodySmall?.color;
    final note = attachment.note?.trim();

    final tile = ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        missing
            ? Icons.report_gmailerrorred_outlined
            : (attachment.isLink ? Icons.link : Icons.insert_drive_file_outlined),
        color: missing ? Colors.red.shade300 : theme.colorScheme.primary,
      ),
      title: Text(
        attachment.displayLabel,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: missing ? Colors.red.shade300 : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            missing ? '$missingLabel  ·  ${attachment.target}' : attachment.target,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: missing ? Colors.red.shade300 : subtitleColor,
            ),
          ),
          if (note != null && note.isNotEmpty)
            Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: subtitleColor),
            ),
          Text(
            DateFormat.yMMMd(Localizations.localeOf(context).toString())
                .format(attachment.addedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: subtitleColor?.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: editTooltip,
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: removeTooltip,
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red.shade300,
            onPressed: onRemove,
          ),
        ],
      ),
      // Missing files stay tappable: the click is what surfaces the "file not
      // found" message, and the row is already flagged red before it.
      onTap: onOpen,
    );

    return Tooltip(message: openTooltip, child: tile);
  }
}
