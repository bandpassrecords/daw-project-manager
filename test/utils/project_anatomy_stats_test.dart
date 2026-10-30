import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/utils/project_anatomy_stats.dart';

AnatomyChannel _ch(
  String name, {
  AnatomyChannelKind kind = AnatomyChannelKind.audio,
  String? output = 'Stereo Out',
  List<String> inserts = const [],
  Set<String> off = const {},
  List<AnatomySend> sends = const [],
  double? fader = 0.8,
}) =>
    AnatomyChannel(
      name: name,
      kind: kind,
      output: output,
      faderPosition: fader,
      inserts: [
        for (final (i, plugin) in inserts.indexed)
          AnatomyInsert(slot: i, plugin: plugin, deactivated: off.contains(plugin)),
      ],
      sends: sends,
    );

/// A small mix: drums into a group, vocals with a reverb send and a
/// side-chain into the bass compressor.
final _mix = [
  _ch('Drums', kind: AnatomyChannelKind.folder, output: null, fader: null),
  _ch('Kick', output: 'Drum Bus', inserts: ['EQ', 'Comp', 'Clip']),
  _ch('Snare', output: 'Drum Bus', inserts: ['EQ', 'Comp', 'Clip']),
  _ch('Hats', output: 'Drum Bus', inserts: ['EQ', 'Comp']),
  _ch('Drum Bus', kind: AnatomyChannelKind.group, inserts: ['Glue']),
  _ch('Bass', inserts: ['Comp'], output: 'Stereo Out'),
  _ch('Vox', inserts: ['EQ', 'Comp', 'De-esser'], sends: const [
    AnatomySend(destination: 'Verb', levelDb: -12),
    AnatomySend(destination: 'Bass', sideChainOf: 'Comp'),
  ]),
  _ch('Verb', kind: AnatomyChannelKind.fx, output: 'Stereo Out'),
  _ch('Lost', output: null),
  _ch('Notes', kind: AnatomyChannelKind.midi, output: null, fader: null),
];

void main() {
  test('channel counts by kind', () {
    final counts = channelCounts(_mix);
    expect(counts[AnatomyChannelKind.audio], 6);
    expect(counts[AnatomyChannelKind.group], 1);
    expect(counts[AnatomyChannelKind.fx], 1);
    expect(counts[AnatomyChannelKind.folder], 1);
  });

  test('plug-in instances by role and origin; unknowns kept apart', () {
    final c = pluginInstanceCounts(const [
      AnatomyPlugin(name: 'Serum', role: AnatomyPluginRole.instrument, instances: 2),
      AnatomyPlugin(name: 'Comp', role: AnatomyPluginRole.effect, stock: true, instances: 5),
      AnatomyPlugin(name: 'Pro-Q', role: AnatomyPluginRole.effect, stock: false, instances: 3),
      AnatomyPlugin(name: 'Mystery'),
    ]);
    expect(c.instruments, 2);
    expect(c.stockEffects, 5);
    expect(c.thirdPartyEffects, 3);
    expect(c.unknown, 1, reason: 'a name alone counts once');
  });

  test('most used: by instances, ties by name, names-only left out', () {
    final top = mostUsedPlugins(const [
      AnatomyPlugin(name: 'b', instances: 2),
      AnatomyPlugin(name: 'A', instances: 2),
      AnatomyPlugin(name: 'c', instances: 5),
      AnatomyPlugin(name: 'unknown'),
    ]);
    expect(top.map((p) => p.name), ['c', 'A', 'b']);
  });

  test('usual chains: common runs, most used first, no pieces of longer ones',
      () {
    final chains = [
      for (final (chain, n) in usualChains(_mix)) (chain.join(' > '), n),
    ];
    // EQ > Comp is on four channels, more than the chain it starts, so it
    // stands on its own; Comp > Clip only ever comes inside the longer one.
    expect(chains, [('EQ > Comp', 4), ('EQ > Comp > Clip', 2)]);
  });

  test('a deactivated insert breaks a chain', () {
    final chains = usualChains([
      _ch('A', inserts: ['EQ', 'Comp']),
      _ch('B', inserts: ['EQ', 'Comp'], off: {'Comp'}),
    ]);
    expect(chains, isEmpty);
  });

  test('inserts per channel counts mixer channels, not folders or MIDI', () {
    final counts = insertsPerChannel(_mix);
    expect(counts, {3: 3, 2: 1, 1: 2, 0: 2});
  });

  test('sources of a destination: outputs, sends and side-chains', () {
    final drums = sourcesOf(_mix, 'Drum Bus');
    expect(drums.map((s) => s.channel.name), ['Kick', 'Snare', 'Hats']);
    expect(drums.every((s) => s.via == RoutingVia.output), isTrue);

    final verb = sourcesOf(_mix, 'Verb').single;
    expect((verb.channel.name, verb.via, verb.send!.levelDb),
        ('Vox', RoutingVia.send, -12));

    final bass = sourcesOf(_mix, 'Bass').single;
    expect((bass.channel.name, bass.via), ('Vox', RoutingVia.sideChain));
  });

  test('destinations: busiest first, outputs included', () {
    final d = destinations(_mix);
    expect(d.first.$1, 'Stereo Out');
    expect(d.map((e) => e.$1), containsAll(['Drum Bus', 'Verb', 'Bass']));
    final drumBus = d.firstWhere((e) => e.$1 == 'Drum Bus');
    expect(drumBus.$2, hasLength(3));
  });

  test('signal path follows outputs to the end, and stops on a loop', () {
    expect(signalPath(_mix, 'Kick'), ['Kick', 'Drum Bus', 'Stereo Out']);
    expect(signalPath(_mix, 'Lost'), ['Lost']);
    final loop = [
      _ch('A', output: 'B'),
      _ch('B', output: 'A'),
    ];
    expect(signalPath(loop, 'A'), ['A', 'B']);
  });

  test('hints: channels going nowhere, tracks skipping the buses', () {
    expect(channelsGoingNowhere(_mix).map((c) => c.name), ['Lost'],
        reason: 'a folder or MIDI track has no output to miss');
    expect(channelsSkippingBuses(_mix).map((c) => c.name), ['Bass', 'Vox']);
    expect(channelsSkippingBuses([_ch('Solo')]), isEmpty,
        reason: 'a project with no buses has nothing to skip');
  });

  test('search finds a channel by its name, instrument or a plug-in', () {
    final vox = _mix.firstWhere((c) => c.name == 'Vox');
    expect(channelMatches(vox, 'vo'), isTrue);
    expect(channelMatches(vox, 'de-ess'), isTrue);
    expect(channelMatches(vox, 'glue'), isFalse);
    expect(channelMatches(vox, '  '), isTrue);
    expect(
        channelMatches(
            const AnatomyChannel(
                name: 'Lead',
                kind: AnatomyChannelKind.instrument,
                instrument: 'Serum'),
            'serum'),
        isTrue);
    const stripped = AnatomyChannel(
      name: 'Bass',
      kind: AnatomyChannelKind.audio,
      strip: [
        AnatomyStripModule(kind: AnatomyStripKind.eq, plugin: 'EQ'),
        AnatomyStripModule(
            kind: AnatomyStripKind.saturation, plugin: 'Magneto II'),
      ],
    );
    expect(channelMatches(stripped, 'magneto'), isTrue,
        reason: 'a channel strip module is a plug-in on it');
    expect(channelMatches(stripped, 'eq'), isFalse,
        reason: 'every channel has the EQ');
    expect(pluginMatches(const AnatomyPlugin(name: 'Pro-Q 3'), 'pro'), isTrue);
  });
}
