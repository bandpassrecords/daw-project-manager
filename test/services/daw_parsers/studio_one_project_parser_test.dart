import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/daw_parsers/studio_one_project_parser.dart';

Uint8List _song(Map<String, String> files) {
  final archive = Archive();
  for (final e in files.entries) {
    final bytes = utf8.encode(e.value);
    archive.addFile(ArchiveFile(e.key, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _metainfo = '''<?xml version="1.0" encoding="UTF-8"?>
<MetaInformation>
  <Attribute id="Document:Generator" value="Studio One/6.5.1.96553"/>
  <Attribute id="Media:Tempo" value="128"/>
</MetaInformation>''';

const _songXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Song xmlns:x="http://www.presonus.com/x">
  <Attributes x:id="Root">
    <List x:id="Tracks">
      <MediaTrack name="Vox" mediaType="Audio"/>
      <MediaTrack name="Gtr" mediaType="Audio"/>
      <MediaTrack name="Keys" mediaType="Music"/>
      <FolderTrack name="Drums"/>
    </List>
  </Attributes>
</Song>''';

const _mixer = '''<?xml version="1.0" encoding="UTF-8"?>
<AudioMixer>
  <AudioBusChannel name="Drum Bus"/>
  <AudioEffectChannel name="Reverb"/>
  <AudioOutputChannel name="Main"/>
</AudioMixer>''';

void main() {
  test('reads tempo, version and track counts', () {
    final info = StudioOneProjectParser(_song({
      'metainfo.xml': _metainfo,
      'Song/song.xml': _songXml,
      'Devices/audiomixer.xml': _mixer,
    })).read();

    expect(info.bpm, 128);
    expect(info.dawVersion, '6.5');
    final stats = info.stats!;
    expect(stats.audioTracks, 2);
    expect(stats.instrumentTracks, 1);
    expect(stats.folderTracks, 1);
    expect(stats.busTracks, 2, reason: 'the main output is not a bus');
    expect(stats.midiClipCount, isNull, reason: 'clips are not read yet');
  });

  test('a missing document costs only its own values', () {
    final info = StudioOneProjectParser(_song({
      'Song/song.xml': _songXml,
    })).read();
    expect(info.bpm, isNull);
    expect(info.dawVersion, isNull);
    expect(info.stats!.audioTracks, 2);
    expect(info.stats!.busTracks, 0);
  });

  test('a file that is not a zip reads as nothing, not as an error', () {
    final info =
        StudioOneProjectParser(Uint8List.fromList(utf8.encode('nope'))).read();
    expect(info.bpm, isNull);
    expect(info.stats, isNull);
  });
}
