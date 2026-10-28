import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'audio_analysis_service.dart';

/// What tells a source file is still the one a waveform was drawn from: its
/// modification time and size, both from one `stat`. Never a hash of its
/// contents — that reads the whole file, costing about what drawing it again
/// does, and on a cloud drive downloads it. The size catches a copy or sync
/// that carried the old modification time over to new audio.
typedef WaveformSourceStamp = ({int mtime, int size});

/// Persistent on-disk cache for [WaveformPeaks].
///
/// Each entry is a small binary file (~96 KB for 4 096 stereo frames) stored
/// under `<app-support>/waveform_cache/`. The file embeds the source file's
/// [WaveformSourceStamp] — modification time and size — so stale entries are
/// automatically ignored when the audio file changes, a re-bounce to the same
/// name included.
///
/// Binary layout (little-endian):
///   4  uint32  magic = 0x57464B50 ('WFPK')
///   4  uint32  version = 3
///   8  int64   source file mtime (microseconds since epoch)
///   8  int64   source file size (bytes)
///   4  int32   sampleRate
///   8  float64 durationSeconds
///   4  int32   frameCount
///   4  int32   channelCount (0 when the source had no separate lanes)
///   4  int32   pathLen (UTF-8 bytes)
///   N  bytes   source file path (UTF-8)
///  F*4 float32 minValues[F]
///  F*4 float32 maxValues[F]
///  F*4 float32 rmsValues[F]
///  then, per channel:
///  F*4 float32 channelMin[c][F]
///  F*4 float32 channelMax[c][F]
///  F*4 float32 channelRms[c][F]
///
/// A version bump discards every older entry on read, so they are
/// re-extracted once and re-saved in the new shape. v1 had none of the
/// per-channel lanes, the RMS bodies, or the higher frame count; v2 had no
/// source size.
class WaveformDiskCache {
  static const _magic = 0x57464B50;
  static const _version = 3;
  static const _headerBytes = 48;

  /// The [WaveformSourceStamp] of the file at [filePath] now.
  static WaveformSourceStamp sourceStamp(String filePath) {
    final stat = File(filePath).statSync();
    return (mtime: stat.modified.microsecondsSinceEpoch, size: stat.size);
  }

  static Future<String> _entryPath(String filePath) async {
    final dir = await getApplicationSupportDirectory();
    // FNV-1a 32-bit hash of the path — collisions are guarded by the stored path.
    int hash = 0x811c9dc5;
    for (final byte in utf8.encode(filePath)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    final hex = hash.toRadixString(16).padLeft(8, '0');
    return p.join(dir.path, 'waveform_cache', '$hex.wfpk');
  }

  static Future<WaveformPeaks?> load(String filePath) async {
    try {
      final entryPath = await _entryPath(filePath);
      final file = File(entryPath);
      if (!file.existsSync()) return null;

      final bytes = await file.readAsBytes();
      if (bytes.length < _headerBytes) return null;

      final buf = ByteData.sublistView(bytes);
      int off = 0;

      if (buf.getUint32(off, Endian.little) != _magic) return null;
      off += 4;
      if (buf.getUint32(off, Endian.little) != _version) return null;
      off += 4;

      final cachedMtime = buf.getInt64(off, Endian.little); off += 8;
      final cachedSize = buf.getInt64(off, Endian.little); off += 8;
      final sampleRate = buf.getInt32(off, Endian.little); off += 4;
      final duration = buf.getFloat64(off, Endian.little); off += 8;
      final frameCount = buf.getInt32(off, Endian.little); off += 4;
      final channelCount = buf.getInt32(off, Endian.little); off += 4;
      final pathLen = buf.getInt32(off, Endian.little); off += 4;

      if (frameCount < 0 || channelCount < 0 || pathLen < 0) return null;
      if (off + pathLen > bytes.length) return null;
      final storedPath = utf8.decode(bytes.sublist(off, off + pathLen));
      if (storedPath != filePath) return null; // hash collision guard
      off += pathLen;

      // Invalidate if source file was modified since caching.
      if (sourceStamp(filePath) != (mtime: cachedMtime, size: cachedSize)) {
        return null;
      }

      // min/max/rms for the mono mixdown, then the same three per channel lane.
      final arrays = 3 + channelCount * 3;
      if (off + frameCount * 4 * arrays > bytes.length) return null;

      List<double> readArray() {
        final values = List<double>.generate(
            frameCount, (i) => buf.getFloat32(off + i * 4, Endian.little));
        off += frameCount * 4;
        return values;
      }

      final minValues = readArray();
      final maxValues = readArray();
      final rmsValues = readArray();
      final channelMin = <List<double>>[];
      final channelMax = <List<double>>[];
      final channelRms = <List<double>>[];
      for (int c = 0; c < channelCount; c++) {
        channelMin.add(readArray());
        channelMax.add(readArray());
        channelRms.add(readArray());
      }

      return WaveformPeaks(
        minValues: minValues,
        maxValues: maxValues,
        rmsValues: rmsValues,
        channelMin: channelMin,
        channelMax: channelMax,
        channelRms: channelRms,
        sampleRate: sampleRate,
        durationSeconds: duration,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String filePath, WaveformPeaks peaks) async {
    try {
      final stamp = sourceStamp(filePath);
      final pathBytes = utf8.encode(filePath);
      final frameCount = peaks.frameCount;

      if (peaks.minValues.length != frameCount) return;

      // Store the leading run of full-length lanes only — a short or missing
      // one would desynchronise every array after it on read.
      int channelCount = 0;
      while (channelCount < peaks.channelMin.length &&
          channelCount < peaks.channelMax.length &&
          channelCount < peaks.channelRms.length &&
          peaks.channelMin[channelCount].length == frameCount &&
          peaks.channelMax[channelCount].length == frameCount &&
          peaks.channelRms[channelCount].length == frameCount) {
        channelCount++;
      }

      // Every array is fixed-width, so a missing RMS body is stored as zeros
      // rather than shifting everything after it.
      final rmsValues = peaks.hasRms
          ? peaks.rmsValues
          : List<double>.filled(frameCount, 0.0);

      final header = ByteData(_headerBytes);
      header.setUint32(0, _magic, Endian.little);
      header.setUint32(4, _version, Endian.little);
      header.setInt64(8, stamp.mtime, Endian.little);
      header.setInt64(16, stamp.size, Endian.little);
      header.setInt32(24, peaks.sampleRate, Endian.little);
      header.setFloat64(28, peaks.durationSeconds, Endian.little);
      header.setInt32(36, frameCount, Endian.little);
      header.setInt32(40, channelCount, Endian.little);
      header.setInt32(44, pathBytes.length, Endian.little);

      Uint8List encodeArray(List<double> values) {
        final data = ByteData(frameCount * 4);
        for (int i = 0; i < frameCount; i++) {
          data.setFloat32(i * 4, values[i], Endian.little);
        }
        return data.buffer.asUint8List();
      }

      final builder = BytesBuilder(copy: false);
      builder.add(header.buffer.asUint8List());
      builder.add(pathBytes);
      builder.add(encodeArray(peaks.minValues));
      builder.add(encodeArray(peaks.maxValues));
      builder.add(encodeArray(rmsValues));
      for (int c = 0; c < channelCount; c++) {
        builder.add(encodeArray(peaks.channelMin[c]));
        builder.add(encodeArray(peaks.channelMax[c]));
        builder.add(encodeArray(peaks.channelRms[c]));
      }

      final entryPath = await _entryPath(filePath);
      final dir = Directory(p.dirname(entryPath));
      if (!dir.existsSync()) await dir.create(recursive: true);
      await File(entryPath).writeAsBytes(builder.toBytes());
    } catch (_) {}
  }
}
