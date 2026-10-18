import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';

/// Test khói: app khởi động trên emulator thật và hiển thị được màn đăng nhập.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets('smoke: mở app và thấy màn đăng nhập', (tester) async {
    final container = await pumpApp(tester);
    container.read(routerProvider).go('/login');

    await pumpUntilFound(
      tester,
      find.text('Địa chỉ Email'),
      what: 'nhãn Địa chỉ Email trên màn đăng nhập',
    );
    await pumpUntilFound(
      tester,
      find.widgetWithText(TextButton, 'Đăng nhập'),
      what: 'nút Đăng nhập (TextButton) trên màn đăng nhập',
    );
  });
}
