import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'TournamentRegisterScreen không được cho qua im lặng khi ELO check lỗi',
    () {
      final source = File(
        'lib/features/register/screens/tournament_register_screen.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('ELO check failed silently')));
      expect(source, contains('Không thể kiểm tra ELO'));
    },
  );
}
