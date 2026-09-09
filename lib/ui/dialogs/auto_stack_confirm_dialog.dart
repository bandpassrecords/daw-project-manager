import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../generated/l10n/app_localizations.dart';
import '../../repository/project_repository.dart';

/// Shows what switching a scan root to Version Stack would group, and asks
/// before doing it.
///
/// Auto-stacking rewrites rows rather than redrawing them — folders become
/// main projects that own the shared metadata — so a segmented button should
/// not restructure someone's library on one tap. The caller only opens this
/// when [plan] is non-empty; with nothing to group the switch is inert and the
/// dialog would be pure friction.
///
/// Returns true when the user accepts.
Future<bool?> showAutoStackConfirmDialog(
  BuildContext context, {
  required List<AutoStackPlanEntry> plan,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final theme = Theme.of(ctx);
      final projectCount = plan.fold<int>(
        0,
        (sum, entry) => sum + entry.projects.length,
      );

      return AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(l10n.stackAutoConfirmTitle),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.stackAutoConfirmBody(projectCount, plan.length),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in plan)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.layers, size: 20),
                          title: Text(
                            l10n.stackAutoFolderEntry(
                              p.basename(entry.folder),
                              entry.resultingVersionCount,
                            ),
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                          subtitle: Text(
                            entry.createsNewStack
                                ? entry.projects
                                      .map((m) => m.displayName)
                                      .join(', ')
                                : l10n.stackAutoJoinsExisting,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.stackAutoConfirmApply),
          ),
        ],
      );
    },
  );
}
