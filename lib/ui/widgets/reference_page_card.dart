import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

/// The "generate the insert reference page" card on the settings page.
///
/// Split out of `settings_page.dart` so it can be pumped on its own, like
/// `PartsExportCard`.
class ReferencePageCard extends StatelessWidget {
  const ReferencePageCard({
    super.key,
    required this.busy,
    required this.onGenerate,
  });

  /// Disables the button while another settings task is running.
  final bool busy;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.insights_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.referenceTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(l10n.referenceSubtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: busy ? null : onGenerate,
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.referenceButton),
            ),
          ],
        ),
      ),
    );
  }
}
