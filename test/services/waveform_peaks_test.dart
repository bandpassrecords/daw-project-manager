import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:daw_project_manager/providers/providers.dart';
import 'package:daw_project_manager/services/audio_analysis_service.dart';
import 'package:daw_project_manager/services/waveform_disk_cache.dart';

/// Points the disk cache at a real temp folder instead of a device path.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.supportPath);
  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

/// The RIFF header, `fmt ` chunk and `data` chunk header of a WAV — everything
/// before its samples. [leadingChunkBytes] puts a `JUNK` chunk of that size
/// between the two, the way BWF metadata sits before the samples.
Uint8List wavHeader({
  required int numChannels,
  required int numFrames,
  required int sampleRate,
  int bitDepth = 16,
  bool float = false,
  int leadingChunkBytes = 0,
}) {
  final bytesPerSample = bitDepth ~/ 8;
  final dataSize = numFrames * numChannels * bytesPerSample;
  final junk = leadingChunkBytes > 0 ? 8 + leadingChunkBytes : 0;

  final bytes = Uint8List(44 + junk);
  final bd = ByteData.sublistView(bytes);
  bytes.setAll(0, 'RIFF'.codeUnits);
  bd.setUint32(4, 36 + junk + dataSize, Endian.little);
  bytes.setAll(8, 'WAVE'.codeUnits);
  bytes.setAll(12, 'fmt '.codeUnits);
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, float ? 3 : 1, Endian.little);
  bd.setUint16(22, numChannels, Endian.little);
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * numChannels * bytesPerSample, Endian.little);
  bd.setUint16(32, numChannels * bytesPerSample, Endian.little);
  bd.setUint16(34, bitDepth, Endian.little);
  if (junk > 0) {
    bytes.setAll(36, 'JUNK'.codeUnits);
    bd.setUint32(40, leadingChunkBytes, Endian.little);
  }
  bytes.setAll(36 + junk, 'data'.codeUnits);
  bd.setUint32(40 + junk, dataSize, Endian.little);
  return bytes;
}

/// Writes a PCM WAV (16-, 24- or 32-bit, or 32-bit float) whose channels are
/// [channels] (each the same length, samples in −1…+1).
Future<File> writeWav(
  String path,
  List<List<double>> channels, {
  int sampleRate = 8000,
  int bitDepth = 16,
  bool float = false,
  int leadingChunkBytes = 0,
}) async {
  final numChannels = channels.length;
  final numFrames = channels.first.length;
  final bytesPerSample = bitDepth ~/ 8;
  final header = wavHeader(
    numChannels: numChannels,
    numFrames: numFrames,
    sampleRate: sampleRate,
    bitDepth: bitDepth,
    float: float,
    leadingChunkBytes: leadingChunkBytes,
  );

  final data = Uint8List(numFrames * numChannels * bytesPerSample);
  final bd = ByteData.sublistView(data);
  for (int f = 0; f < numFrames; f++) {
    for (int c = 0; c < numChannels; c++) {
      final off = (f * numChannels + c) * bytesPerSample;
      final s = channels[c][f];
      if (float) {
        bd.setFloat32(off, s, Endian.little);
      } else if (bitDepth == 16) {
        bd.setInt16(off, (s * 32767).round(), Endian.little);
      } else if (bitDepth == 24) {
        final v = (s * 8388607).round();
        data[off] = v & 0xFF;
        data[off + 1] = (v >> 8) & 0xFF;
        data[off + 2] = (v >> 16) & 0xFF;
      } else {
        bd.setInt32(off, (s * 2147483647).round(), Endian.little);
      }
    }
  }

  final file = File(path);
  await file.writeAsBytes(
      (BytesBuilder(copy: false)..add(header)..add(data)).toBytes());
  return file;
}

/// Alternating ±[amplitude] for [length] samples, so every bin sees both a
/// minimum and a maximum whatever the bin boundaries land on.
List<double> buzz(int length, double amplitude) =>
    List<double>.generate(length, (i) => i.isEven ? amplitude : -amplitude);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('waveform_peaks_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('extractWaveformPeaks — stereo lanes', () {
    test('keeps left and right as separate envelopes', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'stereo.wav'),
        [buzz(4000, 1.0), buzz(4000, 0.25)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      expect(peaks, isNotNull);
      expect(peaks!.hasChannelData, isTrue);
      expect(peaks.channelMin, hasLength(2));
      expect(peaks.channelMax, hasLength(2));
      expect(peaks.channelMax[0], hasLength(peaks.frameCount));

      // Loud left, quiet right — the whole point of drawing two lanes.
      expect(peaks.channelMax[0].reduce((a, b) => a > b ? a : b), closeTo(1.0, 0.01));
      expect(peaks.channelMax[1].reduce((a, b) => a > b ? a : b), closeTo(0.25, 0.01));
      expect(peaks.channelMin[0].reduce((a, b) => a < b ? a : b), closeTo(-1.0, 0.01));
      expect(peaks.channelMin[1].reduce((a, b) => a < b ? a : b), closeTo(-0.25, 0.01));

      // The mono mixdown is still the average, not either channel.
      expect(peaks.maxValues.reduce((a, b) => a > b ? a : b), closeTo(0.625, 0.01));
    });

    test('carries an RMS body sitting inside the peak outline', () async {
      // A square wave has RMS == peak; a sine sits at peak/√2. The gap between
      // the two is the whole point of the body layer, so it has to be real
      // per-frame data rather than a scaled copy of the peaks.
      final sine = List<double>.generate(
          8000, (i) => sin(2 * pi * i / 40) * 0.8);
      final wav = await writeWav(p.join(tempDir.path, 'sine.wav'), [sine]);

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      expect(peaks!.hasRms, isTrue);
      expect(peaks.rmsValues, hasLength(peaks.frameCount));
      for (int i = 0; i < peaks.frameCount; i++) {
        expect(peaks.rmsValues[i], lessThanOrEqualTo(peaks.maxValues[i] + 1e-6),
            reason: 'body escaped the outline at frame $i');
        expect(peaks.rmsValues[i], greaterThan(0));
      }
      // 0.8 peak → 0.8/√2 ≈ 0.566 RMS.
      final meanRms =
          peaks.rmsValues.reduce((a, b) => a + b) / peaks.frameCount;
      expect(meanRms, closeTo(0.566, 0.02));
    });

    test('gives each lane its own RMS body', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'stereo_rms.wav'),
        [buzz(4000, 1.0), buzz(4000, 0.25)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      expect(peaks!.hasChannelRms(0), isTrue);
      expect(peaks.hasChannelRms(1), isTrue);
      // Alternating ±a is a square wave, so RMS equals the amplitude.
      expect(peaks.channelRms[0].first, closeTo(1.0, 0.01));
      expect(peaks.channelRms[1].first, closeTo(0.25, 0.01));
    });

    test('a mono source carries no lanes, only the mixdown', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'mono.wav'),
        [buzz(4000, 0.5)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      expect(peaks, isNotNull);
      expect(peaks!.hasChannelData, isFalse);
      expect(peaks.channelMin, isEmpty);
      expect(peaks.maxValues.reduce((a, b) => a > b ? a : b), closeTo(0.5, 0.01));
    });

    test('drops channels beyond the two the renderer can show', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'surround.wav'),
        [buzz(4000, 1.0), buzz(4000, 0.8), buzz(4000, 0.6), buzz(4000, 0.4)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      expect(peaks!.channelMin, hasLength(maxWaveformLanes));
      expect(peaks.channelMax, hasLength(maxWaveformLanes));
    });
  });

  group('extractWaveformPeaks — bin coverage', () {
    // Regression: bin width used to be `numSamples ~/ frames`, truncated, so
    // the last `numSamples % frames` samples were covered by no bin at all —
    // a final transient simply never appeared, and every drawn column sat
    // slightly earlier than the audio it represented.
    test('the very end of the file lands in the last frame', () async {
      // 256 × 100 + 90: the truncated bin width stops 90 samples short.
      const total = 25690;
      final samples = List<double>.filled(total, 0.0);
      for (int i = total - 50; i < total; i++) {
        samples[i] = i.isEven ? 0.9 : -0.9;
      }

      final wav = await writeWav(p.join(tempDir.path, 'tail.wav'), [samples]);
      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 256,
      );

      expect(peaks, isNotNull);
      expect(peaks!.frameCount, 256);
      expect(peaks.maxValues.last, greaterThan(0.5));
      expect(peaks.minValues.last, lessThan(-0.5));
    });

    test('every frame is populated for a file shorter than the frame count',
        () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'short.wav'),
        [buzz(64, 1.0)],
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 4096,
      );

      // Clamped to the sample count rather than emitting empty frames. Each
      // frame holds a single sample here, so it registers on one side of zero
      // only — what matters is that none of them is a dead, zero-width frame.
      expect(peaks!.frameCount, 64);
      for (int i = 0; i < peaks.frameCount; i++) {
        expect(peaks.maxValues[i] - peaks.minValues[i], greaterThan(0),
            reason: 'frame $i covered no samples');
      }
    });
  });

  group('extractWaveformPeaks — long files', () {
    // Regression: the whole WAV was read into memory and every sample turned
    // into a Dart double — per channel, plus a mono mixdown — about seven
    // times the file's size for a stereo 16-bit file. A 60-minute bounce
    // needed gigabytes, and on a phone the OS killed the app outright.
    test('memory stays flat however long the file is', () async {
      // Three minutes of 48 kHz stereo, ~35 MB: the old code peaked ~250 MB
      // above where it started.
      const sampleRate = 48000;
      const seconds = 180;
      const numFrames = sampleRate * seconds;
      final path = p.join(tempDir.path, 'long.wav');

      // Written a second at a time, so writing it doesn't raise the peak.
      // Quiet for the first half, loud for the second.
      final raf = File(path).openSync(mode: FileMode.write);
      raf.writeFromSync(wavHeader(
        numChannels: 2,
        numFrames: numFrames,
        sampleRate: sampleRate,
      ));
      final second = Uint8List(sampleRate * 4);
      final bd = ByteData.sublistView(second);
      for (int s = 0; s < seconds; s++) {
        final amplitude = s < seconds ~/ 2 ? 3000 : 30000;
        for (int f = 0; f < sampleRate; f++) {
          final v = f.isEven ? amplitude : -amplitude;
          bd.setInt16(f * 4, v, Endian.little);
          bd.setInt16(f * 4 + 2, v ~/ 2, Endian.little);
        }
        raf.writeFromSync(second);
      }
      raf.closeSync();

      final before = ProcessInfo.maxRss;
      final peaks = await AudioAnalysisService.extractWaveformPeaks(path);
      final grew = ProcessInfo.maxRss - before;

      expect(peaks, isNotNull);
      expect(grew, lessThan(64 * 1024 * 1024),
          reason: 'peak memory grew by ${grew ~/ (1024 * 1024)} MB');

      expect(peaks!.frameCount, AudioAnalysisService.waveformFrameCount);
      expect(peaks.durationSeconds, closeTo(seconds, 0.001));
      expect(peaks.maxValues.first, closeTo(3000 * 0.75 / 32768, 0.001));
      expect(peaks.maxValues.last, closeTo(30000 * 0.75 / 32768, 0.001));
      expect(peaks.channelMax[0].last, closeTo(30000 / 32768, 0.001));
      expect(peaks.channelMax[1].last, closeTo(15000 / 32768, 0.001));
      // Halfway through is where it gets loud, give or take one frame.
      final loudFrom = peaks.maxValues.indexWhere((v) => v > 0.5);
      expect(loudFrom, closeTo(peaks.frameCount ~/ 2, 1));
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('extractWaveformPeaks — sample formats', () {
    for (final (name, bitDepth, float) in [
      ('24-bit', 24, false),
      ('32-bit', 32, false),
      ('32-bit float', 32, true),
    ]) {
      test('reads $name samples', () async {
        final wav = await writeWav(
          p.join(tempDir.path, '$bitDepth$float.wav'),
          [buzz(4000, 0.5), buzz(4000, 0.25)],
          bitDepth: bitDepth,
          float: float,
        );

        final peaks = await AudioAnalysisService.extractWaveformPeaks(
          wav.path,
          targetFrames: 100,
        );

        expect(peaks, isNotNull);
        expect(peaks!.channelMax[0].reduce(max), closeTo(0.5, 0.001));
        expect(peaks.channelMin[1].reduce(min), closeTo(-0.25, 0.001));
        expect(peaks.maxValues.reduce(max), closeTo(0.375, 0.001));
        expect(peaks.rmsValues.first, closeTo(0.375, 0.001));
      });
    }

    test('finds the samples behind a large metadata chunk', () async {
      // Bigger than any fixed-size header read would cover.
      final wav = await writeWav(
        p.join(tempDir.path, 'bwf.wav'),
        [buzz(4000, 0.5)],
        leadingChunkBytes: 200 * 1024,
      );

      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 100,
      );

      expect(peaks, isNotNull);
      expect(peaks!.frameCount, 100);
      expect(peaks.maxValues.reduce(max), closeTo(0.5, 0.001));
      expect(peaks.durationSeconds, closeTo(0.5, 0.001));
    });
  });

  group('WaveformDiskCache', () {
    late Directory supportDir;

    setUp(() async {
      supportDir = await Directory.systemTemp.createTemp('waveform_cache_test_');
      PathProviderPlatform.instance = _FakePathProvider(supportDir.path);
    });

    tearDown(() async {
      if (await supportDir.exists()) await supportDir.delete(recursive: true);
    });

    test('round-trips the stereo lanes, not just the mixdown', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'cached.wav'),
        [buzz(4000, 1.0), buzz(4000, 0.25)],
      );
      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      await WaveformDiskCache.save(wav.path, peaks!);
      final loaded = await WaveformDiskCache.load(wav.path);

      expect(loaded, isNotNull);
      expect(loaded!.frameCount, peaks.frameCount);
      expect(loaded.hasChannelData, isTrue);
      expect(loaded.hasRms, isTrue);
      expect(loaded.channelMin, hasLength(2));
      for (int i = 0; i < peaks.frameCount; i++) {
        expect(loaded.rmsValues[i], closeTo(peaks.rmsValues[i], 1e-6));
      }
      for (int c = 0; c < 2; c++) {
        expect(loaded.hasChannelRms(c), isTrue);
        for (int i = 0; i < peaks.frameCount; i++) {
          expect(loaded.channelMax[c][i], closeTo(peaks.channelMax[c][i], 1e-6));
          expect(loaded.channelMin[c][i], closeTo(peaks.channelMin[c][i], 1e-6));
          expect(loaded.channelRms[c][i], closeTo(peaks.channelRms[c][i], 1e-6));
        }
      }
    });

    test('round-trips a mono entry with no lanes', () async {
      final wav = await writeWav(
        p.join(tempDir.path, 'cached_mono.wav'),
        [buzz(4000, 0.5)],
      );
      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );

      await WaveformDiskCache.save(wav.path, peaks!);
      final loaded = await WaveformDiskCache.load(wav.path);

      expect(loaded, isNotNull);
      expect(loaded!.hasChannelData, isFalse);
      expect(loaded.channelMin, isEmpty);
      expect(loaded.maxValues, hasLength(peaks.frameCount));
    });

    // v1 entries have neither the lanes nor the higher frame count, v2 no
    // source size, so they must be discarded and re-extracted rather than
    // read as the current format and misparsed.
    for (final version in [1, 2]) {
      test('rejects an entry written by cache format v$version', () async {
        final wav = await writeWav(
          p.join(tempDir.path, 'legacy.wav'),
          [buzz(4000, 0.5)],
        );
        final peaks = await AudioAnalysisService.extractWaveformPeaks(
          wav.path,
          targetFrames: 200,
        );
        await WaveformDiskCache.save(wav.path, peaks!);

        // Find the entry we just wrote and stamp it back to the old version.
        final entry = Directory(p.join(supportDir.path, 'waveform_cache'))
            .listSync()
            .whereType<File>()
            .single;
        final bytes = await entry.readAsBytes();
        ByteData.sublistView(bytes).setUint32(4, version, Endian.little);
        await entry.writeAsBytes(bytes);

        expect(await WaveformDiskCache.load(wav.path), isNull);
      });
    }

    test('invalidates when the source file changes', () async {
      final path = p.join(tempDir.path, 'changing.wav');
      final wav = await writeWav(path, [buzz(4000, 0.5)]);
      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );
      await WaveformDiskCache.save(wav.path, peaks!);
      expect(await WaveformDiskCache.load(wav.path), isNotNull);

      // Rewrite with different content, stamping the mtime explicitly rather
      // than sleeping past the filesystem's timestamp granularity.
      await writeWav(path, [buzz(4000, 0.9)]);
      File(path).setLastModifiedSync(
        DateTime.now().add(const Duration(seconds: 5)),
      );

      expect(await WaveformDiskCache.load(wav.path), isNull);
    });

    // A copy or a sync tool can carry the old modification time over to new
    // audio; the size is what still tells them apart.
    test('invalidates when the size changes but the mtime is kept', () async {
      final path = p.join(tempDir.path, 'resynced.wav');
      final wav = await writeWav(path, [buzz(4000, 0.5)]);
      final mtime = File(path).lastModifiedSync();
      final peaks = await AudioAnalysisService.extractWaveformPeaks(
        wav.path,
        targetFrames: 200,
      );
      await WaveformDiskCache.save(wav.path, peaks!);

      await writeWav(path, [buzz(6000, 0.9)]);
      File(path).setLastModifiedSync(mtime);

      expect(await WaveformDiskCache.load(wav.path), isNull);
    });
  });

  group('waveformCacheProvider', () {
    late Directory supportDir;

    setUp(() async {
      supportDir = await Directory.systemTemp.createTemp('waveform_cache_test_');
      PathProviderPlatform.instance = _FakePathProvider(supportDir.path);
    });

    tearDown(() async {
      if (await supportDir.exists()) await supportDir.delete(recursive: true);
    });

    test('re-extracts a file whose size changed under the same mtime',
        () async {
      final path = p.join(tempDir.path, 'held.wav');
      await writeWav(path, [buzz(4000, 0.5)]);
      final mtime = File(path).lastModifiedSync();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final cache = container.read(waveformCacheProvider.notifier);

      final first = await cache.getOrExtract(path);
      expect(first!.maxValues.reduce(max), closeTo(0.5, 0.001));

      await writeWav(path, [buzz(6000, 0.9)]);
      File(path).setLastModifiedSync(mtime);

      var stale = false;
      final second = await cache.getOrExtract(path, onStale: () => stale = true);
      expect(stale, isTrue);
      expect(second!.maxValues.reduce(max), closeTo(0.9, 0.001));
    });
  });
}
