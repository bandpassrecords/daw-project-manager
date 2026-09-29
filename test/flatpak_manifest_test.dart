import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

// The Flatpak manifest is fed to flatpak-flutter, which fails outright on
// invalid YAML (v2.9.1's first tag run died on an unquoted ": " in a command).
void main() {
  final manifest = File('flatpak/com.bandpassrecords.dpm.yml');

  List<String> buildCommands() {
    final doc = loadYaml(manifest.readAsStringSync()) as YamlMap;
    final module = (doc['modules'] as YamlList)
        .whereType<YamlMap>()
        .firstWhere((m) => m['name'] == 'daw-project-manager');
    return (module['build-commands'] as YamlList)
        .map((c) => c.toString())
        .toList();
  }

  test('manifest is valid YAML and the app module has build commands', () {
    expect(buildCommands(), isNotEmpty);
  });

  test('the ffmpeg-kit sed removes the dependency and its override', () {
    final command =
        buildCommands().firstWhere((c) => c.startsWith('sed -i'));
    final patterns = RegExp(r"'([^']*)'")
        .allMatches(command)
        .map((m) => m.group(1)!)
        .toList();
    expect(patterns, hasLength(2));

    final result = Process.runSync(
      'sed',
      [for (final p in patterns) ...['-e', p], 'pubspec.yaml'],
    );
    expect(result.exitCode, 0);
    final out = result.stdout as String;

    final live = out
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('#'))
        .join('\n');
    expect(live, isNot(contains('ffmpeg_kit_flutter_new_audio')));
    expect(live, contains('windows_taskbar:'));
    expect(live, contains('path: third_party/windows_taskbar'));
    expect(() => loadYaml(out), returnsNormally);
  }, skip: Process.runSync('sed', ['--version']).exitCode != 0
      ? 'sed not available'
      : false);

  test('the Flatpak stub exposes the same function as the real file', () {
    const signature = 'Future<bool> runInProcessFfmpeg(List<String> args)';
    expect(File('flatpak/in_process_ffmpeg_stub.dart').readAsStringSync(),
        contains(signature));
    expect(File('lib/services/in_process_ffmpeg.dart').readAsStringSync(),
        contains(signature));
  });
}
