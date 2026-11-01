import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations_en.dart';
import 'package:daw_project_manager/generated/l10n/app_localizations_pt.dart';
import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/services/project_inspector/compare/anatomy_diff.dart';
import 'package:daw_project_manager/services/project_inspector/compare/anatomy_diff_csv.dart';
import 'package:daw_project_manager/ui/widgets/anatomy_compare_text.dart';

void main() {
  final l10n = AppLocalizationsEn();
  String say(AnatomyChange c) => changeText(l10n, c);

  test('every kind of change reads as a sentence', () {
    expect(
      say(const AnatomyChange(AnatomyChangeKind.tempo, before: 145.0, after: 150.5)),
      'Tempo 145 → 150.5 BPM',
    );
    expect(
      say(const AnatomyChange(AnatomyChangeKind.sampleRate, before: 48000, after: 44100)),
      'Sample rate 48 kHz → 44.1 kHz',
    );
    expect(
      say(const AnatomyChange(AnatomyChangeKind.bitDepth, before: 24, after: 32)),
      'Bit depth 24-bit → 32-bit',
    );
    expect(
      say(const AnatomyChange(AnatomyChangeKind.volume, before: -4.0, after: -11.4)),
      'Fader −4.0 dB → −11.4 dB',
    );
    expect(
      say(const AnatomyChange(
        AnatomyChangeKind.volume,
        before: 0.5,
        after: 0.75,
        position: true,
      )),
      'Fader 50% → 75%',
    );
    expect(
      say(const AnatomyChange(AnatomyChangeKind.pan, before: 0.0, after: -0.3)),
      'Pan C → L30',
    );
    expect(say(const AnatomyChange(AnatomyChangeKind.muted, before: false, after: true)),
        'Muted');
    expect(say(const AnatomyChange(AnatomyChangeKind.muted, before: true, after: false)),
        'Unmuted');
    expect(
      say(const AnatomyChange(
        AnatomyChangeKind.channelKind,
        before: AnatomyChannelKind.audio,
        after: AnatomyChannelKind.group,
      )),
      'Kind Audio → Group',
    );
    expect(
      say(const AnatomyChange(AnatomyChangeKind.output, before: null, after: 'Drums')),
      'Output none → Drums',
    );
    expect(
      say(const AnatomyChange(AnatomyChangeKind.insertAdded, subject: 'Pro-L 2', slot: 5)),
      'Pro-L 2 inserted in slot 6',
      reason: 'slots are numbered from 1, as DAWs show them',
    );
    expect(
      say(const AnatomyChange(
        AnatomyChangeKind.insertReplaced,
        slot: 1,
        before: 'OTT',
        after: 'Saturn 2',
      )),
      'Slot 2: OTT replaced by Saturn 2',
    );
    expect(
      say(const AnatomyChange(
        AnatomyChangeKind.insertMoved,
        subject: 'LFOTool',
        slot: 12,
        before: 11,
        after: 12,
      )),
      'LFOTool moved from slot 12 to 13',
    );
    expect(
      say(const AnatomyChange(
        AnatomyChangeKind.insertSwitched,
        subject: 'OTT',
        before: true,
        after: false,
      )),
      'OTT switched off',
    );
    expect(
      say(const AnatomyChange(
        AnatomyChangeKind.sendLevel,
        subject: 'Reverb',
        before: 12.9,
        after: 8.6,
      )),
      'Send to Reverb +12.9 dB → +8.6 dB',
    );
    expect(
      say(const AnatomyChange(
        AnatomyChangeKind.sendPreFader,
        subject: 'Reverb',
        before: false,
        after: true,
      )),
      'Send to Reverb now pre-fader',
    );
    // Nothing throws, whatever the kind.
    for (final kind in AnatomyChangeKind.values) {
      final c = switch (kind) {
        AnatomyChangeKind.tempo => AnatomyChange(kind, before: 1.0, after: 2.0),
        AnatomyChangeKind.pan => AnatomyChange(kind, before: 0.0, after: 1.0),
        AnatomyChangeKind.bitDepth => AnatomyChange(kind, before: 16, after: 24),
        AnatomyChangeKind.insertMoved =>
          AnatomyChange(kind, subject: 'X', before: 0, after: 1),
        _ => AnatomyChange(kind, subject: 'X', before: 'a', after: 'b'),
      };
      expect(say(c), isNotEmpty, reason: kind.name);
    }
  });

  test('in Portuguese too', () {
    expect(
      changeText(
        AppLocalizationsPt(),
        const AnatomyChange(AnatomyChangeKind.insertAdded, subject: 'OTT', slot: 0),
      ),
      'OTT inserido no slot 1',
    );
  });

  const diff = AnatomyDiff(
    channelsCompared: true,
    projectChanges: [
      AnatomyChange(AnatomyChangeKind.tempo, before: 145.0, after: 150.0),
    ],
    channels: [
      ChannelComparison(
        a: AnatomyChannel(name: 'Audio 01', kind: AnatomyChannelKind.audio),
        b: AnatomyChannel(name: 'Lead', kind: AnatomyChannelKind.audio),
        changes: [
          AnatomyChange(AnatomyChangeKind.renamed, before: 'Audio 01', after: 'Lead'),
          AnatomyChange(AnatomyChangeKind.volume, before: -4.0, after: -6.0),
        ],
      ),
      ChannelComparison(
        a: AnatomyChannel(name: 'Kick', kind: AnatomyChannelKind.audio),
        b: AnatomyChannel(name: 'Kick', kind: AnatomyChannelKind.audio),
      ),
      ChannelComparison(
        b: AnatomyChannel(name: 'FX, "wide"', kind: AnatomyChannelKind.fx),
        changes: [AnatomyChange(AnatomyChangeKind.channelAdded)],
      ),
    ],
  );

  test('a renamed channel is named "A → B"', () {
    expect(comparedChannelName(diff.channels[0]), 'Audio 01 → Lead');
    expect(comparedChannelName(diff.channels[1]), 'Kick');
  });

  test('the summary: totals, the project, each changed channel', () {
    expect(
      compareSummaryText(l10n, diff, aName: 'Song 2.cpr', bName: 'Song 3.cpr'),
      'Compare: A = Song 2.cpr, B = Song 3.cpr\n'
      '4 changes · 1 channel changed · 0 only in A · 1 only in B\n'
      '\n'
      'Project\n'
      '- Tempo 145 → 150 BPM\n'
      '\n'
      'Audio 01 → Lead\n'
      '- Fader −4.0 dB → −6.0 dB\n'
      '\n'
      'FX, "wide"\n'
      '- Added',
    );
  });

  test('the CSV: a row per change, English, quoted where it must be', () {
    final lines = anatomyDiffCsv(diff).split('\n');
    expect(lines[0], '﻿area,channel_a,channel_b,change,subject,slot,before,after,unit');
    expect(lines.sublist(1, 5), [
      'project,,,tempo,,,145.00,150.00,',
      'tracks,Audio 01,Lead,renamed,,,Audio 01,Lead,',
      'levels,Audio 01,Lead,volume,,,-4.00,-6.00,dB',
      'tracks,,"FX, ""wide""",channelAdded,,,,,',
    ]);
  });
}
