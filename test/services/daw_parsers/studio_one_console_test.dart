import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/models/project_anatomy.dart';
import 'package:daw_project_manager/services/daw_parsers/studio_one_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/project_anatomy_reader.dart';

/// The console as the Inspector reads it (#228), from a song laid out as
/// real ones are — Studio One 6.6 and 8.1 songs shared on GitHub, checked
/// but without a licence to put them in the collection: the element names,
/// the `x:id`s, gains as linear gains, pans 0–1, connections by UID.
const _metainfo = '''<?xml version="1.0" encoding="UTF-8"?>
<MetaInformation>
	<Attribute id="Document:Generator" value="Studio One/6.6.4.102451"/>
	<Attribute id="Media:SampleRate" value="48000"/>
	<Attribute id="Media:BitDepth" value="24"/>
	<Attribute id="Media:Tempo" value="170"/>
	<Attribute id="Media:TimeSignatureNumerator" value="6"/>
	<Attribute id="Media:TimeSignatureDenominator" value="8"/>
</MetaInformation>''';

String _plugin(
  String slot,
  String name, {
  required String sub,
  String category = 'AudioEffect',
  String? instance,
  String preset = 'Default',
  bool bypass = false,
  bool classInfo = true,
}) =>
    '''
<Attributes name="$slot"${bypass ? ' bypass="1"' : ''}>
  <UID x:id="uniqueID" uid="{33EDE335-9E67-4964-97EC-71F11FB286B2}"/>
  <UID x:id="deviceClassID" uid="{72C4DB71-7A4D-459A-B97E-51745D84B39D}"/>
  <Attributes x:id="deviceData" name="${instance ?? name}"/>
  <Attributes x:id="ghostData" presetType="vstpreset">
    ${classInfo ? '<Attributes x:id="classInfo" classID="{72C4DB71-7A4D-459A-B97E-51745D84B39D}" name="$name" category="$category" subCategory="$sub"/>' : ''}
  </Attributes>
  <Attributes x:id="Presets" pname="$preset" dirty="1"/>
</Attributes>''';

const _out = '{D6F8728E-A356-4426-B48C-991A7C3C4A3D}';
const _bus = '{5496AF91-0BE5-402C-914F-663C21E37C8C}';
const _fx = '{6C7B8872-21F3-4745-AF84-7A0462C9F793}';
const _synth = '{02A73755-52F9-4E65-B232-069FC191886C}';

String _mixer() => '''<?xml version="1.0" encoding="UTF-8"?>
<AudioMixer>
	<Attributes x:id="channels" name="Channels" flags="1">
		<ChannelGroup name="AudioInput" flags="1">
			<AudioInputChannel gain="1" name="Channel01" label="Input L+R">
				<UID x:id="uniqueID" uid="{B033D39F-4C76-4AC4-85DD-48AD7323B266}"/>
			</AudioInputChannel>
		</ChannelGroup>
		<ChannelGroup name="AudioOutput" flags="1">
			<AudioOutputChannel gain="0.70794578438413791" name="Channel01" label="Main" mute="0" solo="0">
				<UID x:id="uniqueID" uid="$_out"/>
				<Attributes x:id="Inserts">
					<Attributes x:id="Presets" pname="Default" dirty="0"/>
				</Attributes>
				<Attributes x:id="PostFaderInserts">
					${_plugin('FX01', 'Limiter', sub: '(Native)/Dynamics')}
				</Attributes>
			</AudioOutputChannel>
		</ChannelGroup>
		<ChannelGroup name="AudioTrack" flags="1">
			<AudioTrackChannel gain="1" pan="0.25" name="Channel01" label="Vox" mute="1" solo="0">
				<UID x:id="uniqueID" uid="{A75B03A1-5951-4D06-81EF-56E2143FB17D}"/>
				<Connection x:id="destination" objectID="$_bus/Input" friendlyName="Old name"/>
				<Attributes x:id="Inserts">
					<Attributes x:id="Presets" pname="Vocal chain" dirty="0"/>
					${_plugin('FX01', 'Pro-Q 3', sub: 'VST3/EQ', instance: 'Pro-Q 3 Vox', preset: 'Air')}
					${_plugin('FX02', 'Decapitator', sub: 'VST3/Distortion', bypass: true)}
					${_plugin('FX03', 'Old Comp', sub: '', classInfo: false)}
					<Attributes x:id="Combinator" name="Combinator">
						<UID x:id="uniqueID" uid="{7F897423-34CA-4066-AB22-5C9E6DB623D9}"/>
					</Attributes>
				</Attributes>
				<Attributes x:id="Sends">
					<Attributes name="Send01" bypass="0" prefader="1" level="0.5" pan="0.5" lockPan="1">
						<UID x:id="uniqueID" uid="{387419AC-820F-4D4E-B10B-CD3648870133}"/>
						<Connection x:id="destination" objectID="$_fx/Input" friendlyName="FX 1"/>
					</Attributes>
					<Attributes name="Send02" bypass="1" prefader="0" level="1" pan="0.5">
						<Connection x:id="destination" objectID="$_out/Input" friendlyName="Main"/>
					</Attributes>
					<Attributes x:id="Presets" pname="Default" dirty="0"/>
				</Attributes>
			</AudioTrackChannel>
		</ChannelGroup>
		<ChannelGroup name="AudioSynth" flags="1">
			<AudioSynthChannel gain="1" pan="0.5" name="Channel01" label="Keys" mute="0" solo="1" synthPort="0">
				<UID x:id="uniqueID" uid="$_synth"/>
				<Connection x:id="destination" objectID="$_out/Input" friendlyName="Main"/>
			</AudioSynthChannel>
		</ChannelGroup>
		<ChannelGroup name="AudioGroup" flags="1">
			<AudioGroupChannel gain="0.5" pan="0.5" name="Channel01" label="Vox Bus" mute="0" solo="0">
				<UID x:id="uniqueID" uid="$_bus"/>
				<Connection x:id="destination" objectID="$_out/Input" friendlyName="Main"/>
			</AudioGroupChannel>
		</ChannelGroup>
		<ChannelGroup name="AudioEffect" flags="1">
			<AudioEffectChannel gain="1" pan="0.5" name="Channel01" label="FX 1" mute="0" solo="0">
				<UID x:id="uniqueID" uid="$_fx"/>
				<Connection x:id="destination" objectID="$_out/Input" friendlyName="Main"/>
				<Attributes x:id="Inserts">
					${_plugin('FX01', 'Little Plate', sub: 'VST3/Reverb')}
				</Attributes>
			</AudioEffectChannel>
		</ChannelGroup>
	</Attributes>
</AudioMixer>''';

const _synthFolder = '''<?xml version="1.0" encoding="UTF-8"?>
<AudioSynthFolder>
	<Attributes name="Inst01" speakerFormat="Stereo">
		<UID x:id="uniqueID" uid="{755CD69A-658C-4737-9AD8-148524B1CBE2}"/>
		<UID x:id="deviceClassID" uid="{3713E26C-2FCA-4024-9F25-17E9D2BE2B9A}"/>
		<Attributes x:id="deviceData" name="Presence"/>
		<Attributes x:id="ghostData" presetType="fxpreset">
			<Attributes x:id="classInfo" classID="{3713E26C-2FCA-4024-9F25-17E9D2BE2B9A}" name="Presence" category="AudioSynth" subCategory="(Native)/Sampler"/>
		</Attributes>
		<Attributes x:id="Presets" pname="Acoustic Piano - Full" dirty="1"/>
		<List x:id="synthChannels">
			<UID uid="$_synth"/>
		</List>
	</Attributes>
	<Attributes x:id="Presets" pname="Default" dirty="0"/>
</AudioSynthFolder>''';

Uint8List _song({bool withMixer = true}) {
  List<int> x(String s) => utf8.encode(s);
  final archive = Archive()
    ..addFile(ArchiveFile.bytes('metainfo.xml', x(_metainfo)))
    ..addFile(ArchiveFile.bytes('Song/song.xml', x('<Song/>')))
    ..addFile(
      ArchiveFile.bytes('Devices/audiosynthfolder.xml', x(_synthFolder)),
    );
  if (withMixer) {
    archive.addFile(ArchiveFile.bytes('Devices/audiomixer.xml', x(_mixer())));
  }
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

void main() {
  final console = StudioOneProjectParser(_song()).readConsole()!;
  StudioOneChannel channel(String name) =>
      console.channels.firstWhere((c) => c.name == name);

  group('readConsole', () {
    test('every channel of the mix, by its label; inputs are not', () {
      expect([for (final c in console.channels) (c.name, c.kind)], [
        ('Main', StudioOneChannelKind.output),
        ('Vox', StudioOneChannelKind.audio),
        ('Keys', StudioOneChannelKind.instrument),
        ('Vox Bus', StudioOneChannelKind.group),
        ('FX 1', StudioOneChannelKind.fx),
      ]);
    });

    test('fader, pan, mute and solo', () {
      expect(channel('Vox').gain, 1);
      expect(channel('Vox').pan, 0.25);
      expect(channel('Vox').muted, isTrue);
      expect(channel('Keys').soloed, isTrue);
      expect(channel('Main').pan, isNull, reason: 'an output has no pan');
    });

    test('a destination is named by the channel it points at, not the name '
        'saved with it', () {
      expect(channel('Vox').destination, 'Vox Bus');
      expect(channel('Vox Bus').destination, 'Main');
    });

    test('inserts: the plug-in, its format, preset and bypass', () {
      final ins = channel('Vox').inserts;
      expect([for (final p in ins) (p.name, p.format, p.bypassed)], [
        ('Pro-Q 3', 'VST3', false),
        ('Decapitator', 'VST3', true),
        ('Old Comp', null, false),
      ], reason: 'no classInfo: the instance name stands in');
      expect(ins[0].preset, 'Air');
      expect(ins[0].classId, '72C4DB717A4D459AB97E51745D84B39D');
      expect(ins[0].native, isFalse);
      expect(ins[2].native, isNull, reason: 'nothing says whose it is');
    });

    test("an output's post-fader inserts count, PreSonus's own as native", () {
      final limiter = channel('Main').inserts.single;
      expect(limiter.name, 'Limiter');
      expect(limiter.native, isTrue);
      expect(limiter.format, isNull);
    });

    test('sends: level, pre-fader, bypass and where they go', () {
      final sends = channel('Vox').sends;
      expect([for (final s in sends) (s.destination, s.level, s.preFader, s.bypassed)], [
        ('FX 1', 0.5, true, false),
        ('Main', 1.0, false, true),
      ]);
    });

    test('an instrument channel carries the instrument playing into it', () {
      final keys = channel('Keys').instrument!;
      expect(keys.name, 'Presence');
      expect(keys.preset, 'Acoustic Piano - Full');
      expect(keys.isInstrument, isTrue);
      expect(keys.native, isTrue);
    });

    test('the song: sample rate, bit depth, time signature', () {
      expect(console.sampleRate, 48000);
      expect(console.bitDepth, 24);
      expect(console.timeSignature, (6, 8));
    });

    test('a song without a console has none to read', () {
      expect(StudioOneProjectParser(_song(withMixer: false)).readConsole(),
          isNull);
    });
  });

  group('studioOneAnatomy', () {
    final a = studioOneAnatomy(filePath: 'Song.song', bytes: _song())!;
    AnatomyChannel ch(String name) =>
        a.channels!.firstWhere((c) => c.name == name);

    test('the output last, as the master', () {
      expect(a.channels!.last.name, 'Main');
      expect(a.channels!.last.kind, AnatomyChannelKind.master);
      expect(ch('Vox Bus').kind, AnatomyChannelKind.group);
      expect(ch('FX 1').kind, AnatomyChannelKind.fx);
    });

    test('gains in dB, pans -1 to 1', () {
      expect(ch('Main').volumeDb, closeTo(-3, 0.01));
      expect(ch('Vox Bus').volumeDb, closeTo(-6.02, 0.01));
      expect(ch('Vox').pan, closeTo(-0.5, 1e-9));
      expect(ch('Vox').inserts[1].deactivated, isTrue);
    });

    test('sends in dB, a bypassed one off', () {
      final s = ch('Vox').sends;
      expect(s[0].levelDb, closeTo(-6.02, 0.01));
      expect(s[0].preFader, isTrue);
      expect(s[1].on, isFalse);
    });

    test('the instrument and its preset on its channel', () {
      expect(ch('Keys').instrument, 'Presence');
      expect(ch('Keys').instrumentPreset, 'Acoustic Piano - Full');
    });

    test("plug-ins: PreSonus's own are stock, the rest by format", () {
      final names = {for (final p in a.plugins) p.name: p};
      expect(names['Presence']?.role, AnatomyPluginRole.instrument);
      expect(names['Presence']?.stock, isTrue);
      expect(names['Presence']?.vendor, 'PreSonus');
      expect(names['Pro-Q 3']?.stock, isFalse);
      expect(names['Pro-Q 3']?.format, 'VST3');
      expect(names['Limiter']?.channels, ['Main']);
      expect(names['Old Comp']?.stock, isNull);
    });

    test('the facts the song keeps', () {
      expect(a.sampleRate, 48000);
      expect(a.bitDepth, 24);
      expect(a.timeSignature, (6, 8));
      expect(a.pluginInstancesKnown, isTrue);
    });
  });

  test('the scan counts buses as real songs name them', () {
    // Studio One 6 and 8 write AudioGroupChannel; reading AudioBusChannel
    // alone counted none.
    expect(StudioOneProjectParser(_song()).read().stats?.busTracks, 2,
        reason: 'one group, one FX channel');
  });
}
