import 'package:app_quanly_giaidau/core/router/app_router.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_driver.dart';
import 'support/backend_api.dart';

/// Task 4.1: VĐV và BTC đăng nhập bằng form trên app, Backend thật.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeAppForTests);

  testWidgets('VĐV đăng nhập bằng form và vào app với vai trò viewer', (
    tester,
  ) async {
    final container = await pumpApp(tester);
    await ensureSignedOut(tester, container);
    container.read(routerProvider).go('/login');

    await loginWithForm(tester, email: kPlayerEmail, password: kE2ePassword);
    await pumpUntilCondition(
      tester,
      () => container.read(authProvider).isAuthenticated,
      what: 'trạng thái đã đăng nhập của VĐV $kPlayerEmail',
    );

    final auth = container.read(authProvider);
    expect(auth.role, UserRole.viewer, reason: 'PLAYER không có vai trò BTC');
    expect(auth.isOrganizer, isFalse);
    await pumpUntilCondition(
      tester,
      () => find.text('Email hoặc SĐT').evaluate().isEmpty,
      what: 'thoát khỏi màn đăng nhập sau khi đăng nhập thành công',
    );
  });

  testWidgets('TC-APP-PHONE-36 tài khoản chỉ có SĐT đăng nhập bằng form', (
    tester,
  ) async {
    // Unique per run: 03 + 8 digits from the clock, a valid VN mobile prefix.
    final stamp = DateTime.now().millisecondsSinceEpoch % 100000000;
    final phone = '03${stamp.toString().padLeft(8, '0')}';
    await BackendApi().registerAccount(
      phone: phone,
      password: kE2ePassword,
      fullName: 'E2E Phone $stamp',
    );

    final container = await pumpApp(tester);
    await ensureSignedOut(tester, container);
    container.read(routerProvider).go('/login');

    await loginWithForm(tester, email: phone, password: kE2ePassword);
    await pumpUntilCondition(
      tester,
      () => container.read(authProvider).isAuthenticated,
      what: 'trạng thái đã đăng nhập của tài khoản chỉ có SĐT',
    );
    expect(container.read(authProvider).role, UserRole.viewer);
  });

  testWidgets('BTC đăng nhập bằng form và có quyền tổ chức', (tester) async {
    final container = await pumpApp(tester);
    await ensureSignedOut(tester, container);
    container.read(routerProvider).go('/login');

    await loginWithForm(tester, email: kOrganizerEmail, password: kE2ePassword);
    await pumpUntilCondition(
      tester,
      () => container.read(authProvider).isAuthenticated,
      what: 'trạng thái đã đăng nhập của BTC $kOrganizerEmail',
    );

    final auth = container.read(authProvider);
    expect(auth.role, UserRole.organizer);
    expect(auth.isOrganizer, isTrue);
    await pumpUntilCondition(
      tester,
      () => find.text('Email hoặc SĐT').evaluate().isEmpty,
      what: 'thoát khỏi màn đăng nhập sau khi đăng nhập thành công',
    );
  });
}
