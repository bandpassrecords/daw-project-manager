// Flatpak-only replacement for lib/services/in_process_ffmpeg.dart. Never
// reached on Linux: in-process ffmpeg is only used on Android and iOS.
Future<bool> runInProcessFfmpeg(List<String> args) async => false;
