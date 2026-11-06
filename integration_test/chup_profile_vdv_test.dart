import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/chup.dart';

/// Chụp ảnh tab Hồ sơ, Dashboard và Cài đặt bằng tài khoản VĐV (Backend thật).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets('chụp các trang hồ sơ, dashboard, cài đặt của VĐV', (
    tester,
  ) async {
    final chup = await Chup.signIn(
      tester,
      binding,
      email: kPlayerEmail,
      password: kE2ePassword,
      prefix: 'vdv',
    );
    await chup.pages(const [
      '/profile',
      '/profile/settings',
      '/profile/edit',
      '/profile/change-password',
      '/profile/reports',
      '/profile/elo',
      '/notifications',
      '/dashboard',
      '/rankings',
      '/payments',
      '/series',
      '/club-invites',
      '/football-teams',
    ]);
  });
}
