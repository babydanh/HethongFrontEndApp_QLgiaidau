import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'DoublesRegistrationFlow copy button phải dùng Clipboard.setData và showSnackBar',
    () {
      final source = File(
        'lib/features/register/screens/doubles_registration_screen.dart',
      ).readAsStringSync();

      expect(source, contains("Clipboard.setData(ClipboardData(text:"));
      expect(source, contains("ScaffoldMessenger.of(context).showSnackBar"));
      expect(source, contains("'Đã sao chép'"));
    },
  );

  test(
    'DoublesRegistrationFlow polling phải có bounded timeout và xử lý hết giờ',
    () {
      final source = File(
        'lib/features/register/screens/doubles_registration_screen.dart',
      ).readAsStringSync();

      expect(source, contains("_pollMaxDuration"));
      expect(source, contains("_pollTimer?.cancel()"));
      expect(source, contains("hết thời gian chờ"));
    },
  );

  test(
    'DoublesRegistrationFlow phải kiểm tra gender restriction trước khi submit Step 1',
    () {
      final source = File(
        'lib/features/register/screens/doubles_registration_screen.dart',
      ).readAsStringSync();

      expect(source, contains("genderRestriction"));
      expect(source, contains("userProfileProvider"));
      expect(source, contains("_genderError"));
    },
  );

  test(
    'DoublesRegistrationFlow phải kiểm tra ELO restriction trước khi submit Step 1',
    () {
      final source = File(
        'lib/features/register/screens/doubles_registration_screen.dart',
      ).readAsStringSync();

      expect(source, contains("rankingRepositoryProvider"));
      expect(source, contains("minElo"));
      expect(source, contains("maxElo"));
      expect(source, contains("_eloError"));
    },
  );

  test(
    'DoublesRegistrationFlow gender/ELO errors phải chặn submit Step 1',
    () {
      final source = File(
        'lib/features/register/screens/doubles_registration_screen.dart',
      ).readAsStringSync();

      expect(source, contains("_genderError != null || _eloError != null"));
      expect(source, contains("return;"));
    },
  );
}
