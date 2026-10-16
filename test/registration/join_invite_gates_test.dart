import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'InviteCodeJoinScreen không đăng ký trực tiếp, chỉ chuyển hướng sang register flow thật',
    () {
      final source = File(
        'lib/features/register/screens/invite_code_join_screen.dart',
      ).readAsStringSync();

      // Không còn method _join tự gọi API
      expect(source, isNot(contains('void _join')));
      expect(source, isNot(contains('Future<void> _join')));

      // Không POST trực tiếp đến /tournaments/join/
      expect(source, isNot(contains("post('/tournaments/join/")));

      // Không còn TextEditingController cho team name (đã chuyển sang register screen)
      expect(source, isNot(contains('_nameCtrl')));

      // Chuyển hướng đến route đăng ký thật, kèm invite code
      expect(source, contains('context.pushReplacement(route)'));
      expect(source, contains(r"'/register/${t.id}?invite=$code'"));
      expect(source, contains(r"'/lite-join/$code'"));
    },
  );

  test(
    'InviteCodeJoinScreen resolve giải qua repository theo inviteCode rồi chuyển hướng',
    () {
      final source = File(
        'lib/features/register/screens/invite_code_join_screen.dart',
      ).readAsStringSync();

      expect(source, contains('repo.getByInviteCode('));
      expect(source, contains('widget.inviteCode.trim()'));
      expect(source, contains(r'?invite=$code'));
    },
  );

  test(
    'Luồng invite giữ auth gate ở màn đăng ký: chưa đăng nhập thì hiện nút đăng nhập',
    () {
      final source = File(
        'lib/features/register/screens/tournament_register_screen.dart',
      ).readAsStringSync();

      expect(source, contains('authProvider'));
      expect(source, contains('isAuthenticated'));
      expect(source, contains('if (!isAuth) return _buildLoginPrompt(t);'));
      expect(source, contains("'/login?redirect="));
    },
  );
}
