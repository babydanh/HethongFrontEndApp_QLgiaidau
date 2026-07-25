import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'JoinInviteScreen không còn đăng ký trực tiếp qua _join — phải chuyển hướng sang register flow thật',
    () {
      final source = File(
        'lib/features/register/screens/join_invite_screen.dart',
      ).readAsStringSync();

      // Không còn method _join tự gọi API
      expect(source, isNot(contains('void _join')));
      expect(source, isNot(contains('Future<void> _join')));

      // Không còn POST trực tiếp đến /tournaments/join/
      expect(source, isNot(contains("post('/tournaments/join/")));

      // Không còn TextEditingController cho team name (đã chuyển sang register screen)
      expect(source, isNot(contains("_nameCtrl = TextEditingController()")));
      expect(source, isNot(contains("_nameCtrl")));

      // Phải chuyển hướng đến route đăng ký thật có gates
      expect(source, contains("context.go('/register/"));
      expect(source, contains('invite'));
    },
  );

  test(
    'JoinInviteScreen phải parse tournament id từ response và chuyển hướng với inviteCode',
    () {
      final source = File(
        'lib/features/register/screens/join_invite_screen.dart',
      ).readAsStringSync();

      // Phải lấy id từ response data
      expect(source, contains("data['id']"));
      // Phải chuyển hướng kèm invite code
      expect(source, contains("invite="));
      expect(source, contains("widget.inviteCode"));
    },
  );

  test(
    'JoinInviteScreen vẫn giữ được auth gate: chưa đăng nhập thì hiển thị nút đăng nhập',
    () {
      final source = File(
        'lib/features/register/screens/join_invite_screen.dart',
      ).readAsStringSync();

      // Vẫn giữ auth check
      expect(source, contains("authProvider"));
      expect(source, contains("isAuthenticated"));
      expect(source, contains("/login"));
    },
  );
}
