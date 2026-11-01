import 'package:material_ui/material_ui.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../services/project_inspector/launch_check.dart';
import '../widgets/project_inspector_view.dart' show trimNumber;

/// What the person chose when warned before a project opened (#222).
enum LaunchChoice { open, relink, safeCopy, inspect, cancel }

/// "44.1 kHz", "48 kHz".
String sampleRateText(int hz) => '${trimNumber(hz / 1000)} kHz';

/// Says what [warnings] found before [projectName] opens, and offers what
/// can be done about it: open anyway, fix the missing files or make a Safe
/// Copy (where [canRelink] / [canSafeCopy]: the format can be written),
/// inspect, or not open it.
class LaunchWarningsDialog extends StatelessWidget {
  const LaunchWarningsDialog({
    super.key,
    required this.projectName,
    required this.warnings,
    this.canRelink = false,
    this.canSafeCopy = false,
  });

  final String projectName;
  final LaunchWarnings warnings;
  final bool canRelink;
  final bool canSafeCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final w = warnings;
    void pick(LaunchChoice c) => Navigator.of(context).pop(c);
    return AlertDialog(
      title: Text(l10n.launchCheckTitle(projectName)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (w.missingAudio > 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.link_off, color: theme.colorScheme.error),
                title: Text(
                  l10n.launchCheckMissingAudio(w.missingAudio, w.totalAudio),
                ),
              ),
            if (w.sampleRateDiffers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.graphic_eq,
                  color: theme.colorScheme.tertiary,
                ),
                title: Text(
                  l10n.launchCheckSampleRate(
                    sampleRateText(w.projectRate!),
                    sampleRateText(w.studioRate!),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => pick(LaunchChoice.cancel),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => pick(LaunchChoice.inspect),
          child: Text(l10n.projectMenuInspect),
        ),
        if (canSafeCopy)
          TextButton(
            onPressed: () => pick(LaunchChoice.safeCopy),
            child: Text(l10n.safeCopyButton),
          ),
        if (canRelink && w.missingAudio > 0)
          TextButton(
            onPressed: () => pick(LaunchChoice.relink),
            child: Text(l10n.relinkFixButton),
          ),
        FilledButton(
          onPressed: () => pick(LaunchChoice.open),
          child: Text(l10n.launchCheckOpenAnyway),
        ),
      ],
    );
  }
}

/// The sample rates offered for "My studio runs at".
const kStudioSampleRates = [44100, 48000, 88200, 96000, 176400, 192000];

/// Settings > DAW Locations' card for the check before opening (#222): the
/// switch and the studio's sample rate. Plain values and callbacks.
class LaunchCheckSettingsCard extends StatelessWidget {
  const LaunchCheckSettingsCard({
    super.key,
    required this.enabled,
    required this.studioRate,
    required this.onEnabled,
    required this.onStudioRate,
  });

  final bool enabled;
  final int? studioRate;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<int?> onStudioRate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.fact_check_outlined),
            title: Text(l10n.launchCheckSetting),
            subtitle: Text(l10n.launchCheckSettingHint),
            value: enabled,
            onChanged: onEnabled,
          ),
          ListTile(
            leading: const Icon(Icons.graphic_eq),
            title: Text(l10n.studioSampleRate),
            trailing: DropdownButton<int?>(
              value: studioRate,
              onChanged: onStudioRate,
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.studioSampleRateNotSet),
                ),
                for (final hz in kStudioSampleRates)
                  DropdownMenuItem(value: hz, child: Text(sampleRateText(hz))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
