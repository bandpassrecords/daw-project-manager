import 'package:material_ui/material_ui.dart';

import '../../generated/l10n/app_localizations.dart';

/// The "plug-in presets from your Cubase projects" card on the settings page.
///
/// Split out of `settings_page.dart` so it can be pumped on its own, like
/// `SamplePackCard`.
class PluginPresetsCard extends StatelessWidget {
  const PluginPresetsCard({
    super.key,
    required this.busy,
    required this.onExport,
  });

  /// Disables the button while another settings task is running.
  final bool busy;
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
            const Icon(Icons.tune),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pluginPresetsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.pluginPresetsSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
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
