import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';
import 'support/chup.dart';

/// Chụp ảnh Hồ sơ, Dashboard và các trang quản trị bằng tài khoản E2E admin1 (ORGANIZER + ADMIN).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets('chụp các trang hồ sơ, dashboard, quản trị của Admin', (
    tester,
  ) async {
    final chup = await Chup.signIn(
      tester,
      binding,
      email: kOrganizerEmail,
      password: kE2ePassword,
      prefix: 'admin',
    );
    await chup.pages(const [
      '/profile',
      '/profile/edit',
      '/dashboard',
      '/admin/clubs',
      '/admin/change-requests',
      '/admin/disputes',
      '/admin/transactions',
      '/admin/verification',
    ], settle: const Duration(seconds: 15));
  });
}
