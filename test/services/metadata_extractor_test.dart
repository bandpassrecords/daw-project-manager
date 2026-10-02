import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daw_project_manager/services/metadata_extractor.dart';

void main() {
  // _getDawTypeFromExtension is private; exercise it via the public
  // extractLightweightMetadata method which delegates to it immediately.
  // The method does not open or read the file, so a fake path is fine.
  Future<String?> dawTypeFor(String ext) async {
    final m = await MetadataExtractor.extractLightweightMetadata('/fake/project$ext');
    return m.dawType;
  }

  group('MetadataExtractor — DAW type detection from extension', () {
    test('.als → Ableton Live', () async {
      expect(await dawTypeFor('.als'), 'Ableton Live');
    });

    test('.alp → Ableton Live', () async {
      expect(await dawTypeFor('.alp'), 'Ableton Live');
    });

    test('.bwproject → Bitwig Studio', () async {
      expect(await dawTypeFor('.bwproject'), 'Bitwig Studio');
    });

    test('.cpr → Cubase', () async {
      expect(await dawTypeFor('.cpr'), 'Cubase');
    });

    test('.flp → FL Studio', () async {
      expect(await dawTypeFor('.flp'), 'FL Studio');
    });

    test('.logicx → Logic Pro', () async {
      expect(await dawTypeFor('.logicx'), 'Logic Pro');
    });

    test('.maschine → Maschine', () async {
      expect(await dawTypeFor('.maschine'), 'Maschine');
    });

    test('.maschine2 → Maschine', () async {
      expect(await dawTypeFor('.maschine2'), 'Maschine');
    });

    test('.npr → Nuendo', () async {
      expect(await dawTypeFor('.npr'), 'Nuendo');
    });

    test('.ptx → Pro Tools', () async {
      expect(await dawTypeFor('.ptx'), 'Pro Tools');
    });

    test('.pts → Pro Tools', () async {
      expect(await dawTypeFor('.pts'), 'Pro Tools');
    });

    test('.rpp → Reaper', () async {
      expect(await dawTypeFor('.rpp'), 'Reaper');
    });

    test('.song → Studio One', () async {
      expect(await dawTypeFor('.song'), 'Studio One');
    });

    test('.tracktionedit → Waveform', () async {
      expect(await dawTypeFor('.tracktionedit'), 'Waveform');
    });

    test('.tracktion → Waveform', () async {
      expect(await dawTypeFor('.tracktion'), 'Waveform');
    });

    test('.cwp → Sonar', () async {
      expect(await dawTypeFor('.cwp'), 'Sonar');
    });

    test('.wrk → Sonar', () async {
      expect(await dawTypeFor('.wrk'), 'Sonar');
    });

    test('.bun → Sonar', () async {
      expect(await dawTypeFor('.bun'), 'Sonar');
    });

    test('.luna → LUNA', () async {
      expect(await dawTypeFor('.luna'), 'LUNA');
    });

    test('.mgd → MAGDA', () async {
      expect(await dawTypeFor('.mgd'), 'MAGDA');
    });

    test('.ardour → Ardour', () async {
      expect(await dawTypeFor('.ardour'), 'Ardour');
    });

    test('.band → GarageBand', () async {
      expect(await dawTypeFor('.band'), 'GarageBand');
    });

    test('.xrns → Renoise', () async {
      expect(await dawTypeFor('.xrns'), 'Renoise');
    });

    test('.mmp → LMMS', () async {
      expect(await dawTypeFor('.mmp'), 'LMMS');
    });

    test('.mmpz → LMMS', () async {
      expect(await dawTypeFor('.mmpz'), 'LMMS');
    });

    test('.aup3 → Audacity', () async {
      expect(await dawTypeFor('.aup3'), 'Audacity');
    });

    test('.qtr → Qtractor', () async {
      expect(await dawTypeFor('.qtr'), 'Qtractor');
    });

    test('.rg → Rosegarden', () async {
      expect(await dawTypeFor('.rg'), 'Rosegarden');
    });

    test('.reason → Reason', () async {
      expect(await dawTypeFor('.reason'), 'Reason');
    });

    test('.rns → Reason', () async {
      expect(await dawTypeFor('.rns'), 'Reason');
    });

    test('.dpproj → Digital Performer', () async {
      expect(await dawTypeFor('.dpproj'), 'Digital Performer');
    });

    test('.sesx → Adobe Audition', () async {
      expect(await dawTypeFor('.sesx'), 'Adobe Audition');
    });

    test('.vip → Samplitude / Sequoia', () async {
      expect(await dawTypeFor('.vip'), 'Samplitude / Sequoia');
    });

    test('.acd → ACID Pro', () async {
      expect(await dawTypeFor('.acd'), 'ACID Pro');
    });

    test('.mx8 → Mixcraft', () async {
      expect(await dawTypeFor('.mx8'), 'Mixcraft');
    });

    test('.mx9 → Mixcraft', () async {
      expect(await dawTypeFor('.mx9'), 'Mixcraft');
    });

    test('.mx10 → Mixcraft', () async {
      expect(await dawTypeFor('.mx10'), 'Mixcraft');
    });

    test('.zpj → Zrythm', () async {
      expect(await dawTypeFor('.zpj'), 'Zrythm');
    });

    test('unknown extension → null', () async {
      expect(await dawTypeFor('.unknown'), isNull);
    });

    test('no extension → null', () async {
      expect(await dawTypeFor(''), isNull);
    });

    test('extension matching is case-insensitive', () async {
      final m = await MetadataExtractor.extractLightweightMetadata('/fake/PROJECT.ALS');
      expect(m.dawType, 'Ableton Live');
    });

    test('returns null BPM and key from lightweight extraction', () async {
      final m = await MetadataExtractor.extractLightweightMetadata('/fake/project.als');
      expect(m.bpm, isNull);
      expect(m.key, isNull);
      expect(m.dawVersion, isNull);
    });
  });

  group('MetadataExtractor — Reaper (.rpp) full extraction', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rpp_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('extracts version, BPM, and key signature from Reaper text project files', () async {
      final file = File('${tempDir.path}/project.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
<KEYSIG
  0 11 1 0x4E9
>
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.dawType, 'Reaper');
      expect(metadata.bpm, 120.0);
      expect(metadata.key, 'B Blues Minor');
      expect(metadata.dawVersion, '7.78');
    });

    test('extracts major and minor Reaper scale values from the text signature block', () async {
      final majorFile = File('${tempDir.path}/project_major.rpp');
      await majorFile.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
<KEYSIG
  0 11 1 0x0AB5
>
''');

      final majorMetadata = await MetadataExtractor.extractMetadata(majorFile.path);
      expect(majorMetadata.key, 'B Major');

      final minorFile = File('${tempDir.path}/project_minor.rpp');
      await minorFile.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
<KEYSIG
  0 0 -1 0x05AD
>
''');

      final minorMetadata = await MetadataExtractor.extractMetadata(minorFile.path);
      expect(minorMetadata.key, 'C Minor');
    });

    test('accepts both integer and decimal Reaper tempo values', () async {
      final integerFile = File('${tempDir.path}/project_integer.rpp');
      await integerFile.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
''');

      final integerMetadata = await MetadataExtractor.extractMetadata(integerFile.path);
      expect(integerMetadata.bpm, 120.0);

      final decimalFile = File('${tempDir.path}/project_decimal.rpp');
      await decimalFile.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120.2 4 4 0
''');

      final decimalMetadata = await MetadataExtractor.extractMetadata(decimalFile.path);
      expect(decimalMetadata.bpm, 120.2);
    });

    test('resolves a Reaper scale mask from the same 12-slot bit pattern methodology used by the .reascale file', () async {
      final file = File('${tempDir.path}/project_scale_mask.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
<KEYSIG
  0 0 0 0x0295
>
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.key, 'C Major Pentatonic');
    });

    test('resolves a scale mask beyond Bitwig\'s original 23, sourced from the expanded '
        '.reascale-derived table', () async {
      // 0x0d39 ("Chromatic Phrygian") is not one of Bitwig's 23 scale types —
      // before the scale table was expanded from ZD-complete.reascale, this
      // mask fell through to a null key entirely.
      final file = File('${tempDir.path}/project_expanded_scale_mask.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
<KEYSIG
  0 0 0 0x0d39
>
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.key, 'C Chromatic Phrygian');
    });

    test('matches only the whole TEMPO token, not TEMPOENVLOCKMODE', () async {
      final file = File('${tempDir.path}/project_tempoenvlock.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPOENVLOCKMODE 1
TEMPO 120 4 4 0
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.bpm, 120.0);
    });

    test('extracts Title, Author and Notes into a single combined projectNotes string', () async {
      final file = File('${tempDir.path}/project_notes.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  TITLE "Notes 1"
  AUTHOR "Audio Crawler"
  <NOTES 0 2
    |This is notes of the project to be displayed in DAW Project Manager
    |
    |Multiple lines
    |
    |1
    |
    |2
    |
    |Test
  >
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      // No "by "-style connector: this string is persisted to Hive and
      // synced to Drive, so it must not bake in an English word — see the
      // comment in _extractReaperNotes. Title and author are joined by an
      // em dash instead, since that's punctuation rather than a word.
      expect(
        metadata.projectNotes,
        'Notes 1 — Audio Crawler\n'
        '\n'
        'This is notes of the project to be displayed in DAW Project Manager\n'
        '\n'
        'Multiple lines\n'
        '\n'
        '1\n'
        '\n'
        '2\n'
        '\n'
        'Test',
      );
    });

    test('joins Title and Author with an em dash on one line when both are present', () async {
      final file = File('${tempDir.path}/project_title_author.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  TITLE "My Song"
  AUTHOR "Jane Doe"
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.projectNotes, 'My Song — Jane Doe\n');
    });

    test('projectNotes shows just the title when Author is absent', () async {
      final file = File('${tempDir.path}/project_title_only.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  TITLE "My Song"
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.projectNotes, 'My Song\n');
    });

    test('projectNotes shows just the author when Title is absent', () async {
      final file = File('${tempDir.path}/project_author_only.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  AUTHOR "Jane Doe"
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.projectNotes, 'Jane Doe\n');
    });

    test('projectNotes is null when there is no NOTES/TITLE/AUTHOR block', () async {
      final file = File('${tempDir.path}/project_no_notes.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
TEMPO 120 4 4 0
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.projectNotes, isNull);
    });

    test('projectNotes falls back to just the notes body when TITLE/AUTHOR are absent', () async {
      final file = File('${tempDir.path}/project_notes_only.rpp');
      await file.writeAsString('''
<REAPER_PROJECT 0.1 "7.78/win64" 1784823281 0
  <NOTES 0 2
    |Just a quick note
  >
''');

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.projectNotes, 'Just a quick note');
    });
  });

  group('MetadataExtractor — Cubase/Nuendo (.cpr/.npr) project notes', () {
    // Cubase/Nuendo serialize named attributes as length-prefixed "Pascal
    // strings": a 4-byte big-endian length (counting the trailing null
    // terminator), the ASCII name, then a null terminator. The Notepad
    // panel writes a `Cursor` attribute (11 bytes: 4-byte type marker + an
    // 8-byte cursor position) always, and a `Text` attribute (2-byte type
    // code 0x0008 + 4-byte big-endian byte length + raw text) only when
    // notes are non-empty. Reverse-engineered against 40+ real project
    // files — see the comment on MetadataExtractor._extractCubaseNotes.
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cpr_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    List<int> pstring(String s) {
      final withNull = [...utf8.encode(s), 0x00];
      final length = withNull.length;
      return [
        (length >> 24) & 0xFF, (length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF,
        ...withNull,
      ];
    }

    List<int> cursorField() => [
          ...pstring('Cursor'),
          0x00, 0x01, // type code (int64)
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // 8-byte cursor position
        ];

    List<int> textField(List<int> rawTextBytes) {
      final length = rawTextBytes.length;
      return [
        ...pstring('Text'),
        0x00, 0x08, // type code
        (length >> 24) & 0xFF, (length >> 16) & 0xFF, (length >> 8) & 0xFF, length & 0xFF,
        ...rawTextBytes,
      ];
    }

    Future<String> writeCprFixture(List<int> body, {String ext = '.cpr'}) async {
      final file = File('${tempDir.path}/project$ext');
      await file.writeAsBytes([
        ...utf8.encode('daPN'), // Project Notes panel tag (not itself parsed)
        ...body,
        ...utf8.encode('trailing project data'),
      ]);
      return file.path;
    }

    test('extracts the Notepad Text field and normalizes CRLF to LF', () async {
      final path = await writeCprFixture([
        ...cursorField(),
        ...textField(utf8.encode('Line one\r\nLine two')),
      ]);

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.dawType, 'Cubase');
      expect(metadata.projectNotes, 'Line one\nLine two');
    });

    test('extracts notes from a Nuendo (.npr) project the same way', () async {
      final path = await writeCprFixture(
        [...cursorField(), ...textField(utf8.encode('Nuendo notes'))],
        ext: '.npr',
      );

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.dawType, 'Nuendo');
      expect(metadata.projectNotes, 'Nuendo notes');
    });

    test('strips a trailing null byte and UTF-8 BOM padding inside the declared text length', () async {
      final path = await writeCprFixture([
        ...cursorField(),
        ...textField([...utf8.encode('Short note'), 0x00, 0xEF, 0xBB, 0xBF]),
      ]);

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.projectNotes, 'Short note');
    });

    test('finds the Notepad Text field even when an earlier unrelated Cursor-bearing '
        'panel has no Text of its own', () async {
      final path = await writeCprFixture([
        ...cursorField(), // e.g. some other panel's editor-cursor state
        ...utf8.encode('someOtherPanelObject'),
        ...cursorField(), // the actual Notepad panel's Cursor
        ...textField(utf8.encode('Real notes here')),
      ]);

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.projectNotes, 'Real notes here');
    });

    test('projectNotes is null when the Notepad panel has no Text field (empty notes)', () async {
      final path = await writeCprFixture([
        ...cursorField(),
        ...utf8.encode('iCVT'), // next object Cubase writes right after an empty notepad
      ]);

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.projectNotes, isNull);
    });

    test('projectNotes is null for a project file with no Notepad panel at all', () async {
      final path = await writeCprFixture(utf8.encode('no notepad data in this project'));

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.projectNotes, isNull);
    });
  });

  group('MetadataExtractor — MAGDA (.mgd) full extraction', () {
    // .mgd files are a single zlib-compressed (RFC 1950) JSON document with a
    // top-level `magdaVersion` and a `project` object holding `tempo`,
    // `keyRoot` (0=C..11=B, -1=none) and `keyQuality` (0=major, 1=minor).
    // Verified against a real project file exported by MAGDA 0.15.0.
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('mgd_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    Future<String> writeMgdFixture(Map<String, dynamic> json) async {
      final file = File('${tempDir.path}/project.mgd');
      final compressed = zlib.encode(utf8.encode(jsonEncode(json)));
      await file.writeAsBytes(compressed);
      return file.path;
    }

    test('extracts BPM, key, and major DAW version', () async {
      final path = await writeMgdFixture({
        'magdaVersion': '0.15.0',
        'project': {
          'tempo': 125.0,
          'keyRoot': 1, // C#/Db
          'keyQuality': 0, // Major
        },
      });

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.dawType, 'MAGDA');
      expect(metadata.bpm, 125.0);
      expect(metadata.key, 'C#/Db Major');
      expect(metadata.dawVersion, '0.15');
    });

    test('minor key quality', () async {
      final path = await writeMgdFixture({
        'magdaVersion': '0.15.0',
        'project': {'tempo': 90.0, 'keyRoot': 9, 'keyQuality': 1},
      });

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.key, 'A Minor');
    });

    test('keyRoot -1 means no key set', () async {
      final path = await writeMgdFixture({
        'magdaVersion': '0.15.0',
        'project': {'tempo': 120.0, 'keyRoot': -1, 'keyQuality': 0},
      });

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.key, isNull);
      expect(metadata.bpm, 120.0);
    });

    test('malformed file returns empty metadata instead of throwing', () async {
      final file = File('${tempDir.path}/broken.mgd');
      await file.writeAsBytes([0x00, 0x01, 0x02]);

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.bpm, isNull);
      expect(metadata.key, isNull);
      expect(metadata.dawVersion, isNull);
      expect(metadata.dawType, 'MAGDA');
    });

    test('missing file returns empty metadata', () async {
      final metadata =
          await MetadataExtractor.extractMetadata('${tempDir.path}/missing.mgd');
      expect(metadata.bpm, isNull);
      expect(metadata.key, isNull);
      expect(metadata.dawVersion, isNull);
    });
  });

  group('MetadataExtractor — Ableton Live (.als) full extraction', () {
    // .als files are gzipped XML. The root <Ableton> element's Creator
    // attribute (e.g. "Ableton Live 12.3") carries the real major.minor
    // version — MinorVersion (e.g. "12.0_12300") does not reflect it.
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('als_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    Future<String> writeAlsFixture(String xml) async {
      final file = File('${tempDir.path}/project.als');
      final compressed = gzip.encode(utf8.encode(xml));
      await file.writeAsBytes(compressed);
      return file.path;
    }

    test('extracts major.minor DAW version from the Creator attribute', () async {
      final path = await writeAlsFixture('''
<?xml version="1.0" encoding="UTF-8"?>
<Ableton MajorVersion="5" MinorVersion="12.0_12300" SchemaChangeCount="1" Creator="Ableton Live 12.3" Revision="49ca8995cfdbe384bd4648a2e0d5a14dba7b993d">
	<LiveSet>
		<Tracks>
		</Tracks>
	</LiveSet>
</Ableton>
''');

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.dawType, 'Ableton Live');
      expect(metadata.dawVersion, '12.3');
    });

    test('ignores a misleading MinorVersion suffix when Creator disagrees', () async {
      // Real sample from an older project: MinorVersion's "9.0_305" suffix
      // does not encode "9.1.7" in any way (unlike the 12.3 fixture above,
      // where "12300" coincidentally lines up with "12.3") — Creator must
      // always win, never a parse of the MinorVersion suffix.
      final path = await writeAlsFixture('''
<?xml version="1.0" encoding="UTF-8"?>
<Ableton MajorVersion="4" MinorVersion="9.0_305" SchemaChangeCount="10" Creator="Ableton Live 9.1.7" Revision="411c6f82371175a563be02dd24e0409fdb4c3d87">
	<LiveSet>
		<Tracks>
		</Tracks>
	</LiveSet>
</Ableton>
''');

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.dawVersion, '9.1');
    });

    test('falls back to MinorVersion major when Creator is missing', () async {
      final path = await writeAlsFixture('''
<?xml version="1.0" encoding="UTF-8"?>
<Ableton MajorVersion="5" MinorVersion="12.0_12300" SchemaChangeCount="1">
	<LiveSet>
		<Tracks>
		</Tracks>
	</LiveSet>
</Ableton>
''');

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.dawVersion, '12');
    });

    test('extracts BPM from the Tempo/Manual element', () async {
      final path = await writeAlsFixture('''
<?xml version="1.0" encoding="UTF-8"?>
<Ableton MajorVersion="5" MinorVersion="12.0_12300" Creator="Ableton Live 12.3">
	<LiveSet>
		<MasterTrack>
			<DeviceChain>
				<Mixer>
					<Tempo>
						<Manual Value="126.5" />
					</Tempo>
				</Mixer>
			</DeviceChain>
		</MasterTrack>
	</LiveSet>
</Ableton>
''');

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.bpm, 126.5);
    });

    test('malformed file returns empty metadata instead of throwing', () async {
      final file = File('${tempDir.path}/broken.als');
      await file.writeAsBytes([0x00, 0x01, 0x02]);

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.bpm, isNull);
      expect(metadata.key, isNull);
      expect(metadata.dawVersion, isNull);
      expect(metadata.dawType, 'Ableton Live');
    });

    test('missing file returns empty metadata', () async {
      final metadata =
          await MetadataExtractor.extractMetadata('${tempDir.path}/missing.als');
      expect(metadata.bpm, isNull);
      expect(metadata.key, isNull);
      expect(metadata.dawVersion, isNull);
    });
  });

  group('MetadataExtractor — FL Studio (.flp) full extraction', () {
    // .flp files use FL's native "FLhd"/"FLdt" chunk format: a fixed header
    // followed by a stream of TLV events, keyed by ID range (0-63 byte,
    // 64-127 word, 128-191 dword, 192-255 variable-length w/ varint length
    // prefix). Verified against 19 real project files spanning FL 7 to FL
    // 20: event 199 (Version) is the plain version string; event 66
    // (Tempo, word) is the whole-BPM value used before fine tempo existed;
    // event 156 (FineTempo, dword) is BPM*1000 and supersedes it in newer
    // files. Cross-checked against github.com/jdstmporter/FLPFiles.
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('flp_test_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    List<int> varintLength(int length) {
      final bytes = <int>[];
      var value = length;
      while (true) {
        final byte = value & 0x7F;
        value >>= 7;
        if (value == 0) {
          bytes.add(byte);
          break;
        }
        bytes.add(byte | 0x80);
      }
      return bytes;
    }

    List<int> buildFlpBytes({
      required String version,
      int? tempoWord,
      int? fineTempo,
    }) {
      final events = <int>[];

      final versionBytes = [...utf8.encode(version), 0];
      events.add(199);
      events.addAll(varintLength(versionBytes.length));
      events.addAll(versionBytes);

      if (tempoWord != null) {
        events.add(66);
        events.add(tempoWord & 0xFF);
        events.add((tempoWord >> 8) & 0xFF);
      }

      if (fineTempo != null) {
        events.add(156);
        events.add(fineTempo & 0xFF);
        events.add((fineTempo >> 8) & 0xFF);
        events.add((fineTempo >> 16) & 0xFF);
        events.add((fineTempo >> 24) & 0xFF);
      }

      final bytes = <int>[];
      bytes.addAll(utf8.encode('FLhd'));
      bytes.addAll([6, 0, 0, 0]); // header length
      bytes.addAll([0, 0]); // format
      bytes.addAll([4, 0]); // nChannels
      bytes.addAll([96, 0]); // ppq
      bytes.addAll(utf8.encode('FLdt'));
      final len = events.length;
      bytes.addAll([len & 0xFF, (len >> 8) & 0xFF, (len >> 16) & 0xFF, (len >> 24) & 0xFF]);
      bytes.addAll(events);
      return bytes;
    }

    Future<String> writeFlpFixture(List<int> bytes) async {
      final file = File('${tempDir.path}/project.flp');
      await file.writeAsBytes(bytes);
      return file.path;
    }

    test('extracts major.minor version and whole-BPM from a legacy Tempo word event', () async {
      final path = await writeFlpFixture(buildFlpBytes(version: '7.0.0', tempoWord: 142));

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.dawType, 'FL Studio');
      expect(metadata.dawVersion, '7.0');
      expect(metadata.bpm, 142.0);
    });

    test('extracts precise BPM from a FineTempo dword event', () async {
      final path = await writeFlpFixture(buildFlpBytes(version: '20.6.2.1549', fineTempo: 145000));

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.dawVersion, '20.6');
      expect(metadata.bpm, 145.0);
    });

    test('FineTempo takes precedence over the legacy Tempo word when both are present', () async {
      final path = await writeFlpFixture(
        buildFlpBytes(version: '21.0.0', tempoWord: 140, fineTempo: 138500),
      );

      final metadata = await MetadataExtractor.extractMetadata(path);
      expect(metadata.bpm, 138.5);
    });

    test('malformed file returns empty metadata instead of throwing', () async {
      final file = File('${tempDir.path}/broken.flp');
      await file.writeAsBytes([0x00, 0x01, 0x02]);

      final metadata = await MetadataExtractor.extractMetadata(file.path);
      expect(metadata.bpm, isNull);
      expect(metadata.key, isNull);
      expect(metadata.dawVersion, isNull);
      expect(metadata.dawType, 'FL Studio');
    });

    test('missing file returns empty metadata', () async {
      final metadata =
          await MetadataExtractor.extractMetadata('${tempDir.path}/missing.flp');
      expect(metadata.bpm, isNull);
      expect(metadata.key, isNull);
      expect(metadata.dawVersion, isNull);
    });
  });

  group('MetadataExtractor.supportsFullExtraction', () {
    for (final ext in ['.als', '.alp', '.cpr', '.npr', '.bwproject', '.rpp', '.mgd', '.flp', '.logicx', '.song']) {
      test('$ext is supported', () {
        expect(MetadataExtractor.supportsFullExtraction('/fake/project$ext'), isTrue);
      });
    }

    for (final ext in ['.ptx', '.pts', '.cwp', '.ardour', '.band', '.aup3']) {
      test('$ext is not supported', () {
        expect(MetadataExtractor.supportsFullExtraction('/fake/project$ext'), isFalse);
      });
    }

    test('extension check is case-insensitive', () {
      expect(MetadataExtractor.supportsFullExtraction('/fake/Project.RPP'), isTrue);
    });
  });

  // The stats parsers have their own tests under test/services/daw_parsers;
  // these check that extractMetadata actually hands their result back, for
  // each format, through the real file + isolate path.
  group('MetadataExtractor — project stats', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('stats_extract_');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('Ableton: tracks and plug-ins, alongside tempo', () async {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<Ableton Creator="Ableton Live 12.1">
  <LiveSet>
    <Tracks>
      <AudioTrack Id="1" />
      <MidiTrack Id="2">
        <DeviceChain><DeviceChain><Devices>
          <PluginDevice Id="0"><PluginDesc>
            <VstPluginInfo Id="0"><PlugName Value="Sylenth1" /></VstPluginInfo>
          </PluginDesc></PluginDevice>
        </Devices></DeviceChain></DeviceChain>
      </MidiTrack>
      <ReturnTrack Id="3" />
    </Tracks>
    <MainTrack><DeviceChain><Mixer><Tempo><Manual Value="128" /></Tempo></Mixer></DeviceChain></MainTrack>
  </LiveSet>
</Ableton>''';
      final file = File('${tempDir.path}/set.als')
        ..writeAsBytesSync(gzip.encode(utf8.encode(xml)));

      final m = await MetadataExtractor.extractMetadata(file.path);

      expect(m.bpm, 128);
      expect(m.dawVersion, '12.1');
      expect(m.stats!.audioTracks, 1);
      expect(m.stats!.midiTracks, 1);
      expect(m.stats!.busTracks, 1);
      expect(m.stats!.plugins, ['Sylenth1']);
    });

    test('Reaper: stats come back with the markers and notes', () async {
      final file = File('${tempDir.path}/song.rpp')..writeAsStringSync('''
<REAPER_PROJECT 0.1 "7.0/win64" 0
  TEMPO 140 4 4
  <TRACK
    NAME "Drums"
    ISBUS 1 1
  >
>
''');
      final m = await MetadataExtractor.extractMetadata(file.path);
      expect(m.bpm, 140);
      expect(m.markers, isEmpty);
      expect(m.stats!.folderTracks, 1);
    });

    test('Studio One: tempo, version and tracks from the .song zip', () async {
      final archive = Archive();
      void add(String name, String content) {
        final bytes = utf8.encode(content);
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }

      add('metainfo.xml', '''<MetaInformation>
  <Attribute id="Media:Tempo" value="95"/>
  <Attribute id="Document:Generator" value="Studio One/7.0.1.1234"/>
</MetaInformation>''');
      add('Song/song.xml', '''<Song><List>
  <MediaTrack mediaType="Audio"/><MediaTrack mediaType="Music"/>
</List></Song>''');
      final file = File('${tempDir.path}/song.song')
        ..writeAsBytesSync(ZipEncoder().encode(archive));

      final m = await MetadataExtractor.extractMetadata(file.path);

      expect(m.dawType, 'Studio One');
      expect(m.bpm, 95);
      expect(m.dawVersion, '7.0');
      expect(m.stats!.audioTracks, 1);
      expect(m.stats!.instrumentTracks, 1);
    });

    test('a .cpr that is not really a Cubase project yields no stats', () async {
      final file = File('${tempDir.path}/fake.cpr')..writeAsStringSync('nope');
      final m = await MetadataExtractor.extractMetadata(file.path);
      expect(m.stats, isNull);
    });

    test('a lightweight extraction never reads stats', () async {
      final m = await MetadataExtractor.extractLightweightMetadata('/fake/x.cpr');
      expect(m.stats, isNull);
    });
  });
}
