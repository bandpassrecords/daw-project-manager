import 'package:daw_project_manager/utils/first_connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firstConnectionStaysManual', () {
    test('a device that never synced and never chose starts manual', () {
      expect(
        firstConnectionStaysManual(
          syncedBefore: false,
          startupChoiceStored: false,
        ),
        isTrue,
      );
    });

    test('a device that has synced is left as it is', () {
      expect(
        firstConnectionStaysManual(
          syncedBefore: true,
          startupChoiceStored: false,
        ),
        isFalse,
      );
    });

    test('a choice the user already made is never overwritten', () {
      expect(
        firstConnectionStaysManual(
          syncedBefore: false,
          startupChoiceStored: true,
        ),
        isFalse,
      );
    });
  });
}
