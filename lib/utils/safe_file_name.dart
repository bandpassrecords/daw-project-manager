import 'package:path/path.dart' as p;

/// File names made from data that came from outside the app — a backup file,
/// a Drive backup — where an id or a file name is text anyone could have
/// written. A backup whose project id was `..\..\Startup\x` once could write
/// its own bytes to `x_cover.bat` wherever that led; everything here keeps a
/// write inside the folder it was meant for.

/// Characters that make a name more than one plain segment: separators on
/// any platform, a drive or alternate-stream colon, and control characters.
final RegExp _unsafeNameChars = RegExp(r'[/\\:\x00-\x1f]');

/// A file extension (".jpg") that is safe to append to a name, or [fallback]
/// when [extension] is missing or anything but a dot and a few letters and
/// digits.
String safeExtension(String? extension, {required String fallback}) {
  if (extension == null) return fallback;
  return RegExp(r'^\.[A-Za-z0-9]{1,10}$').hasMatch(extension) ? extension : fallback;
}

/// [name] inside [folder], or null when [name] isn't one plain file name:
/// empty, all dots, too long, or carrying a separator, a colon or a control
/// character. The joined path is checked to stay inside [folder] too.
String? safeFileIn(String folder, String name) {
  if (name.isEmpty || name.length > 200) return null;
  if (_unsafeNameChars.hasMatch(name)) return null;
  if (RegExp(r'^\.+$').hasMatch(name)) return null;
  final joined = p.join(folder, name);
  return p.isWithin(p.normalize(folder), p.normalize(joined)) ? joined : null;
}
