import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/services/project_inspector/compare/anatomy_diff.dart';

AnatomyChannel _ch(
  String name, {
  AnatomyChannelKind kind = AnatomyChannelKind.audio,
  String? output = 'Stereo Out',
  double? volumeDb = 0,
  double? pan = 0,
  bool? muted = false,
  List<AnatomyInsert> inserts = const [],
  List<AnatomySend> sends = const [],
  List<AnatomyStripModule> strip = const [],
  String? instrument,
  String? instrumentPreset,
  String? folder,
}) => AnatomyChannel(
  name: name,
  kind: kind,
  output: output,
  volumeDb: volumeDb,
  pan: pan,
  muted: muted,
  inserts: inserts,
  sends: sends,
  strip: strip,
  instrument: instrument,
  instrumentPreset: instrumentPreset,
  folder: folder,
);

ProjectAnatomy _project(
  List<AnatomyChannel>? channels, {
  double? tempo = 120,
  int? sampleRate = 48000,
  List<AnatomyPlugin> plugins = const [],
}) => ProjectAnatomy(
  filePath: '/x/Song.cpr',
  fileSize: 1,
  tempo: tempo,
  sampleRate: sampleRate,
  timeSignature: (4, 4),
  channels: channels,
  plugins: plugins,
);

List<String> _kinds(List<AnatomyChange> changes) => [
  for (final c in changes) c.kind.name,
];

void main() {
  group('matching channels', () {
    test('by name, in order for a name used twice', () {
      final pairs = matchChannels(
        [_ch('Kick'), _ch('Vox'), _ch('Vox')],
        [_ch('Vox'), _ch('Kick'), _ch('Vox')],
      );
      expect(pairs, {0: 1, 1: 0, 2: 2});
    });

    test('ignoring case after exact names', () {
      expect(matchChannels([_ch('BASS')], [_ch('Bass')]), {0: 0});
    });

    test('renamed: same kind, between the same neighbours', () {
      final a = [
        _ch('Kick'),
        _ch('Audio 01'),
        _ch('Pad', kind: AnatomyChannelKind.instrument),
        _ch('Vox'),
      ];
      final b = [
        _ch('Kick'),
        _ch('Lead Guitar'),
        _ch('Strings', kind: AnatomyChannelKind.instrument),
        _ch('Vox'),
      ];
      expect(matchChannels(a, b), {0: 0, 3: 3, 1: 1, 2: 2});
    });

    test('a different kind in that place is not a rename', () {
      final pairs = matchChannels(
        [_ch('Kick'), _ch('Audio 01'), _ch('Vox')],
        [_ch('Kick'), _ch('FX 1', kind: AnatomyChannelKind.fx), _ch('Vox')],
      );
      expect(pairs.containsKey(1), isFalse);
    });
  });

  test('the project: tempo, sample rate, time signature', () {
    final d = diffAnatomy(
      _project(const [], tempo: 120),
      _project(const [], tempo: 124, sampleRate: 44100),
    );
    expect(
      [for (final c in d.projectChanges) (c.kind, c.before, c.after)],
      [
        (AnatomyChangeKind.tempo, 120.0, 124.0),
        (AnatomyChangeKind.sampleRate, 48000, 44100),
      ],
    );
  });

  test('what one reader leaves null is not compared', () {
    final d = diffAnatomy(
      _project([_ch('Kick', volumeDb: null)], tempo: null),
      _project([_ch('Kick', volumeDb: -6)]),
    );
    expect(d.changeCount, 0);
  });

  test('channels only in A or B, in B order, A ones where they were', () {
    final d = diffAnatomy(
      _project([_ch('Kick'), _ch('Shaker', kind: AnatomyChannelKind.midi), _ch('Vox')]),
      _project([_ch('Kick'), _ch('Vox'), _ch('FX', kind: AnatomyChannelKind.fx)]),
    );
    expect([for (final c in d.channels) c.name], ['Kick', 'Shaker', 'Vox', 'FX']);
    expect(d.onlyInA, 1);
    expect(d.onlyInB, 1);
    expect(d.unchangedChannels, 2);
    expect(d.changedChannels, 0);
    expect(_kinds(d.channels[1].changes), ['channelRemoved']);
    expect(_kinds(d.channels[3].changes), ['channelAdded']);
  });

  test('levels: fader, pan, mute — a move under 0.05 dB is none', () {
    final changes = diffChannel(
      _ch('Vox', volumeDb: -4.0, pan: 0, muted: false),
      _ch('Vox', volumeDb: -11.4, pan: -0.3, muted: true),
    );
    expect(
      [for (final c in changes) (c.kind, c.before, c.after)],
      [
        (AnatomyChangeKind.volume, -4.0, -11.4),
        (AnatomyChangeKind.pan, 0.0, -0.3),
        (AnatomyChangeKind.muted, false, true),
      ],
    );
    expect(diffChannel(_ch('Vox', volumeDb: -4.0), _ch('Vox', volumeDb: -4.04)),
        isEmpty);
    expect(
      diffChannel(
        _ch('Vox', volumeDb: double.negativeInfinity),
        _ch('Vox', volumeDb: -60),
      ),
      hasLength(1),
    );
  });

  test('a fader with no dB compares by its position', () {
    const a = AnatomyChannel(name: 'X', kind: AnatomyChannelKind.audio, faderPosition: 0.5);
    const b = AnatomyChannel(name: 'X', kind: AnatomyChannelKind.audio, faderPosition: 0.7);
    final change = diffChannel(a, b).single;
    expect((change.kind, change.position), (AnatomyChangeKind.volume, true));
  });

  test('routing, folder, rename, kind', () {
    final changes = diffChannel(
      _ch('Audio 01', output: 'Stereo Out', folder: null),
      _ch('Lead', output: 'Guitars', folder: 'Band'),
    );
    expect(_kinds(changes), ['renamed', 'folder', 'output']);
  });

  group('inserts', () {
    AnatomyInsert ins(int slot, String plugin, {bool? off, String? preset}) =>
        AnatomyInsert(slot: slot, plugin: plugin, deactivated: off, preset: preset);

    test('added, removed, replaced in its slot, moved', () {
      final changes = diffInserts(
        [ins(0, 'Pro-Q 3'), ins(1, 'OTT'), ins(2, 'Decapitator')],
        [ins(0, 'Pro-Q 3'), ins(1, 'Saturn 2'), ins(3, 'Decapitator'), ins(5, 'Pro-L 2')],
      );
      expect(
        [for (final c in changes) (c.kind, c.subject, c.slot, c.before, c.after)],
        [
          (AnatomyChangeKind.insertReplaced, null, 1, 'OTT', 'Saturn 2'),
          (AnatomyChangeKind.insertMoved, 'Decapitator', 3, 2, 3),
          (AnatomyChangeKind.insertAdded, 'Pro-L 2', 5, null, null),
        ],
      );
    });

    test('switched off, and a new preset', () {
      final changes = diffInserts(
        [ins(0, 'Pro-Q 3', off: false, preset: 'Default')],
        [ins(0, 'Pro-Q 3', off: true, preset: 'Vocal')],
      );
      expect(
        [for (final c in changes) (c.kind, c.before, c.after)],
        [
          (AnatomyChangeKind.insertSwitched, true, false),
          (AnatomyChangeKind.insertPreset, 'Default', 'Vocal'),
        ],
      );
    });

    test('a plug-in gone from a slot nothing took is removed', () {
      final changes = diffInserts([ins(4, 'OTT')], const []);
      expect(
        [for (final c in changes) (c.kind, c.subject, c.slot)],
        [(AnatomyChangeKind.insertRemoved, 'OTT', 4)],
      );
    });

    test('the same chain is no change', () {
      expect(diffInserts([ins(0, 'OTT'), ins(1, 'OTT')], [ins(0, 'ott'), ins(1, 'OTT')]),
          isEmpty);
    });
  });

  test('instrument swapped, or the same one with another preset', () {
    expect(
      _kinds(diffChannel(
        _ch('Lead', instrument: 'Serum'),
        _ch('Lead', instrument: 'Vital'),
      )),
      ['instrument'],
    );
    final preset = diffChannel(
      _ch('Lead', instrument: 'Serum', instrumentPreset: 'Init'),
      _ch('Lead', instrument: 'Serum', instrumentPreset: 'Big Lead'),
    ).single;
    expect((preset.kind, preset.subject, preset.after),
        (AnatomyChangeKind.instrumentPreset, 'Serum', 'Big Lead'));
  });

  test('strip modules by kind; the EQ never', () {
    AnatomyStripModule m(AnatomyStripKind kind, String plugin, {bool? off}) =>
        AnatomyStripModule(kind: kind, plugin: plugin, deactivated: off);
    final changes = diffChannel(
      _ch('Vox', strip: [
        m(AnatomyStripKind.gate, 'Noise Gate'),
        m(AnatomyStripKind.compressor, 'Standard Compressor', off: false),
        m(AnatomyStripKind.eq, 'EQ'),
      ]),
      _ch('Vox', strip: [
        m(AnatomyStripKind.compressor, 'Vintage Compressor'),
        m(AnatomyStripKind.limiter, 'Standard Limiter'),
      ]),
    );
    expect(
      [for (final c in changes) (c.kind, c.subject ?? c.after)],
      [
        (AnatomyChangeKind.stripReplaced, 'Vintage Compressor'),
        (AnatomyChangeKind.stripAdded, 'Standard Limiter'),
        (AnatomyChangeKind.stripRemoved, 'Noise Gate'),
      ],
    );
  });

  test('sends: added, removed, level, on, pre-fader', () {
    final changes = diffSends(
      const [
        AnatomySend(destination: 'Reverb', levelDb: 12.9),
        AnatomySend(destination: 'Delay', levelDb: -10),
        AnatomySend(destination: 'Bus', levelDb: 0),
      ],
      const [
        AnatomySend(destination: 'Reverb', levelDb: 8.6),
        AnatomySend(destination: 'Delay', levelDb: -10, on: false, preFader: true),
        AnatomySend(destination: 'Comp', sideChainOf: 'Pro-C 2'),
      ],
    );
    expect(
      [for (final c in changes) (c.kind, c.subject, c.before, c.after)],
      [
        (AnatomyChangeKind.sendLevel, 'Reverb', 12.9, 8.6),
        (AnatomyChangeKind.sendSwitched, 'Delay', true, false),
        (AnatomyChangeKind.sendPreFader, 'Delay', false, true),
        (AnatomyChangeKind.sendAdded, 'Comp', null, null),
        (AnatomyChangeKind.sendRemoved, 'Bus', null, null),
      ],
    );
  });

  test('a DAW with no channels read compares the plug-ins in use', () {
    final d = diffAnatomy(
      _project(null, plugins: const [
        AnatomyPlugin(name: 'Serum'),
        AnatomyPlugin(name: 'OTT'),
      ]),
      _project(null, plugins: const [
        AnatomyPlugin(name: 'serum'),
        AnatomyPlugin(name: 'Pro-L 2'),
      ]),
    );
    expect(d.channelsCompared, isFalse);
    expect(
      [for (final c in d.projectChanges) (c.kind, c.subject)],
      [
        (AnatomyChangeKind.pluginRemoved, 'OTT'),
        (AnatomyChangeKind.pluginAdded, 'Pro-L 2'),
      ],
    );
    expect(d.pluginChanges, 2);
  });

  test('totals', () {
    final d = diffAnatomy(
      _project([_ch('Kick'), _ch('Vox', volumeDb: -3), _ch('Old')]),
      _project([_ch('Kick'), _ch('Vox', volumeDb: -6, inserts: const [
        AnatomyInsert(slot: 0, plugin: 'Pro-Q 3'),
      ])]),
    );
    expect(d.changeCount, 3);
    expect(d.changedChannels, 1);
    expect(d.unchangedChannels, 1);
    expect(d.onlyInA, 1);
    expect(d.pluginChanges, 1);
  });
}
