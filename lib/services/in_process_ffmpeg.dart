import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:flutter/foundation.dart';

/// Runs ffmpeg inside the app process (Android/iOS only). The Flatpak build
/// replaces this file with flatpak/in_process_ffmpeg_stub.dart so the
/// ffmpeg-kit package is not needed there at all.
Future<bool> runInProcessFfmpeg(List<String> args) async {
  final session = await FFmpegKit.executeWithArguments(args);
  final returnCode = await session.getReturnCode();
  if (ReturnCode.isSuccess(returnCode)) return true;
  debugPrint(
    '[ShareConvert] ffmpeg-kit failed (${returnCode?.getValue()}): '
    '${await session.getOutput()}',
  );
  return false;
}
