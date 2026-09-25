import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/music_project.dart';
import '../../models/project_part.dart';
import '../../utils/part_status_display.dart';
import '../project_parts_page.dart';

/// At-a-glance instrumentation on the project detail page: progress, the first
/// few parts, and a way into [ProjectPartsPage].
///
/// Read-only on purpose — editing, reordering, bulk changes and spreadsheet
/// round-tripping all live on the workspace page, which has the room for them.
class PartsSummaryCard extends StatelessWidget {
  final MusicProject project;

  /// How many parts to list before collapsing into "+N more".
  static const previewCount = 4;

  const PartsSummaryCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final parts = project.parts;
    final preview = parts.take(previewCount).toList();
    final hidden = parts.length - preview.length;

    return Card(
      color: theme.cardColor,
      child: InkWell(
        onTap: () => open(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.piano, color: theme.textTheme.bodyMedium?.color),
                  const SizedBox(width: 8),
                  // Title and chip share one Expanded rather than sitting
                  // beside a Spacer. A loose Flexible next to a Spacer is
                  // allotted half the free space and hands back none of what
                  // it doesn't use, so the button stopped short of the edge by
                  // however much the title didn't need.
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n.songParts,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (parts.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _ProgressChip(parts: parts),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => open(context),
                    icon: const Icon(Icons.tune, size: 18),
                    label: Text(l10n.manageParts),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (parts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.noPartsYet,
                        style:
                            TextStyle(color: theme.textTheme.bodySmall?.color),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.noPartsYetHint,
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                )
              else ...[
                for (final part in preview) _PartLine(part: part),
                if (hidden > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l10n.partsMoreCount(hidden),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the workspace for this project.
  void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectPartsPage(projectId: project.id),
      ),
    );
  }
}

class _PartLine extends StatelessWidget {
  final ProjectPart part;

  const _PartLine({required this.part});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final performer = part.performer?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(part.status.icon, color: part.status.color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              part.name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            performer == null || performer.isEmpty
                ? l10n.partsUnassignedPerformer
                : performer,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 12),
          Text(
            part.status.label(l10n),
            style: theme.textTheme.bodySmall?.copyWith(color: part.status.color),
          ),
        ],
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final List<ProjectPart> parts;

  const _ProgressChip({required this.parts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = ProjectPart.allDone(parts)
        ? PartTakeStatus.finalTake.color
        : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        l10n.partsProgress(ProjectPart.doneCount(parts), parts.length),
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}
