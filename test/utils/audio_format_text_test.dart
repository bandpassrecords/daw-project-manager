import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/audio_format_text.dart';

void main() {
  String bits(int b) => '$b-bit';

  test('sample rates in kHz, without trailing zeros', () {
    expect(formatSampleRate(44100), '44.1 kHz');
    expect(formatSampleRate(48000), '48 kHz');
    expect(formatSampleRate(88200), '88.2 kHz');
    expect(formatSampleRate(192000), '192 kHz');
  });

  test('rate and depth together, either alone, or nothing', () {
    expect(audioFormatText(48000, 24, bits), '48 kHz · 24-bit');
    expect(audioFormatText(44100, null, bits), '44.1 kHz');
    expect(audioFormatText(null, 32, bits), '32-bit');
    expect(audioFormatText(null, null, bits), isNull);
  });
}
