// Saving the presets of real Cubase projects (plug-in presets, Settings >
// Experimental): the library scans copies of the collection, the presets of
// every Cubase project are exported through the same service the settings
// page calls — each project read in an isolate, as in the app — and every
// file that comes out is read back as a .fxb/.fxp.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/plugin_presets/preset_export.dart';
import 'package:daw_project_manager/services/plugin_presets/vst2_state.dart';

import 'flow_library.dart';

void main() {
  late FlowLibrary lib;
  late Directory out;

  setUp(() async {
    lib = await FlowLibrary.open(
      only: ['cubase/Klone - NN (Cubase 5)', 'cubase/Test 2025 (Cubase 13)'],
    );
    await lib.scan();
    out = Directory(p.join(lib.scratch.path, 'Presets'));
  });
  tearDown(() async => lib.close());

  List<PresetProject> cubaseProjects() => [
        for (final project in lib.projects)
          if (!project.isVirtual && project.fileExtension == '.cpr')
            PresetProject(name: project.displayName, path: project.filePath),
      ];

  test('every file saved reads back as a preset of the plug-in it is filed under',
      () async {
    final result = await exportPresets(
      destination: out.path,
      projects: cubaseProjects(),
    );

    expect(result.projectsFailed, 0);
    expect(result.projectsRead, greaterThan(3));
    expect(result.written, greaterThan(10));

    final files = out
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => !f.path.endsWith('.part'))
        .toList();
    expect(files.length, result.written);
    for (final file in files) {
      final extension = p.extension(file.path);
      expect(['.fxb', '.fxp'], contains(extension));
      final state = Vst2State.parseFile(file.readAsBytesSync());
      expect(state, isNotNull, reason: file.path);
      expect(state!.fileExtension, extension, reason: file.path);
    }
  });

  test('a bank\'s program is named in the file, as the plug-in had it', () async {
    await exportPresets(destination: out.path, projects: cubaseProjects());

    final tbk = Directory(p.join(out.path, 'Sonalksis TBK Stereo'))
        .listSync()
        .map((e) => p.basename(e.path))
        .toList();
    expect(tbk, isNotEmpty);
    expect(tbk.any((n) => n.endsWith('Smooth LPF.fxb')), isTrue, reason: '$tbk');
  });

  test('plug-ins that keep their own format are reported, not written', () async {
    final result = await exportPresets(
      destination: out.path,
      projects: cubaseProjects(),
    );

    expect(result.unsavable, contains('PuigTec EQP1A Stereo'));
    expect(
      Directory(out.path)
          .listSync()
          .map((e) => p.basename(e.path)),
      isNot(contains('PuigTec EQP1A Stereo')),
    );
  });

  test('exporting again into the same folder writes nothing new', () async {
    final first = await exportPresets(
      destination: out.path,
      projects: cubaseProjects(),
    );
    final again = await exportPresets(
      destination: out.path,
      projects: cubaseProjects(),
    );

    expect(first.written, greaterThan(0));
    expect(again.written, 0);
    expect(again.alreadyThere, greaterThanOrEqualTo(first.written));
  });

  test('the project files are only read', () async {
    final projects = cubaseProjects();
    final before = {
      for (final pr in projects) pr.path: File(pr.path).lastModifiedSync(),
    };

    await exportPresets(destination: out.path, projects: projects);

    for (final pr in projects) {
      expect(File(pr.path).lastModifiedSync(), before[pr.path]);
    }
  });
}
