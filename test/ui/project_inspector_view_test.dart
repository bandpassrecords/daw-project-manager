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
  inserts: [AnatomyInsert(slot: 0, plugin: 'Pro-Q 3', preset: 'Kick Shape')],
  sends: [
    AnatomySend(destination: 'Bass', sideChainOf: 'Compressor'),
  ],
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
    inputBuses: [AnatomyBus(name: 'Stereo In', ports: ['Input 1', 'Input 2'])],
    outputBuses: [AnatomyBus(name: 'Stereo Out')],
    midiInputs: ['Studio 24c MIDI In'],
  ),
);

void main() {
  final binding = SemanticsOrphanBinding.ensureInitialized();

  Future<List<String>> pump(
    WidgetTester tester,
    ProjectAnatomy anatomy, {
    String search = '',
    List<MediaCheck>? media,
    InspectorSection section = InspectorSection.tracks,
  }) async {
    final calls = <String>[];
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
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
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return calls;
  }

  testWidgets('the header says what saved it, and the tiles the essentials',
      (tester) async {
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

  testWidgets('tracks: a channel opens its routing, inserts and sends',
      (tester) async {
    await pump(tester, _cubase);
    expect(find.text('Select a channel to see its routing and plug-ins.'),
        findsOneWidget);
    await tester.tap(find.text('Kick').first);
    await tester.pumpAndSettle();
    expect(find.text('1. Pro-Q 3 — Kick Shape'), findsOneWidget);
    expect(find.textContaining('Side-chain into Compressor'), findsOneWidget);
    // Kick → Drum Bus → Stereo Out.
    expect(find.widgetWithText(Chip, 'Stereo Out'), findsOneWidget);
  });

  testWidgets('the search box finds channels by a plug-in on them',
      (tester) async {
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

  testWidgets('routing by destination lists what feeds each bus',
      (tester) async {
    await pump(tester, _cubase, section: InspectorSection.routing);
    await tester.tap(find.text('By destination'));
    await tester.pumpAndSettle();
    // Its own card, and a source of Stereo Out.
    expect(find.text('Drum Bus'), findsNWidgets(2));
    expect(find.text('Bass (Side-chain)'), findsNothing,
        reason: 'the side-chain feeds Bass, listed under Bass');
    expect(find.text('Kick (Side-chain)'), findsOneWidget);
  });

  testWidgets('audio files: missing ones first, with a summary',
      (tester) async {
    const kick = SampleReference(fileName: 'Kick.wav', candidates: ['/a/Kick.wav']);
    const snare =
        SampleReference(fileName: 'Snare.wav', candidates: ['/a/Snare.wav']);
    await pump(tester, _cubase, section: InspectorSection.media, media: const [
      MediaCheck(kick, MediaStatus.found, path: '/a/Kick.wav'),
      MediaCheck(snare, MediaStatus.missing),
    ]);
    expect(find.text('1 of 2 missing'), findsOneWidget);
    final kickY = tester.getTopLeft(find.text('Kick.wav')).dy;
    final snareY = tester.getTopLeft(find.text('Snare.wav')).dy;
    expect(snareY, lessThan(kickY));
  });

  testWidgets('audio I/O: the driver, where it was saved, buses and ports',
      (tester) async {
    await pump(tester, _cubase, section: InspectorSection.audioIo);
    expect(find.text('Studio USB ASIO Driver', findRichText: true),
        findsOneWidget);
    expect(find.text('Saved on Windows'), findsOneWidget);
    expect(find.text('Stereo In'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Input 2'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'Studio 24c MIDI In'), findsOneWidget);
    expect(find.text('None'), findsWidgets,
        reason: 'no MIDI outputs, and Stereo Out with no ports');
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

  testWidgets('statistics show without throwing on every card',
      (tester) async {
    await pump(tester, _cubase, section: InspectorSection.statistics);
    expect(find.text('Track types'), findsOneWidget);
    expect(find.text('Most used plug-ins'), findsOneWidget);
    expect(find.text('No chain of plug-ins repeats across channels.'),
        findsOneWidget);
  });

  testWidgets('every tooltip shows with no node Windows rejects',
      (tester) async {
    binding.resetSemanticsRecord();
    final handle = tester.ensureSemantics();
    await pump(tester, _cubase);
    await tester.tap(find.text('Bass').first);
    await tester.pumpAndSettle();
    expect(binding.orphans, isEmpty);
    expect(await expectNoOrphanSemanticsWhileHovering(tester),
        greaterThan(2));
    handle.dispose();
  });
}
