import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations_en.dart';
import 'package:daw_project_manager/generated/l10n/app_localizations_pt.dart';
import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/models/sample_reference.dart';
import 'package:daw_project_manager/services/project_inspector/media_check.dart';
import 'package:daw_project_manager/services/project_inspector/report/anatomy_report_csv.dart';
import 'package:daw_project_manager/ui/widgets/inspector_report_text.dart';

const _song = ProjectAnatomy(
  filePath: '/music/Song/Song.cpr',
  fileSize: 2048,
  dawType: 'Cubase',
  savedWith: '13.0.41',
  tempo: 150,
  timeSignature: (4, 4),
  sampleRate: 48000,
  bitDepth: 24,
  key: 'A minor',
  pluginInstancesKnown: true,
  notes: 'Mix for the EP',
  channels: [
    AnatomyChannel(
      name: 'Bass | Sub',
      kind: AnatomyChannelKind.instrument,
      output: 'Stereo Out',
      volumeDb: -6,
      pan: -0.3,
      muted: false,
      instrument: 'Serum',
      inserts: [
        AnatomyInsert(slot: 0, plugin: 'Pro-Q 3'),
        AnatomyInsert(slot: 2, plugin: 'OTT', deactivated: true),
      ],
      sends: [
        AnatomySend(destination: 'Reverb', levelDb: -10, preFader: true),
      ],
    ),
    AnatomyChannel(name: 'Reverb', kind: AnatomyChannelKind.fx),
  ],
  plugins: [
    AnatomyPlugin(
      name: 'Serum',
      role: AnatomyPluginRole.instrument,
      stock: false,
      instances: 1,
      channels: ['Bass | Sub'],
      vendor: 'Xfer Records',
      format: 'VST3',
    ),
    AnatomyPlugin(
      name: 'Pro-Q 3',
      role: AnatomyPluginRole.effect,
      stock: false,
      instances: 1,
      channels: ['Bass | Sub'],
    ),
    AnatomyPlugin(
      name: 'OTT',
      role: AnatomyPluginRole.effect,
      stock: false,
      instances: 2,
      channels: ['Bass | Sub', 'Reverb'],
    ),
  ],
);

const _media = [
  MediaCheck(
    SampleReference(fileName: 'Kick.wav', candidates: ['/a/Kick.wav']),
    MediaStatus.found,
    path: '/a/Kick.wav',
  ),
  MediaCheck(
    SampleReference(fileName: 'Vox.wav', candidates: ['/old/Vox.wav']),
    MediaStatus.missing,
  ),
];

void main() {
  final l10n = AppLocalizationsEn();
  setUpAll(() => initializeDateFormatting());

  test('the Markdown report: overview, plug-ins, tracks, files, notes', () {
    final md = inspectorReportMarkdown(
      l10n,
      _song,
      media: _media,
      now: DateTime(2026, 10, 30),
    );
    expect(md, startsWith('# Song\n\nSaved with Cubase 13.0.41\n'));
    for (final line in [
      '## Overview',
      '- Tempo: 150 BPM',
      '- Time signature: 4/4',
      '- Sample rate: 48 kHz · 24-bit',
      '- Key: A minor',
      '- Track types: Instrument 1, FX 1',
      '- Plug-ins: 3 unique · 4 instances',
      '- Audio files: 1 of 2 missing',
      '### Instruments (1)',
      '- **Serum** ×1 (Xfer Records · VST3) — Bass | Sub',
      '### Third-party effects (2)',
      '| Channel | Kind | Output | Fader | Inserts | Sends |',
      r'| Bass \| Sub | Instrument | Stereo Out | −6.0 dB | Serum, 1. Pro-Q 3, 3. OTT (off) | Reverb −10.0 dB |',
      '## 1 audio file missing',
      '- Vox.wav — `/old/Vox.wav`',
      '## Notes in the project',
      'Mix for the EP',
      'Made with DAW Project Manager on Oct 30, 2026',
    ]) {
      expect(md.split('\n'), contains(line), reason: line);
    }
  });

  test('a report is in the user\'s language', () {
    final md = inspectorReportMarkdown(
      AppLocalizationsPt(),
      _song,
      now: DateTime(2026, 10, 30),
    );
    expect(md, contains('## Visão geral'));
    expect(md, isNot(contains('Audio files')), reason: 'no media read');
  });

  test('the summary fits a chat message', () {
    expect(
      inspectorSummaryText(l10n, _song, media: _media),
      'Song — Saved with Cubase 13.0.41\n'
      '150 BPM · 4/4 · 48 kHz · A minor\n'
      '2 tracks · Plug-ins: 3 unique · 4 instances\n'
      'Instruments: Serum\n'
      'Third-party effects: Pro-Q 3, OTT ×2\n'
      '1 audio file missing',
    );
  });

  test('the track list CSV: a row per channel, English', () {
    final lines = anatomyTracksCsv(_song).split('\n');
    expect(
      lines[0],
      '﻿channel,kind,folder,output,volume_db,fader_position,pan,muted,'
      'soloed,instrument,instrument_preset,inserts,strip,sends,eq_bands_on',
    );
    expect(
      lines[1],
      'Bass | Sub,instrument,,Stereo Out,-6.0,,-0.30,false,,Serum,,'
      '1. Pro-Q 3; 3. OTT (off),,Reverb -10.0 dB pre,',
    );
    expect(lines[2], 'Reverb,fx,,,,,,,,,,,,,');
  });

  test('the plug-ins CSV: maker, format, role, instances, channels', () {
    final lines = anatomyPluginsCsv(_song).split('\n');
    expect(lines[0], '﻿plugin,vendor,format,role,stock,instances,channels');
    expect(lines[1], 'Serum,Xfer Records,VST3,instrument,false,1,Bass | Sub');
    expect(lines[3], 'OTT,,,effect,false,2,Bass | Sub; Reverb');
  });

  test('a DAW whose channels aren\'t read writes an empty track list', () {
    const flp = ProjectAnatomy(filePath: '/x/a.flp', fileSize: 1);
    expect(anatomyTracksCsv(flp).split('\n').where((l) => l.isNotEmpty),
        hasLength(1));
  });
}
