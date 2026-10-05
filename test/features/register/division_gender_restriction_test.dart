import 'package:app_quanly_giaidau/features/register/utils/division_gender_restriction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('division gender requirements', () {
    test('open divisions do not require a profile gender', () {
      expect(requiresGenderProfileForDivision(null), isFalse);
      expect(requiresGenderProfileForDivision('OPEN'), isFalse);
    });

    test('restricted divisions require a profile gender', () {
      expect(requiresGenderProfileForDivision('MALE'), isTrue);
      expect(requiresGenderProfileForDivision('FEMALE'), isTrue);
      expect(requiresGenderProfileForDivision('MIXED'), isTrue);
    });

    test('normalizes the restricted gender values used by registration', () {
      expect(normalizeDivisionGenderRestriction('female'), 'FEMALE');
      expect(normalizeDivisionGenderRestriction('Nam Nữ'), 'MIXED');
    });
  });
}
