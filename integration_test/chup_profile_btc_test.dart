import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/chup.dart';

/// Chụp ảnh tab Hồ sơ, Dashboard và Cài đặt bằng tài khoản BTC (Backend thật).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets('chụp các trang hồ sơ, dashboard, cài đặt của BTC', (
    tester,
  ) async {
    final chup = await Chup.signIn(
      tester,
      binding,
      email: kOrganizerEmail,
      password: kE2ePassword,
      prefix: 'btc',
    );
    await chup.pages(const [
      '/profile',
      '/profile/settings',
      '/profile/edit',
      '/dashboard',
      '/tournaments/create',
      '/payments',
      '/club-invites',
    ]);
  });
}
