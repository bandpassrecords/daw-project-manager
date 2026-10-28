import 'package:daw_project_manager/services/backup_unchanged.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('when and from where it was written don\'t count', () {
    expect(
      backupUnchanged(
        {'timestamp': '2026-10-01T10:00:00', 'device': 'Laptop', 'projects': [{'id': 'a'}]},
        {'timestamp': '2026-10-29T09:00:00', 'device': 'Desktop', 'projects': [{'id': 'a'}]},
      ),
      isTrue,
    );
  });

  test('a map\'s keys in another order are the same backup', () {
    // A backup written by another build may list its fields in another order.
    expect(
      backupUnchanged(
        {'a': 1, 'b': {'x': 1, 'y': 2}},
        {'b': {'y': 2, 'x': 1}, 'a': 1},
      ),
      isTrue,
    );
  });

  test('anything else changed is a change', () {
    expect(backupUnchanged({'projects': [{'notes': 'a'}]}, {'projects': [{'notes': 'b'}]}), isFalse);
    expect(backupUnchanged({'version': '1.6'}, {'version': '1.7'}), isFalse);
    expect(backupUnchanged({'a': 1}, {'a': 1, 'b': null}), isFalse);
  });

  test('a list in another order is written again — never wrong, only a write saved less', () {
    expect(backupUnchanged({'projects': ['a', 'b']}, {'projects': ['b', 'a']}), isFalse);
  });
}
