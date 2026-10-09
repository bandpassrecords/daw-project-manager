import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';

/// The "export melodic MIDI with a catalog" card on the settings page.
///
/// Split out of `settings_page.dart` so it can be pumped on its own, like
/// `PartsExportCard`.
class MelodicExportCard extends StatelessWidget {
  const MelodicExportCard({
    super.key,
    required this.busy,
    required this.includeChords,
    required this.includeBass,
    required this.onIncludeChordsChanged,
    required this.onIncludeBassChanged,
    required this.onExport,
  });

  /// Disables everything while another settings task is running.
  final bool busy;
  final bool includeChords;
  final bool includeBass;
  final ValueChanged<bool> onIncludeChordsChanged;
  final ValueChanged<bool> onIncludeBassChanged;
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
            const Icon(Icons.piano_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.melodicExportTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(l10n.melodicExportSubtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: includeChords,
                    onChanged: busy
                        ? null
                        : (v) => onIncludeChordsChanged(v ?? false),
                    title: Text(l10n.melodicExportIncludeChords),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: includeBass,
                    onChanged:
                        busy ? null : (v) => onIncludeBassChanged(v ?? false),
                    title: Text(l10n.melodicExportIncludeBass),
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
