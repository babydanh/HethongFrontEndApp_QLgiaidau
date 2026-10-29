import 'dart:ui';

import 'package:app_quanly_giaidau/features/tournament/utils/schedule_gender_tint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('scheduleGenderTint', () {
    test('MALE maps to the blue tint of the web schedule card', () {
      final tint = scheduleGenderTint('MALE');
      expect(tint.stripe, const Color(0xFF2563EB));
      expect(tint.border, const Color(0xFF93C5FD));
      expect(tint.header, const Color(0xFFDBEAFE));
      expect(tint.headerText, const Color(0xFF1E3A8A));
    });

    test('FEMALE maps to pink', () {
      final tint = scheduleGenderTint('FEMALE');
      expect(tint.stripe, const Color(0xFFEC4899));
      expect(tint.border, const Color(0xFFF9A8D4));
      expect(tint.header, const Color(0xFFFCE7F3));
      expect(tint.headerText, const Color(0xFF831843));
    });

    test('MIXED maps to teal', () {
      final tint = scheduleGenderTint('MIXED');
      expect(tint.stripe, const Color(0xFF0D9488));
      expect(tint.border, const Color(0xFF5EEAD4));
      expect(tint.header, const Color(0xFFCCFBF1));
      expect(tint.headerText, const Color(0xFF134E4A));
    });

    test('missing, blank or unknown restriction reads as flexible orange', () {
      for (final value in [null, '', '  ', 'OPEN', 'whatever']) {
        final tint = scheduleGenderTint(value);
        expect(tint.stripe, const Color(0xFFEA580C), reason: '$value');
        expect(tint.border, const Color(0xFFFDBA74), reason: '$value');
        expect(tint.header, const Color(0xFFFFEDD5), reason: '$value');
        expect(tint.headerText, const Color(0xFF7C2D12), reason: '$value');
      }
    });

    test('value is matched case-insensitively and trimmed', () {
      expect(scheduleGenderTint(' male ').stripe, const Color(0xFF2563EB));
      expect(scheduleGenderTint('Female').stripe, const Color(0xFFEC4899));
    });
  });
}
