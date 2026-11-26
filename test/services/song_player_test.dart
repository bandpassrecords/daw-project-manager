import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:daw_project_manager/services/song_player.dart';

void main() {
  test('a song player reports its position on a timer, never every frame', () {
    // audioplayers' default reports on every frame, which kept the whole app
    // rendering at the display's rate while a song played.
    final updater = songPositionUpdater(() async => Duration.zero);
    expect(updater, isA<TimerPositionUpdater>());
    expect((updater as TimerPositionUpdater).interval, kSongPositionInterval);
    expect(kSongPositionInterval.inMilliseconds, inInclusiveRange(30, 100));
  });

  test('every song player in lib/ is made by newSongPlayer', () {
    // Not song players: the MIDI preview player and the note auditioner
    // follow a clip frame by frame, and the duration probe never plays.
    final allowed = {
      p.normalize('lib/services/song_player.dart'),
      p.normalize('lib/ui/midi_preview_player.dart'),
      p.normalize('lib/ui/midi_note_auditioner.dart'),
      p.normalize('lib/services/track_duration_probe_service.dart'),
    };
    final bare = RegExp(r'(?<![\w.])AudioPlayer\(\)');
    final offenders = <String>[];
    for (final file
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = p.normalize(file.path);
      if (!path.endsWith('.dart') || allowed.contains(path)) continue;
      final lines = file.readAsLinesSync();
      for (final (i, line) in lines.indexed) {
        if (line.trimLeft().startsWith('//')) continue;
        if (bare.hasMatch(line)) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty);
  });
}
