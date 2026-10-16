import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'TournamentRegisterScreen không được cho qua im lặng khi ELO check lỗi',
    () {
      final source = File(
        'lib/features/register/screens/tournament_register_screen.dart',
      ).readAsStringSync();
      final viArb = File('lib/l10n/app_vi.arb').readAsStringSync();

      expect(source, isNot(contains('ELO check failed silently')));
      // Lỗi check ELO được gán vào _eloError (hiện thông báo + chặn submit).
      expect(source, contains('_eloError = l10n.registerEloCheckError'));
      expect(source, contains('if (_eloError != null)'));
      // Chuỗi hiển thị nằm trong l10n, không hard-code trong màn.
      expect(viArb, contains('Không thể kiểm tra ELO'));
    },
  );
}
