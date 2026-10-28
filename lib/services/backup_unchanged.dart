import 'dart:convert';

/// The fields a backup carries about the write itself — when, and from which
/// device — rather than about what it holds.
const _aboutTheWrite = {'timestamp', 'device'};

/// Whether [next], the backup this device would write, holds exactly what
/// [onDrive] does. Then there is nothing to upload: every sync used to write
/// the whole backup again, and each write pushed one of the earlier backups
/// out of the history kept for "Recover from an earlier backup".
///
/// Maps compare whatever order their keys are in, lists in order — a list in
/// another order is written, which is never wrong, only a write saved less.
/// Both sides are compared as JSON reads them back, so [next] should be too.
bool backupUnchanged(Map<String, dynamic> onDrive, Map<String, dynamic> next) =>
    _canonical(onDrive) == _canonical(next);

String _canonical(Map<String, dynamic> backup) => jsonEncode(_sorted({
      for (final e in backup.entries)
        if (!_aboutTheWrite.contains(e.key)) e.key: e.value,
    }));

Object? _sorted(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => '$k').toList()..sort();
    return {for (final k in keys) k: _sorted(value[k])};
  }
  if (value is List) return [for (final v in value) _sorted(v)];
  return value;
}
