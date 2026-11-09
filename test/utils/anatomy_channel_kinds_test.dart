import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/ui/widgets/project_inspector_view.dart';
import 'package:daw_project_manager/utils/project_anatomy_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('every channel kind has a label in every language, and an icon', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final labels = channelKindLabels(lookupAppLocalizations(locale));
      expect({for (final (k, _) in labels) k}, AnatomyChannelKind.values.toSet(),
          reason: '$locale');
      expect(labels.every((l) => l.$2.trim().isNotEmpty), isTrue);
    }
    for (final k in AnatomyChannelKind.values) {
      expect(channelKindIcon(k), isA<IconData>());
    }
  });

  test('the master is a mixer channel but not a track', () {
    const channels = [
      AnatomyChannel(name: 'Kick', kind: AnatomyChannelKind.audio),
      AnatomyChannel(name: 'Drums', kind: AnatomyChannelKind.folder),
      AnatomyChannel(name: 'A-Reverb', kind: AnatomyChannelKind.fx),
      AnatomyChannel(name: 'Master', kind: AnatomyChannelKind.master),
    ];
    expect([for (final c in mixerChannels(channels)) c.name],
        ['Kick', 'A-Reverb', 'Master']);
    expect([for (final c in trackChannels(channels)) c.name],
        ['Kick', 'A-Reverb']);
  });
}
