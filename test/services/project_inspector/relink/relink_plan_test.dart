import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/models/sample_reference.dart';
import 'package:daw_project_manager/services/daw_parsers/cubase_project_parser.dart';
import 'package:daw_project_manager/services/project_inspector/media_check.dart';
import 'package:daw_project_manager/services/project_inspector/relink/folder_rules.dart';
import 'package:daw_project_manager/services/project_inspector/relink/relink_from_folders.dart';
import 'package:daw_project_manager/services/project_inspector/relink/relink_plan.dart';
import 'package:daw_project_manager/services/sample_pack/sample_locator.dart';

import '../../../helpers/cubase_archive.dart';

/// A folder the files were in, on a drive this computer doesn't have;
/// long, so a temp folder on any CI runner fits in its room.
const _stored = r'Q:\MusicProduction\Projects\Cubase\Audio Crawler\'
    r'A Song With A Long Name (Audio Crawler vs Somebody Remix 2024)\Audio\'
    r'Recorded Takes\Session 1\Comped\';

SampleReference _ref(String name, {SampleUse use = SampleUse.audio}) =>
    SampleReference(fileName: name, candidates: ['$_stored$name'], use: use);

void main() {
  late Directory dir;
  late String projectDir;
  late String backup;

  Future<String> touch(String path, [int size = 3]) async {
    await File(path).create(recursive: true);
    await File(path).writeAsBytes(List.filled(size, 1));
    return path;
  }

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('dpm_relink_plan_');
    projectDir = p.join(dir.path, 'Project');
    backup = p.join(dir.path, 'Backup');
    await Directory(projectDir).create();
  });
  tearDown(() => dir.delete(recursive: true));

  Future<List<RelinkItem>> plan(
    List<SampleReference> refs, {
    List<String> folders = const [],
  }) async {
    final locator = SampleLocator();
    final checks =
        await checkMedia(refs, projectDir: projectDir, locator: locator);
    return planRelink(checks,
        projectDir: projectDir, locator: locator, searchFolders: folders);
  }

  group('planRelink', () {
    test('a name found once in a folder the user gave is taken', () async {
      final kick = await touch(p.join(backup, 'Drums', 'Kit 3', 'kick.wav'));
      final items = await plan([_ref('kick.wav')], folders: [backup]);
      expect(items.single.choice, kick,
          reason: 'not in a library, so agreement is not asked for');
    });

    test('found twice, the one sharing the old folders wins', () async {
      await touch(p.join(backup, 'Other', 'snare.wav'));
      final right = await touch(p.join(backup, 'Session 1', 'Comped', 'snare.wav'));
      final items = await plan([_ref('snare.wav')], folders: [backup]);
      expect(items.single.choice, right);
    });

    test('found twice with nothing to tell them apart: the user picks',
        () async {
      await touch(p.join(backup, 'A', 'snare.wav'));
      await touch(p.join(backup, 'B', 'snare.wav'));
      final item = (await plan([_ref('snare.wav')], folders: [backup])).single;
      expect(item.choice, isNull);
      expect(item.ambiguous, isTrue);
      expect(item.candidates, hasLength(2));
    });

    test("a file in the project's own folder is the first choice", () async {
      final own = await touch(p.join(projectDir, 'Audio', 'kick.wav'));
      await touch(p.join(backup, 'kick.wav'));
      final items = await plan([_ref('kick.wav')], folders: [backup]);
      expect(items.single.choice, own);
      expect(items.single.candidates, hasLength(2));
    });

    test('files found where the project says, and plug-in paths, are left out',
        () async {
      final here = await touch(p.join(dir.path, 'here.wav'));
      final items = await plan([
        SampleReference(fileName: 'here.wav', candidates: [here]),
        _ref('pad.wav', use: SampleUse.plugin),
      ]);
      expect(items, isEmpty);
    });

    test('nothing found: no choice, nothing to pick from', () async {
      final item = (await plan([_ref('hat.wav')], folders: [backup])).single;
      expect((item.choice, item.ambiguous), (null, false));
    });
  });

  group('rules', () {
    final items = [
      RelinkItem(reference: _ref('a.wav'), stored: '${_stored}a.wav'),
      RelinkItem(
        reference: _ref('b.wav'),
        stored: '${_stored}b.wav',
        choice: r'X:\picked\b.wav',
        manual: true,
      ),
    ];
    final rule = FolderRule(_stored, r'E:\Moved');
    Future<bool> exists(String path) async => path.startsWith(r'E:\Moved');

    test('applyRules points every item not chosen by hand', () async {
      final out = await applyRules(items, [rule], exists);
      expect(out[0].choice, r'E:\Moved\a.wav');
      expect(out[1].choice, r'X:\picked\b.wav');
    });

    test('a rule whose file is not there changes nothing', () async {
      final out = await applyRules(items, [rule], (_) async => false);
      expect(out[0].choice, isNull);
    });

    test('filesFixedBy counts the files a rule finds', () async {
      expect(await filesFixedBy(rule, items, exists), 2);
    });

    test('relinkMoves: chosen items only, stored path to new', () {
      expect(relinkMoves(items), {'${_stored}b.wav': r'X:\picked\b.wav'});
    });
  });

  test('relinkFromFolders: one folder in, a relinked copy out', () async {
    final a = CubaseArchive()..begin('PPool');
    for (final name in ['kick.wav', 'snare.wav', 'hat.wav']) {
      a.poolFile(name, _stored);
    }
    a.end();
    final Uint8List bytes = a.toCpr();
    final project = p.join(projectDir, 'Song.cpr');
    await File(project).writeAsBytes(bytes);
    final kick = await touch(p.join(backup, 'kick.wav'));
    await touch(p.join(backup, 'A', 'snare.wav'));
    await touch(p.join(backup, 'B', 'snare.wav'));

    final result = await relinkFromFolders(
      projectPath: project,
      references: CubaseProjectParser(bytes).readSampleReferences(),
      folders: [backup],
    );
    expect(result.relinked, 1);
    expect(p.basename(result.copy!.path!), 'Song (relinked).cpr');
    expect([for (final i in result.ambiguous) i.reference.fileName],
        ['snare.wav']);
    expect([for (final i in result.notFound) i.reference.fileName],
        ['hat.wav']);
    final copied = CubaseProjectParser(
            await File(result.copy!.path!).readAsBytes())
        .readSampleReferences();
    expect(copied.first.candidates.first, kick);
    expect(await File(project).readAsBytes(), bytes, reason: 'untouched');
  });

  test('relinkFromFolders writes nothing when nothing is found', () async {
    final a = CubaseArchive()..begin('PPool');
    a.poolFile('hat.wav', _stored);
    a.end();
    final project = p.join(projectDir, 'Song.cpr');
    await File(project).writeAsBytes(a.toCpr());
    final result = await relinkFromFolders(
      projectPath: project,
      references: [_ref('hat.wav')],
      folders: [backup],
    );
    expect(result.copy, isNull);
    expect(Directory(projectDir).listSync(), hasLength(1));
  });
}
