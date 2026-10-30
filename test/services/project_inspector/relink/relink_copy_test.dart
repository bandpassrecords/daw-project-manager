import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/relink/relink_copy.dart';
import 'package:daw_project_manager/services/project_inspector/relink/relink_writer.dart';

import '../../../helpers/cubase_archive.dart';

/// Long enough that a temp folder on any CI runner fits in its room.
const _stored = r'D:\MusicProduction\Projects\Cubase\Audio Crawler\'
    r'A Song With A Long Name (Audio Crawler vs Somebody Remix 2024)\Audio\'
    r'Recorded Takes\Session 1\Comped\';

Uint8List _project() {
  final a = CubaseArchive()..begin('PPool');
  a.poolFile('kick.wav', _stored);
  a.poolFile('snare.wav', _stored);
  a.end();
  return a.toCpr();
}

void main() {
  late Directory dir;
  late String project;
  late String audio;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('dpm_relink_');
    project = p.join(dir.path, 'Song.cpr');
    await File(project).writeAsBytes(_project());
    audio = p.join(dir.path, 'Audio');
    await Directory(audio).create();
    await File(p.join(audio, 'kick.wav')).writeAsBytes([1, 2, 3]);
  });
  tearDown(() => dir.delete(recursive: true));

  test('writes "<name> (relinked)" beside the original, which is untouched',
      () async {
    final before = await File(project).readAsBytes();
    final copy = await writeRelinkedCopy(
      projectPath: project,
      moves: {'${_stored}kick.wav': p.join(audio, 'kick.wav')},
    );
    expect(copy.path, p.join(dir.path, 'Song (relinked).cpr'));
    expect(copy.relinked, {'${_stored}kick.wav'});
    expect(await File(project).readAsBytes(), before);
    final refs = CubaseProjectParser(await File(copy.path!).readAsBytes())
        .readSampleReferences();
    expect([for (final r in refs) r.candidates.first],
        [p.join(audio, 'kick.wav'), '${_stored}snare.wav']);
    expect(File('${copy.path}.part').existsSync(), isFalse);
  });

  test('nothing is written when no move could be applied', () async {
    final copy = await writeRelinkedCopy(
      projectPath: project,
      moves: {r'C:\elsewhere\hat.wav': p.join(audio, 'kick.wav')},
    );
    expect(copy.path, isNull);
    expect(copy.refused, {r'C:\elsewhere\hat.wav': RelinkRefusal.notFound});
    expect(dir.listSync().whereType<File>().map((f) => p.basename(f.path)),
        ['Song.cpr']);
  });

  test('a copy pointing at a file that is not there is never kept', () async {
    await expectLater(
      writeRelinkedCopy(
        projectPath: project,
        moves: {'${_stored}snare.wav': p.join(audio, 'snare.wav')},
      ),
      throwsA(isA<RelinkCheckFailed>()),
    );
    expect(dir.listSync().whereType<File>().map((f) => p.basename(f.path)),
        ['Song.cpr']);
  });

  test('a second copy is numbered, never written over the first', () async {
    final moves = {'${_stored}kick.wav': p.join(audio, 'kick.wav')};
    await writeRelinkedCopy(projectPath: project, moves: moves);
    final second = await writeRelinkedCopy(projectPath: project, moves: moves);
    expect(p.basename(second.path!), 'Song (relinked 2).cpr');
  });

  test('relinkedCopyPath skips names taken, and half-written copies', () {
    final taken = {
      p.join('x', 'Song (relinked).cpr'),
      p.join('x', 'Song (relinked 2).cpr.part'),
    };
    expect(relinkedCopyPath(p.join('x', 'Song.cpr'), taken.contains),
        p.join('x', 'Song (relinked 3).cpr'));
  });

  test('a format with no writer is refused up front', () {
    expect(
      () => writeRelinkedCopy(projectPath: 'Song.als', moves: const {}),
      throwsUnsupportedError,
    );
  });
}
