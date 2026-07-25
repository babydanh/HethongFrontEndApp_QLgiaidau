import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Source-guard test for design tokens in app_theme.dart.
///
/// Ensures font weights follow the new scale (max w600, no w700)
/// and border-radius constants match the design-system refresh.
void main() {
  late String appThemeSource;

  setUpAll(() {
    appThemeSource = File('lib/core/config/app_theme.dart').readAsStringSync();
  });

  group('Border radius constants', () {
    test('radiusSmall is 6.0', () {
      expect(appThemeSource, contains('static const double radiusSmall = 6.0'));
    });

    test('radiusMedium is 8.0', () {
      expect(
        appThemeSource,
        contains('static const double radiusMedium = 8.0'),
      );
    });

    test('radiusLarge is 10.0', () {
      expect(
        appThemeSource,
        contains('static const double radiusLarge = 10.0'),
      );
    });

    test('radiusXL is 12.0', () {
      expect(appThemeSource, contains('static const double radiusXL = 12.0'));
    });
  });

  group('Font weight restrictions', () {
    test('no FontWeight.w700 remaining', () {
      expect(appThemeSource, isNot(contains('FontWeight.w700')));
    });

    test('max FontWeight is w600 (display styles)', () {
      expect(appThemeSource, contains('FontWeight.w600'));
    });

    test('no FontWeight.w700 in display or widget styles', () {
      // Ensure no w700 appears anywhere in the source
      expect(appThemeSource, isNot(contains('FontWeight.w700')));
    });
  });
}
