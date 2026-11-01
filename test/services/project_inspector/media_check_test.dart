import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/sample_reference.dart';
import 'package:daw_project_manager/services/project_inspector/media_check.dart';

void main() {
  late Directory project;

  setUp(() {
    project = Directory.systemTemp.createTempSync('media_check');
    File(p.join(project.path, 'Audio', 'Kick.wav'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);
    File(p.join(project.path, 'Moved', 'Snare.wav'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([1]);
  });

  tearDown(() => project.deleteSync(recursive: true));

  SampleReference ref(String name, List<String> candidates) =>
      SampleReference(fileName: name, candidates: candidates);

  test('found where stored, found elsewhere in the project, or missing',
      () async {
    final checks = await checkMedia([
      ref('Kick.wav', [p.join(project.path, 'Audio', 'Kick.wav')]),
      ref('Snare.wav', [p.join('Audio', 'Snare.wav')]),
      ref('Gone.wav', [p.join(project.path, 'Audio', 'Gone.wav')]),
    ], projectDir: project.path);

    expect([for (final c in checks) (c.reference.fileName, c.status)], [
      ('Kick.wav', MediaStatus.found),
      ('Snare.wav', MediaStatus.foundElsewhere),
      ('Gone.wav', MediaStatus.missing),
    ]);
    expect(p.normalize(checks[1].path!),
        p.normalize(p.join(project.path, 'Moved', 'Snare.wav')));
    expect(checks[2].path, isNull);
  });

  test('a relative stored path counts as where the project says', () async {
    final checks = await checkMedia([
      ref('Kick.wav', [p.join('Audio', 'Kick.wav')]),
    ], projectDir: project.path);
    expect(checks.single.status, MediaStatus.found);
  });

  test('a file referenced twice is checked once', () async {
    final kick = ref('Kick.wav', [p.join(project.path, 'Audio', 'Kick.wav')]);
    final checks = await checkMedia([kick, kick], projectDir: project.path);
    expect(checks, hasLength(1));
  });

  test('mediaCounts tallies the statuses', () {
    final counts = mediaCounts([
      MediaCheck(ref('a', const []), MediaStatus.missing),
      MediaCheck(ref('b', const []), MediaStatus.missing),
      MediaCheck(ref('c', const []), MediaStatus.found),
    ]);
    expect(counts, {MediaStatus.missing: 2, MediaStatus.found: 1});
  });
}
