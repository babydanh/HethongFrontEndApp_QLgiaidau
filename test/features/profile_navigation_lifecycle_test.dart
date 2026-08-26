import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile avatar navigation invokes one callback only', () {
    final navSource = File(
      'lib/core/widgets/floating_bottom_nav.dart',
    ).readAsStringSync();

    expect(navSource, contains('onTap: onProfileTap,'));
    expect(navSource, isNot(contains('onTabSelected(2);')));
  });

  test('Home does not navigate to Profile from its build phase', () {
    final homeSource = File(
      'lib/features/home/screens/home_screen.dart',
    ).readAsStringSync();

    expect(homeSource, isNot(contains("context.go('/profile');")));
    expect(homeSource, isNot(contains('_currentIndex == 2')));
  });
}
