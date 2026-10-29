/// "44.1 kHz", "48 kHz", "96 kHz": a sample rate in kHz, without trailing
/// zeros.
String formatSampleRate(int hz) {
  final khz = (hz / 1000).toStringAsFixed(1);
  return '${khz.endsWith('.0') ? khz.substring(0, khz.length - 2) : khz} kHz';
}

/// "48 kHz · 24-bit", "44.1 kHz", or null when neither is known.
/// [bitDepthText] words the bit depth in the user's language.
String? audioFormatText(
  int? sampleRate,
  int? bitDepth,
  String Function(int bits) bitDepthText,
) {
  final parts = [
    if (sampleRate != null) formatSampleRate(sampleRate),
    if (bitDepth != null) bitDepthText(bitDepth),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}
