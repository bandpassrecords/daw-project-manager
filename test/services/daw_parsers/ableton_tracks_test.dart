import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

import 'package:daw_project_manager/services/daw_parsers/ableton_devices.dart';
import 'package:daw_project_manager/services/daw_parsers/ableton_project_parser.dart';

/// A Live 9+ parameter: the current value in `Manual`.
String _p(String tag, Object value) =>
    '<$tag><LomId Value="0" /><Manual Value="$value" /></$tag>';

/// A Live 8 parameter: no `Manual`, the value in the first automation
/// event (Live writes it at a huge negative time), a later event after it.
String _p8(String tag, Object value, {Object? later}) =>
    '''
<$tag><LomId Value="0" /><ArrangerAutomation><Events>
  ${later == null ? '' : '<FloatEvent Time="16" Value="$later" />'}
  <FloatEvent Time="-63072000" Value="$value" />
</Events></ArrangerAutomation></$tag>''';

String _routing(String target, String upper, [String lower = '']) =>
    '''
<AudioOutputRouting>
  <Target Value="$target" />
  <UpperDisplayString Value="$upper" />
  <LowerDisplayString Value="$lower" />
</AudioOutputRouting>''';

String _track(
  String element,
  String name, {
  String id = '1',
  String groupId = '-1',
  String output = '',
  String mixer = '',
  String devices = '',
  String chain = 'DeviceChain',
}) =>
    '''
<$element Id="$id">
  <Name><EffectiveName Value="$name" /><UserName Value="" /></Name>
  <TrackGroupId Value="$groupId" />
  <$chain>
    $output
    <Mixer>$mixer</Mixer>
    <DeviceChain><Devices>$devices</Devices></DeviceChain>
  </$chain>
</$element>''';

String _sends(List<(double, bool)> sends) =>
    '<Sends>${[for (final (i, (level, active)) in sends.indexed) '<TrackSendHolder Id="$i">${_p('Send', level)}'
          '<Active Value="$active" /></TrackSendHolder>'].join()}</Sends>';

String _set({
  required String tracks,
  String master = '',
  String sendsPre = '',
}) =>
    '''<?xml version="1.0" encoding="UTF-8"?>
<Ableton MajorVersion="5" MinorVersion="11.0_11202" Creator="Ableton Live 11.2.11">
  <LiveSet>
    <Tracks>$tracks</Tracks>
    $master
    <SendsPre>$sendsPre</SendsPre>
  </LiveSet>
</Ableton>''';

AbletonProjectParser _parse(String xml) =>
    AbletonProjectParser(XmlDocument.parse(xml));

String _vst2(String name, {int id = 1178808944, int category = 1}) =>
    '''
<PluginDevice Id="0">
  ${_p('On', true)}
  <UserName Value="" />
  <PluginDesc><VstPluginInfo Id="0">
    <PlugName Value="$name" /><UniqueId Value="$id" /><Category Value="$category" />
  </VstPluginInfo></PluginDesc>
</PluginDevice>''';

String _vst3(String name, {required int deviceType, bool on = true}) =>
    '''
<PluginDevice Id="0">
  ${_p('On', on)}
  <UserName Value="" />
  <PluginDesc><Vst3PluginInfo Id="0">
    <Name Value="$name" />
    <Uid><Fields.0 Value="-744662167" /><Fields.1 Value="-693157126" />
      <Fields.2 Value="305419896" /><Fields.3 Value="1397572658" /></Uid>
    <DeviceType Value="$deviceType" />
  </Vst3PluginInfo></PluginDesc>
</PluginDevice>''';

String _native(String tag, {bool on = true, String userName = ''}) =>
    '<$tag Id="0">${_p('On', on)}<UserName Value="$userName" /></$tag>';

void main() {
  group('readTracks: the mixer', () {
    test('fader, pan, mute (the track activator) and solo, Live 9+', () {
      final tracks = _parse(
        _set(
          tracks: _track(
            'AudioTrack',
            'Kick',
            output: _routing('AudioOut/Master', 'Master'),
            mixer:
                '${_p('Volume', 0.5011872053)}${_p('Pan', -0.2)}'
                '${_p('Speaker', false)}<SoloSink Value="true" />',
          ),
        ),
      ).readTracks();

      final kick = tracks.single;
      expect(kick.kind, AbletonTrackKind.audio);
      expect(kick.volume, closeTo(0.5011872053, 1e-9)); // −6 dB
      expect(kick.pan, closeTo(-0.2, 1e-9));
      expect(kick.active, isFalse);
      expect(kick.soloed, isTrue);
      expect(kick.outputTarget, 'AudioOut/Master');
    });

    test(
      'Live 8 keeps values in the first automation event, not a later one',
      () {
        // Ben Gold style (Live 8) in the corpus: no Manual anywhere.
        final tracks = _parse(
          _set(
            tracks: _track(
              'AudioTrack',
              'Pad',
              mixer:
                  '${_p8('Volume', 0.8912508488, later: 0.1)}${_p8('Pan', 0.5)}'
                  '''<Speaker><ArrangerAutomation><Events>
                <BoolEvent Time="-63072000" Value="false" />
              </Events></ArrangerAutomation></Speaker>''',
            ),
          ),
        ).readTracks();

        expect(tracks.single.volume, closeTo(0.8912508488, 1e-9));
        expect(tracks.single.pan, 0.5);
        expect(tracks.single.active, isFalse);
      },
    );

    test('a track in a group names it; returns and the master come last', () {
      final tracks = _parse(
        _set(
          tracks: [
            _track('GroupTrack', 'Drums', id: '30'),
            _track('AudioTrack', 'Snare', id: '31', groupId: '30'),
            _track('ReturnTrack', 'A-Reverb', id: '2'),
          ].join(),
          master: _track('MasterTrack', 'Master', id: '0'),
        ),
      ).readTracks();

      expect(
        [for (final t in tracks) (t.name, t.kind, t.group)],
        [
          ('Drums', AbletonTrackKind.group, null),
          ('Snare', AbletonTrackKind.audio, 'Drums'),
          ('A-Reverb', AbletonTrackKind.returnTrack, null),
          ('Master', AbletonTrackKind.master, null),
        ],
      );
    });

    test("Live 8's master keeps its mixer and devices in MasterChain", () {
      final parser = _parse(
        _set(
          tracks: '',
          master: _track(
            'MasterTrack',
            'Master',
            chain: 'MasterChain',
            output: _routing('AudioOut/External/S0', 'Ext. Out', '1/2'),
            mixer: '''<TimeSignature><ArrangerAutomation><Events>
              <EnumEvent Time="-63072000" Value="201" />
            </Events></ArrangerAutomation></TimeSignature>''',
            devices: _native('Limiter'),
          ),
        ),
      );

      final master = parser.readTracks().single;
      expect(master.outputUpper, 'Ext. Out');
      expect(master.devices.single.name, 'Limiter');
      expect(parser.readTimeSignature(), (4, 4));
    });
  });

  group('readTracks: sends', () {
    test('each send is the return in the same place, with SendsPre', () {
      final tracks = _parse(
        _set(
          tracks: [
            _track(
              'AudioTrack',
              'Vox',
              mixer: _sends([(0.25, true), (0.5, false)]),
            ),
            _track('ReturnTrack', 'A-Reverb', id: '2'),
            _track('ReturnTrack', 'B-Delay', id: '3'),
          ].join(),
          sendsPre:
              '<SendPreBool Id="0" Value="true" />'
              '<SendPreBool Id="1" Value="false" />',
        ),
      ).readTracks();

      final sends = tracks.first.sends;
      expect(
        [for (final s in sends) (s.destination, s.level, s.active, s.preFader)],
        [('A-Reverb', 0.25, true, true), ('B-Delay', 0.5, false, false)],
      );
      // A return's own send knobs aren't read.
      expect(tracks[1].sends, isEmpty);
    });
  });

  group('readTracks: devices', () {
    test(
      "Live's devices by the names Live shows; a renamed one keeps both",
      () {
        final devices = _parse(
          _set(
            tracks: _track(
              'AudioTrack',
              'Drums',
              devices: [
                _native('Eq8'),
                _native('Reverb', userName: 'Drums Room'),
                _native('CrossDelay', on: false),
                _native('SomeFutureDevice'),
              ].join(),
            ),
          ),
        ).readTracks().single.devices;

        expect(
          [for (final d in devices) (d.name, d.userName, d.on, d.isPlugin)],
          [
            ('EQ Eight', null, true, false),
            ('Reverb', 'Drums Room', true, false),
            ('Simple Delay', null, false, false),
            ('Some Future Device', null, true, false),
          ],
        );
      },
    );

    test(
      'a VST2: id as hex, category 2 an instrument, anything else an effect',
      () {
        final devices = _parse(
          _set(
            tracks: _track(
              'MidiTrack',
              'Lead',
              devices:
                  _vst2('Sylenth1', id: 875788082, category: 2) +
                  _vst2('FabFilter Pro-Q 2', category: 0),
            ),
          ),
        ).readTracks().single.devices;

        expect(devices[0].format, 'VST2');
        expect(devices[0].pluginId, '34337732'); // 875788082
        expect(devices[0].kind, AbletonDeviceKind.instrument);
        expect(devices[1].kind, AbletonDeviceKind.audioEffect);
      },
    );

    test('a VST3: its class id from the four signed fields, DeviceType 1 an '
        'instrument', () {
      final devices = _parse(
        _set(
          tracks: _track(
            'MidiTrack',
            'Pad',
            devices:
                _vst3('Zebra2', deviceType: 1) +
                _vst3('RBass Stereo', deviceType: 2, on: false),
          ),
        ),
      ).readTracks().single.devices;

      expect(devices[0].format, 'VST3');
      expect(devices[0].pluginId, 'D39D5B69D6AF42FA12345678534D4432');
      expect(devices[0].kind, AbletonDeviceKind.instrument);
      expect(devices[1].kind, AbletonDeviceKind.audioEffect);
      expect(devices[1].on, isFalse);
    });

    test('an Audio Unit: its maker, and aumu as an instrument', () {
      final devices = _parse(
        _set(
          tracks: _track(
            'MidiTrack',
            'Keys',
            devices:
                '''
<AuPluginDevice Id="0"><PluginDesc><AuPluginInfo Id="0">
  <Name Value="Diva" /><Manufacturer Value="u-he" />
  <ComponentType Value="${0x61756D75}" />
</AuPluginInfo></PluginDesc></AuPluginDevice>''',
          ),
        ),
      ).readTracks().single.devices;

      expect(devices.single.format, 'AU');
      expect(devices.single.vendor, 'u-he');
      expect(devices.single.kind, AbletonDeviceKind.instrument);
    });

    test("a rack holds its branches' devices, a rack inside it its own", () {
      final devices = _parse(
        _set(
          tracks: _track(
            'MidiTrack',
            'Stab',
            devices:
                '''
<InstrumentGroupDevice Id="0">
  <UserName Value="5th Stab Lead" />
  <Branches>
    <InstrumentBranch Id="0"><DeviceChain><MidiToAudioDeviceChain><Devices>
      ${_vst2('Sylenth1', category: 2)}
      <AudioEffectGroupDevice Id="1"><Branches><AudioEffectBranch Id="0">
        <DeviceChain><AudioToAudioDeviceChain><Devices>${_native('Saturator')}</Devices>
        </AudioToAudioDeviceChain></DeviceChain>
      </AudioEffectBranch></Branches></AudioEffectGroupDevice>
    </Devices></MidiToAudioDeviceChain></DeviceChain></InstrumentBranch>
  </Branches>
</InstrumentGroupDevice>''',
          ),
        ),
      ).readTracks().single.devices;

      final rack = devices.single;
      expect(
        (rack.name, rack.userName, rack.kind),
        ('Instrument Rack', '5th Stab Lead', AbletonDeviceKind.rack),
      );
      expect(
        [for (final d in rack.nested) d.name],
        ['Sylenth1', 'Audio Effect Rack'],
      );
      expect([for (final d in rack.nested[1].nested) d.name], ['Saturator']);
    });
  });

  group('readTimeSignature', () {
    test('Live writes one number: numerator − 1 + 99 × log2(denominator)', () {
      String master(int v) =>
          _track('MasterTrack', 'Master', mixer: _p('TimeSignature', v));
      expect(
        _parse(_set(tracks: '', master: master(201))).readTimeSignature(),
        (4, 4),
      );
      expect(
        _parse(_set(tracks: '', master: master(303))).readTimeSignature(),
        (7, 8),
      );
      expect(
        _parse(_set(tracks: '', master: master(101))).readTimeSignature(),
        (3, 2),
      );
    });

    test('none, when the set has no master', () {
      expect(_parse(_set(tracks: '')).readTimeSignature(), isNull);
    });
  });
}
