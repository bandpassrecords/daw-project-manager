import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:daw_project_manager/generated/l10n/app_localizations.dart';
import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/models/sample_reference.dart';
import 'package:daw_project_manager/services/project_inspector/media_check.dart';
import 'package:daw_project_manager/ui/widgets/project_inspector_view.dart';
import 'package:daw_project_manager/utils/localization_delegates.dart';

import '../helpers/semantics_orphans.dart';

const _kick = AnatomyChannel(
  name: 'Kick',
  kind: AnatomyChannelKind.audio,
  output: 'Drum Bus',
  volumeDb: 0,
  faderPosition: 0.79,
  pan: -0.3,
  muted: true,
  inserts: [AnatomyInsert(slot: 0, plugin: 'Pro-Q 3', preset: 'Kick Shape')],
  sends: [AnatomySend(destination: 'Bass', sideChainOf: 'Compressor')],
);

const _cubase = ProjectAnatomy(
  filePath: '/music/Song/Song.cpr',
  fileSize: 18 * 1024 * 1024,
  dawType: 'Cubase',
  savedWith: '13.0.41',
  tempo: 150,
  timeSignature: (4, 4),
  sampleRate: 48000,
  bitDepth: 24,
  pluginInstancesKnown: true,
  channels: [
    _kick,
    AnatomyChannel(
      name: 'Bass',
      kind: AnatomyChannelKind.instrument,
      output: 'Stereo Out',
      instrument: 'Serum',
      faderPosition: 0.5,
      inserts: [AnatomyInsert(slot: 0, plugin: 'Compressor')],
    ),
    AnatomyChannel(
      name: 'Drum Bus',
      kind: AnatomyChannelKind.group,
      output: 'Stereo Out',
      faderPosition: 0.79,
      volumeDb: 0,
    ),
  ],
  plugins: [
    AnatomyPlugin(
      name: 'Pro-Q 3',
      role: AnatomyPluginRole.effect,
      stock: false,
      instances: 1,
      channels: ['Kick'],
      vendor: 'FabFilter',
      format: 'VST3',
    ),
    AnatomyPlugin(
      name: 'Compressor',
      role: AnatomyPluginRole.effect,
      stock: true,
      instances: 1,
      channels: ['Bass'],
    ),
    AnatomyPlugin(
      name: 'Serum',
      role: AnatomyPluginRole.instrument,
      stock: false,
      instances: 1,
      channels: ['Bass'],
    ),
  ],
  media: [],
  audioIo: AnatomyAudioIo(
    driver: 'Studio USB ASIO Driver',
    platform: 'Windows',
    inputBuses: [
      AnatomyBus(name: 'Stereo In', ports: ['Input 1', 'Input 2']),
    ],
    outputBuses: [AnatomyBus(name: 'Stereo Out')],
    midiInputs: ['Studio 24c MIDI In'],
  ),
);

void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();

  group('FlowLayout', () {
    test('three columns, centred on each other, the height of the tallest', () {
      final l = FlowLayout.of(
        sources: 3,
        destinations: 1,
        centerLines: 2,
        width: 1000,
      );
      expect(l.sources, hasLength(3));
      expect(l.destinations, hasLength(1));
      expect(l.sources.first.left, 0);
      expect(l.destinations.single.right, 1000);
      expect(l.center.center.dx, 500);
      // Three boxes stacked set the height; the others centre on them.
      expect(l.height, 3 * FlowLayout.nodeHeight + 2 * FlowLayout.gap);
      expect(l.destinations.single.center.dy, closeTo(l.height / 2, 0.01));
      expect(l.center.center.dy, closeTo(l.height / 2, 0.01));
      // Boxes never overlap.
      for (var i = 1; i < l.sources.length; i++) {
        expect(l.sources[i].top, greaterThanOrEqualTo(l.sources[i - 1].bottom));
      }
    });

    test(
      'a channel nothing feeds still has its place, and a minimum height',
      () {
        final l = FlowLayout.of(
          sources: 0,
          destinations: 1,
          centerLines: 0,
          width: 600,
        );
        expect(l.sources, isEmpty);
        expect(l.height, 120);
      },
    );

    test('a long chain of inserts makes the middle box tall, up to a cap', () {
      final few = FlowLayout.of(
        sources: 1,
        destinations: 1,
        centerLines: 2,
        width: 600,
      );
      final many = FlowLayout.of(
        sources: 1,
        destinations: 1,
        centerLines: 40,
        width: 600,
      );
      expect(many.center.height, greaterThan(few.center.height));
      expect(many.center.height, 64 + FlowLayout.lineHeight * 12);
    });
  });

  test('formatPan prints C, L and R the way DAWs do', () {
    expect(formatPan(0), 'C');
    expect(formatPan(0.004), 'C');
    expect(formatPan(-0.3), 'L30');
    expect(formatPan(1), 'R100');
  });

  Future<List<String>> pump(
    WidgetTester tester,
    ProjectAnatomy anatomy, {
    String search = '',
    List<MediaCheck>? media,
    InspectorSection section = InspectorSection.tracks,
    bool relinkable = false,
  }) async {
    final calls = <String>[];
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProjectInspectorView(
            anatomy: anatomy,
            search: search,
            mediaChecks: media,
            initialSection: section,
            onClose: () => calls.add('close'),
            onReload: () => calls.add('reload'),
            onOpenOther: () => calls.add('open'),
            onRelink: relinkable ? () => calls.add('relink') : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('the header says what saved it, and the tiles the essentials', (
    tester,
  ) async {
    final calls = await pump(tester, _cubase);
    expect(find.text('Song'), findsOneWidget);
    expect(find.text('Saved with Cubase 13.0.41'), findsOneWidget);
    // Values are rich text: the number, then its unit.
    expect(find.text('150 BPM', findRichText: true), findsOneWidget);
    expect(find.text('4/4', findRichText: true), findsOneWidget);
    expect(find.text('48 kHz', findRichText: true), findsOneWidget);
    expect(find.text('24-bit'), findsOneWidget);
    expect(find.text('1 stock · 1 third-party'), findsOneWidget);

    await tester.tap(find.byTooltip('Read again'));
    await tester.tap(find.byTooltip('Close'));
    expect(calls, ['reload', 'close']);
  });

  testWidgets('tracks: a channel opens its routing, inserts and sends', (
    tester,
  ) async {
    await pump(tester, _cubase);
    expect(
      find.text('Select a channel to see its routing and plug-ins.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Kick').first);
    await tester.pumpAndSettle();
    expect(find.text('1. Pro-Q 3 — Kick Shape'), findsOneWidget);
    expect(find.text('L30'), findsOneWidget);
    expect(find.text('Muted'), findsOneWidget);
    expect(find.textContaining('Side-chain into Compressor'), findsOneWidget);
    // Kick → Drum Bus → Stereo Out.
    expect(find.widgetWithText(Chip, 'Stereo Out'), findsOneWidget);
  });

  group('channel strip', () {
    AnatomyChannel vox({bool bypassed = false, bool before = false}) =>
        AnatomyChannel(
          name: 'Vox',
          kind: AnatomyChannelKind.audio,
          output: 'Stereo Out',
          faderPosition: 0.79,
          inserts: const [AnatomyInsert(slot: 0, plugin: 'Pro-Q 3')],
          strip: const [
            AnatomyStripModule(
              kind: AnatomyStripKind.gate,
              plugin: 'Noise Gate',
            ),
            AnatomyStripModule(kind: AnatomyStripKind.eq, plugin: 'EQ'),
            AnatomyStripModule(
              kind: AnatomyStripKind.compressor,
              plugin: 'Tube Compressor',
              deactivated: true,
            ),
          ],
          stripBypassed: bypassed,
          stripBeforeInserts: before,
        );
    ProjectAnatomy project(AnatomyChannel c) => ProjectAnatomy(
      filePath: '/music/Song/Song.cpr',
      fileSize: 1024,
      pluginInstancesKnown: true,
      channels: [_kick, c],
    );
    double top(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    testWidgets('its modules in order after the inserts, the EQ in its place', (
      tester,
    ) async {
      await pump(tester, project(vox(bypassed: true)));
      await tester.tap(find.text('Vox').first);
      await tester.pumpAndSettle();
      expect(find.text('CHANNEL STRIP'), findsOneWidget);
      expect(find.text('Strip bypassed'), findsOneWidget);
      expect(find.text('Gate: Noise Gate'), findsOneWidget);
      expect(find.text('EQ'), findsOneWidget);
      expect(find.text('Compressor: Tube Compressor (off)'), findsOneWidget);
      expect(top(tester, 'Gate: Noise Gate'), lessThan(top(tester, 'EQ')));
      expect(top(tester, 'INSERTS'), lessThan(top(tester, 'CHANNEL STRIP')));

      // A channel with nothing in its strip but the EQ shows none.
      await tester.tap(find.text('Kick').first);
      await tester.pumpAndSettle();
      expect(find.text('CHANNEL STRIP'), findsNothing);
    });

    testWidgets('a strip placed before the inserts is shown before them', (
      tester,
    ) async {
      await pump(tester, project(vox(before: true)));
      await tester.tap(find.text('Vox').first);
      await tester.pumpAndSettle();
      expect(find.text('Before the inserts'), findsOneWidget);
      expect(top(tester, 'CHANNEL STRIP'), lessThan(top(tester, 'INSERTS')));
    });

    testWidgets("signal flow lists a strip's modules unless it is bypassed", (
      tester,
    ) async {
      Finder inDiagram(String text) =>
          find.descendant(of: find.byType(Stack), matching: find.text(text));
      await pump(tester, project(vox()), section: InspectorSection.routing);
      await tester.tap(find.text('Vox').first);
      await tester.pumpAndSettle();
      expect(inDiagram('Gate: Noise Gate'), findsOneWidget);
      expect(inDiagram('EQ'), findsNothing, reason: 'every channel has it');

      await pump(
        tester,
        project(vox(bypassed: true)),
        section: InspectorSection.routing,
      );
      await tester.tap(find.text('Vox').first);
      await tester.pumpAndSettle();
      expect(inDiagram('Gate: Noise Gate'), findsNothing);
    });

    testWidgets('the search box finds a channel by a strip module', (
      tester,
    ) async {
      await pump(tester, project(vox()), search: 'noise');
      expect(find.text('Vox'), findsOneWidget);
      expect(find.text('Kick'), findsNothing);
    });
  });

  testWidgets('the search box finds channels by a plug-in on them', (
    tester,
  ) async {
    await pump(tester, _cubase, search: 'pro-q');
    expect(find.text('Kick'), findsOneWidget);
    expect(find.text('Bass'), findsNothing);
  });

  testWidgets('a kind filter keeps only that kind', (tester) async {
    await pump(tester, _cubase);
    await tester.tap(find.text('Group 1'));
    await tester.pumpAndSettle();
    expect(find.text('Drum Bus'), findsWidgets);
    expect(find.text('Kick'), findsNothing);
  });

  testWidgets('plug-ins are grouped by what they are', (tester) async {
    await pump(tester, _cubase, section: InspectorSection.plugins);
    expect(find.text('Instruments (1)'), findsOneWidget);
    expect(find.text('Stock effects (1)'), findsOneWidget);
    expect(find.text('Third-party effects (1)'), findsOneWidget);
    expect(find.text('3 unique · 3 instances'), findsOneWidget);
    expect(find.text('FabFilter · VST3'), findsOneWidget);
  });

  testWidgets(
    'signal flow draws the channel, what feeds it and where it goes',
    (tester) async {
      await pump(tester, _cubase, section: InspectorSection.routing);
      await tester.tap(find.text('Drum Bus').first);
      await tester.pumpAndSettle();
      // Kick feeds the bus; the bus goes to Stereo Out.
      expect(
        find.descendant(of: find.byType(Stack), matching: find.text('Kick')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(Stack),
          matching: find.text('Stereo Out'),
        ),
        findsOneWidget,
      );
      // A box that is a channel opens it.
      await tester.tap(
        find.descendant(of: find.byType(Stack), matching: find.text('Kick')),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Side-chain into Compressor'),
        findsWidgets,
        reason: "now Kick's flow: its side-chain send into Bass",
      );
    },
  );

  testWidgets('routing by destination lists what feeds each bus', (
    tester,
  ) async {
    await pump(tester, _cubase, section: InspectorSection.routing);
    await tester.tap(find.text('By destination'));
    await tester.pumpAndSettle();
    // Its own card, and a source of Stereo Out.
    expect(find.text('Drum Bus'), findsNWidgets(2));
    expect(
      find.text('Bass (Side-chain)'),
      findsNothing,
      reason: 'the side-chain feeds Bass, listed under Bass',
    );
    expect(find.text('Kick (Side-chain)'), findsOneWidget);
  });

  testWidgets('audio files: missing ones first, with a summary', (
    tester,
  ) async {
    const kick = SampleReference(
      fileName: 'Kick.wav',
      candidates: ['/a/Kick.wav'],
    );
    const snare = SampleReference(
      fileName: 'Snare.wav',
      candidates: ['/a/Snare.wav'],
    );
    await pump(
      tester,
      _cubase,
      section: InspectorSection.media,
      media: const [
        MediaCheck(kick, MediaStatus.found, path: '/a/Kick.wav'),
        MediaCheck(snare, MediaStatus.missing),
      ],
    );
    expect(find.text('1 of 2 missing'), findsOneWidget);
    final kickY = tester.getTopLeft(find.text('Kick.wav')).dy;
    final snareY = tester.getTopLeft(find.text('Snare.wav')).dy;
    expect(snareY, lessThan(kickY));
    expect(find.text('Fix missing files…'), findsNothing,
        reason: "this DAW's projects can't be relinked");
  });

  testWidgets('missing files offer a fix where the format can be relinked', (
    tester,
  ) async {
    const snare = SampleReference(
      fileName: 'Snare.wav',
      candidates: ['/a/Snare.wav'],
    );
    const pad = SampleReference(
      fileName: 'Pad.wav',
      candidates: ['/a/Pad.wav'],
      use: SampleUse.plugin,
    );
    var calls = await pump(
      tester,
      _cubase,
      section: InspectorSection.media,
      relinkable: true,
      media: const [MediaCheck(snare, MediaStatus.missing)],
    );
    await tester.tap(find.text('Fix missing files…'));
    expect(calls, ['relink']);

    calls = await pump(
      tester,
      _cubase,
      section: InspectorSection.media,
      relinkable: true,
      media: const [MediaCheck(pad, MediaStatus.missing)],
    );
    expect(find.text('Fix missing files…'), findsNothing,
        reason: "a path in a plug-in's state isn't the project's to rewrite");
  });

  testWidgets('audio I/O: the driver, where it was saved, buses and ports', (
    tester,
  ) async {
    await pump(tester, _cubase, section: InspectorSection.audioIo);
    expect(
      find.text('Studio USB ASIO Driver', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Saved on Windows'), findsOneWidget);
    expect(find.text('Stereo In'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Input 2'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Studio 24c MIDI In'), findsOneWidget);
    expect(
      find.text('None'),
      findsWidgets,
      reason: 'no MIDI outputs, and Stereo Out with no ports',
    );
  });

  testWidgets('a DAW whose channels are not read says so', (tester) async {
    const reaper = ProjectAnatomy(
      filePath: '/music/Song.rpp',
      fileSize: 1000,
      dawType: 'REAPER',
      plugins: [AnatomyPlugin(name: 'ReaEQ')],
    );
    await pump(tester, reaper);
    expect(find.text('Not read for REAPER projects yet.'), findsOneWidget);
    await tester.tap(find.text('Plug-ins'));
    await tester.pumpAndSettle();
    expect(find.text('ReaEQ'), findsOneWidget);
    expect(find.textContaining("isn't read for REAPER"), findsOneWidget);
    await tester.tap(find.text('Audio files'));
    await tester.pumpAndSettle();
    expect(find.text('Not read for REAPER projects yet.'), findsOneWidget);
  });

  testWidgets('statistics show without throwing on every card', (tester) async {
    await pump(tester, _cubase, section: InspectorSection.statistics);
    expect(find.text('Track types'), findsOneWidget);
    expect(find.text('Most used plug-ins'), findsOneWidget);
    expect(
      find.text('No chain of plug-ins repeats across channels.'),
      findsOneWidget,
    );
  });

  testWidgets('every tooltip shows with no node Windows rejects', (
    tester,
  ) async {
    binding.resetSemanticsRecord();
    final handle = tester.ensureSemantics();
    await pump(tester, _cubase);
    await tester.tap(find.text('Bass').first);
    await tester.pumpAndSettle();
    expect(binding.orphans, isEmpty);
    expect(await expectNoOrphanSemanticsWhileHovering(tester), greaterThan(2));
    handle.dispose();
  });
}
