import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/providers/providers.dart';

/// The "Open" action on an "Added to collection" snackbar files a request
/// here; the dashboard switches to the MIDI tab on it and the tab consumes it.
/// (The snackbar and tab wiring themselves need the Hive-backed repository
/// and are not exercised in a widget test.)
void main() {
  test('holds one request until the MIDI tab consumes it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(midiCollectionToOpenProvider.notifier);

    expect(container.read(midiCollectionToOpenProvider), isNull);
    notifier.open('c1');
    expect(container.read(midiCollectionToOpenProvider), 'c1');
    notifier.consumed();
    expect(container.read(midiCollectionToOpenProvider), isNull);
  });

  test('opening the same collection twice notifies again after consumption',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final seen = <String?>[];
    container.listen(midiCollectionToOpenProvider, (_, next) => seen.add(next),
        fireImmediately: false);
    final notifier = container.read(midiCollectionToOpenProvider.notifier);

    notifier.open('c1');
    notifier.consumed();
    notifier.open('c1');
    expect(seen, ['c1', null, 'c1'],
        reason: 'consuming resets it, so a second Open is a fresh request');
  });
}
