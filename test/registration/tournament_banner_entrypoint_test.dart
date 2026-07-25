import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'TournamentBanner đăng ký phải đi qua route đăng ký thật, không mở sheet giả',
    () {
      final source = File(
        'lib/features/tournament/widgets/tournament_banner.dart',
      ).readAsStringSync();

      expect(
        source,
        contains("context.push('/register/\${widget.tournament.id}')"),
      );
      expect(source, isNot(contains('TournamentRegistrationSheet')));
      expect(source, isNot(contains('showModalBottomSheet')));
    },
  );

  test('TournamentRegistrationSheet không còn submit giả thành công', () {
    final source = File(
      'lib/features/tournament/widgets/tournament_registration_sheet.dart',
    ).readAsStringSync();

    expect(source, contains("context.push('/register/\${tournament.id}')"));
    expect(source, isNot(contains('Future.delayed')));
    expect(source, isNot(contains('Đăng ký tham gia giải đấu thành công')));
  });
}
