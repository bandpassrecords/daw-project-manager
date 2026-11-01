import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:daw_project_manager/utils/initial_window_size.dart';

void main() {
  const desired = Size(1800, 1040);
  const minimum = Size(800, 600);

  test('shrinks to a 16" MacBook Pro (1728x1117, minus menu bar and Dock)', () {
    final size = fitInitialWindowSize(
      desired: desired,
      minimum: minimum,
      visible: const Size(1728, 1010),
    );
    expect(size.width, lessThan(1728));
    expect(size.height, lessThan(1010));
  });

  test('keeps the desired size on a screen that holds it', () {
    expect(
      fitInitialWindowSize(
        desired: desired,
        minimum: minimum,
        visible: const Size(2560, 1415),
      ),
      desired,
    );
  });

  test('never goes below the minimum', () {
    expect(
      fitInitialWindowSize(
        desired: desired,
        minimum: minimum,
        visible: const Size(640, 480),
      ),
      minimum,
    );
  });

  test('without a known screen the desired size stands', () {
    expect(fitInitialWindowSize(desired: desired, minimum: minimum), desired);
  });
}
