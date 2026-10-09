import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

/// The "export Cubase track layouts for a template" card on the settings page.
///
/// Split out of `settings_page.dart` so it can be pumped on its own, like
/// `PartsExportCard`.
class TemplateExportCard extends StatelessWidget {
  const TemplateExportCard({
    super.key,
    required this.busy,
    required this.anonymize,
    required this.onAnonymizeChanged,
    required this.onExport,
  });

  /// Disables the button while another settings task is running.
  final bool busy;
  final bool anonymize;
  final ValueChanged<bool> onAnonymizeChanged;
  final VoidCallback onExport;

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
            const Icon(Icons.account_tree_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.templateExportTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(l10n.templateExportSubtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: anonymize,
                    onChanged:
                        busy ? null : (v) => onAnonymizeChanged(v ?? false),
                    title: Text(l10n.templateExportAnonymize),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: busy ? null : onExport,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(l10n.templateExportButton),
            ),
          ],
        ),
      ),
    );
  }
}
