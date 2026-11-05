import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../models/midi_clip_naming.dart' show safeFileNamePart;
import '../daw_parsers/cubase_project_parser.dart';
import 'sylenth1_bank.dart';
import 'vst2_state.dart';

/// One project to read presets from.
class PresetProject {
  const PresetProject({required this.name, required this.path});
  final String name;
  final String path;
}

/// A `.fxb` or `.fxp` ready to be written: the file as the plug-in saved it.
class PresetFile {
  const PresetFile({
    required this.folder,
    required this.fileName,
    required this.bytes,
  });

  /// The plug-in's folder name.
  final String folder;
  final String fileName;
  final Uint8List bytes;
}

/// What an export did.
class PresetExportResult {
  const PresetExportResult({
    this.written = 0,
    this.alreadyThere = 0,
    this.projectsRead = 0,
    this.projectsFailed = 0,
    this.unsavable = const {},
    this.stopped = false,
  });

  /// Files created.
  final int written;

  /// Presets not written because the same bytes were already saved, in this
  /// run (another project, another version) or in the folder from before.
  final int alreadyThere;
  final int projectsRead;
  final int projectsFailed;

  /// Plug-ins with a state that can't be saved as a preset (VST3, and VST2
  /// plug-ins that keep their own format, like Waves'), with how many
  /// instances were found.
  final Map<String, int> unsavable;
  final bool stopped;

  int get unsavableInstances => unsavable.values.fold(0, (a, b) => a + b);
}

/// The preset's name inside its plug-in's folder: what is known about it.
///
/// Sylenth1 names its selected program, which is read from inside the bank;
/// a plain bank or a program says it in its own header; anything else is
/// named by the track alone.
String? presetProgramName(Vst2State state) {
  if (state.pluginId == sylenth1PluginId && state.kind == Vst2StateKind.opaqueBank) {
    final chunk = state.chunk;
    final name = chunk == null ? null : SylenthBank.read(chunk)?.selectedName;
    if (name != null && name.isNotEmpty) return name;
  }
  final name = state.programName;
  return name == null || name.isEmpty ? null : name;
}

/// The files [states] of one project would be saved as, and the plug-ins
/// whose state cannot be saved at all.
///
/// A file is `<plug-in>/<project> - <track> - <program>.fxb`; the program is
/// left out where nothing says which it was.
({List<PresetFile> files, Map<String, int> unsavable}) planPresetFiles(
  String projectName,
  List<CubasePluginState> states,
) {
  final files = <PresetFile>[];
  final unsavable = <String, int>{};
  for (final s in states) {
    final plugin = s.plugin.trim().isNotEmpty
        ? s.plugin.trim()
        : (s.pluginId ?? s.state?.pluginId ?? 'Unknown plug-in');
    final state = s.state;
    if (state == null) {
      unsavable.update(plugin, (n) => n + 1, ifAbsent: () => 1);
      continue;
    }
    final program = presetProgramName(state);
    final parts = [
      projectName,
      if (s.track.isNotEmpty) s.track,
      program ?? state.pluginId,
    ];
    files.add(PresetFile(
      folder: _part(plugin),
      fileName: '${_clip(parts.map(_part).join(' - '))}${state.fileExtension}',
      bytes: state.file,
    ));
  }
  return (files: files, unsavable: unsavable);
}

String _part(String name) {
  final safe = safeFileNamePart(name);
  return safe.isEmpty ? '_' : safe;
}

/// File names stay well short of the 255 bytes most file systems allow.
String _clip(String name) =>
    name.length <= 140 ? name : name.substring(0, 140).trimRight();

/// A state's identity for telling copies from different presets.
String presetDigest(Uint8List bytes) => sha1.convert(bytes).toString();

/// Reads each project and saves its presets under [destination], one folder
/// per plug-in.
///
/// Presets with the same bytes are saved once: the same instance sits in
/// every version of a song, and in several places of one project. Running
/// again into the same folder adds what is new and leaves the rest. A
/// different preset that would take an existing file's name gets a number.
///
/// [readStates] is how a project is read; the default does it off the UI
/// thread. Tests pass their own.
Future<PresetExportResult> exportPresets({
  required String destination,
  required List<PresetProject> projects,
  Future<List<CubasePluginState>> Function(String path) readStates =
      readPluginStatesOffThread,
  void Function(int done, int total, String name)? onProgress,
  bool Function()? shouldStop,
}) async {
  var written = 0;
  var alreadyThere = 0;
  var read = 0;
  var failed = 0;
  var stopped = false;
  final unsavable = <String, int>{};
  final seen = <String>{};

  for (var i = 0; i < projects.length; i++) {
    if (shouldStop?.call() ?? false) {
      stopped = true;
      break;
    }
    final project = projects[i];
    onProgress?.call(i, projects.length, project.name);
    final List<CubasePluginState> states;
    try {
      states = await readStates(project.path);
    } catch (_) {
      failed++;
      continue;
    }
    read++;
    final plan = planPresetFiles(project.name, states);
    plan.unsavable.forEach(
      (plugin, n) => unsavable.update(plugin, (v) => v + n, ifAbsent: () => n),
    );
    for (final file in plan.files) {
      final digest = '${file.folder}/${presetDigest(file.bytes)}';
      if (!seen.add(digest)) {
        alreadyThere++;
        continue;
      }
      switch (await _save(destination, file)) {
        case _Saved.written:
          written++;
        case _Saved.alreadyThere:
          alreadyThere++;
      }
    }
  }
  onProgress?.call(projects.length, projects.length, '');
  return PresetExportResult(
    written: written,
    alreadyThere: alreadyThere,
    projectsRead: read,
    projectsFailed: failed,
    unsavable: unsavable,
    stopped: stopped,
  );
}

enum _Saved { written, alreadyThere }

Future<_Saved> _save(String destination, PresetFile file) async {
  final folder = Directory(p.join(destination, file.folder));
  await folder.create(recursive: true);
  final extension = p.extension(file.fileName);
  final stem = p.basenameWithoutExtension(file.fileName);
  final digest = presetDigest(file.bytes);
  for (var n = 1;; n++) {
    final name = n == 1 ? file.fileName : '$stem ($n)$extension';
    final target = File(p.join(folder.path, name));
    if (!await target.exists()) {
      await _write(target, file.bytes);
      return _Saved.written;
    }
    // The same preset saved by an earlier run, whatever it was called then.
    if (presetDigest(await target.readAsBytes()) == digest) {
      return _Saved.alreadyThere;
    }
  }
}

/// Written to a `.part` and renamed, so a stopped run never leaves a half
/// file that looks finished.
Future<void> _write(File target, Uint8List bytes) async {
  final part = File('${target.path}.part');
  await part.writeAsBytes(bytes, flush: true);
  await part.rename(target.path);
}

/// The default reader: the project is read in an isolate, since they reach
/// tens of megabytes. States come back as copies of their own bytes —
/// handing back views would send the whole project file with each.
Future<List<CubasePluginState>> readPluginStatesOffThread(String path) =>
    Isolate.run(() => _readDetached(path));

List<CubasePluginState> _readDetached(String path) {
  final parser = CubaseProjectParser(File(path).readAsBytesSync());
  return [
    for (final s in parser.readPluginStates())
      CubasePluginState(
        track: s.track,
        place: s.place,
        slot: s.slot,
        plugin: s.plugin,
        pluginId: s.pluginId,
        format: s.format,
        state: s.state == null
            ? null
            : Vst2State.parseFile(Uint8List.fromList(s.state!.file)),
      ),
  ];
}
