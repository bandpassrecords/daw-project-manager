import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/services/audio_fade.dart';

void main() {
  test('a fade steps down gently, all the way to silence', () {
    final steps = fadeOutVolumes(0.8);
    expect(steps, hasLength(16));
    expect(steps.last, 0, reason: 'silent before the stop: no pop');
    expect(steps.first, lessThan(0.8));
    for (var i = 1; i < steps.length; i++) {
      expect(steps[i], lessThanOrEqualTo(steps[i - 1]));
      // No single drop bigger than an eighth of the starting level: the
      // old fade jumped 40 % at once, and the jumps were the clicks.
      expect(steps[i - 1] - steps[i], lessThan(0.8 / 8));
    }
    expect(0.8 - steps.first, lessThan(0.8 / 8));
  });

  test('a fade sets every step, then stops', () async {
    final volumes = <double>[];
    var stopped = 0;
    await runFadeOut(
      setVolume: (v) async => volumes.add(v),
      stop: () async => stopped++,
      volume: 1,
      over: Duration.zero,
    );
    expect(volumes, fadeOutVolumes(1));
    expect(stopped, 1);
  });

  test('a fade whose player is handed a new sound lets it be: no stop',
      () async {
    final volumes = <double>[];
    var stopped = 0;
    await runFadeOut(
      setVolume: (v) async => volumes.add(v),
      stop: () async => stopped++,
      volume: 1,
      over: Duration.zero,
      abandoned: () => volumes.length >= 4, // a new play after four steps
    );
    expect(volumes, hasLength(4), reason: 'no more turning it down');
    expect(stopped, 0, reason: 'the new sound plays on');
  });

  test('a player that cannot fade still stops', () async {
    var stopped = 0;
    await runFadeOut(
      setVolume: (_) async => throw StateError('no volume'),
      stop: () async => stopped++,
      volume: 1,
      over: Duration.zero,
    );
    expect(stopped, 1);
  });

  test('a muted player fades from nothing to nothing', () {
    expect(fadeOutVolumes(0).every((v) => v == 0), isTrue);
  });
}
