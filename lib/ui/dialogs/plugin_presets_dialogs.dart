import 'package:material_ui/material_ui.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/plugin_presets/preset_export.dart';

/// Reads the projects one by one, saying which, with a way to stop. Pops with
/// the [PresetExportResult], or the error that ended it.
class PluginPresetsProgressDialog extends StatefulWidget {
  const PluginPresetsProgressDialog({super.key, required this.run});

  final Future<PresetExportResult> Function(
    void Function(int done, int total, String name) onProgress,
    bool Function() shouldStop,
  )
  run;

  @override
  State<PluginPresetsProgressDialog> createState() =>
      _PluginPresetsProgressDialogState();
}

class _PluginPresetsProgressDialogState
    extends State<PluginPresetsProgressDialog> {
  ({int done, int total, String name})? _update;
  bool _stop = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    Object? outcome;
    try {
      outcome = await widget.run((done, total, name) {
        if (mounted) setState(() => _update = (done: done, total: total, name: name));
      }, () => _stop);
    } catch (e) {
      outcome = e;
    }
    if (mounted) Navigator.pop(context, outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final u = _update;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.pluginPresetsProgressTitle),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: u == null || u.total == 0 ? null : u.done / u.total,
              ),
              const SizedBox(height: 12),
              if (u != null && u.name.isNotEmpty)
                Text(
                  l10n.pluginPresetsReading(
                    u.done + 1 > u.total ? u.total : u.done + 1,
                    u.total,
                    u.name,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _stop ? null : () => setState(() => _stop = true),
            child: Text(l10n.stop),
          ),
        ],
      ),
    );
  }
}

/// How many plug-ins are named before the rest are summed up as "…".
const kPluginPresetsNamedUnsavable = 5;

/// What the export did, with a way into the folder.
class PluginPresetsResultDialog extends StatelessWidget {
  const PluginPresetsResultDialog({
    super.key,
    required this.result,
    required this.onOpenFolder,
  });

  final PresetExportResult result;
  final VoidCallback onOpenFolder;

  /// The plug-ins whose state can't be saved, the most numerous first.
  static String unsavableNames(Map<String, int> unsavable) {
    final ordered = unsavable.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final shown = ordered.take(kPluginPresetsNamedUnsavable).map((e) => e.key);
    return ordered.length > kPluginPresetsNamedUnsavable
        ? '${shown.join(', ')}…'
        : shown.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lines = [
      l10n.pluginPresetsSaved(result.written),
      if (result.alreadyThere > 0)
        l10n.pluginPresetsAlreadyThere(result.alreadyThere),
      if (result.unsavable.isNotEmpty)
        l10n.pluginPresetsUnsavable(
          result.unsavableInstances,
          unsavableNames(result.unsavable),
        ),
      if (result.projectsFailed > 0)
        l10n.pluginPresetsNotRead(result.projectsFailed),
    ];
    return AlertDialog(
      title: Text(
        result.stopped
            ? l10n.pluginPresetsStoppedTitle
            : l10n.pluginPresetsDoneTitle,
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $line'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
        if (result.written > 0 || result.alreadyThere > 0)
          FilledButton.icon(
            onPressed: onOpenFolder,
            icon: const Icon(Icons.folder_open),
            label: Text(l10n.openFolder),
          ),
      ],
    );
  }
}
