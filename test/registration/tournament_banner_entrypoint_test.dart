import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Đăng ký từ tournament intro đi qua route /register thật, không mở sheet giả',
    () {
      final intro = File(
        'lib/features/tournament/screens/tournament_intro_screen.dart',
      ).readAsStringSync();
      final banner = File(
        'lib/features/tournament/widgets/tournament_banner.dart',
      ).readAsStringSync();

      // Intro dựng URI đăng ký thật rồi đẩy qua TournamentRegisterBar.
      expect(intro, contains("pathSegments: ['register', tournament.id]"));
      expect(
        intro,
        contains('onRegister: () => context.push(registrationUri)'),
      );
      expect(intro, isNot(contains('TournamentRegistrationSheet')));
      // TournamentBanner không còn CTA đăng ký và không mở sheet giả.
      expect(banner, isNot(contains('TournamentRegistrationSheet')));
      expect(banner, isNot(contains('showModalBottomSheet')));
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
