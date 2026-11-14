import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/features/auth/screens/reset_password_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_api_adapter.dart';

const _resetRoute = 'POST /auth/reset-password';

Future<FakeApiAdapter> _pump(
  WidgetTester tester,
  Map<String, FakeReply> routes,
) async {
  final adapter = FakeApiAdapter(routes);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const ResetPasswordScreen(token: 'tok-123'),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('LOGIN PAGE')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dioClientProvider.overrideWithValue(fakeDioClient(adapter))],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData.light(),
      ),
    ),
  );
  await tester.pump();
  return adapter;
}

Future<void> _fillAndSubmit(
  WidgetTester tester, {
  required String password,
  required String confirm,
}) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), password);
  await tester.enterText(fields.at(1), confirm);
  await tester.tap(find.byType(ElevatedButton));
  // runAsync cho phép future giả của Dio hoàn tất.
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  testWidgets('mật khẩu dưới 6 ký tự báo lỗi độ dài và không gọi API', (
    tester,
  ) async {
    final adapter = await _pump(tester, {});

    await _fillAndSubmit(tester, password: '12345', confirm: '12345');

    expect(find.text(l10n.resetPassword_minLengthError), findsOneWidget);
    expect(adapter.postsTo('/auth/reset-password'), isEmpty);
  });

  testWidgets('mật khẩu xác nhận không khớp báo lỗi và không gọi API', (
    tester,
  ) async {
    final adapter = await _pump(tester, {});

    await _fillAndSubmit(tester, password: 'matkhau1', confirm: 'matkhau2');

    expect(find.text(l10n.resetPassword_mismatchError), findsOneWidget);
    expect(adapter.postsTo('/auth/reset-password'), isEmpty);
  });

  testWidgets(
    'đặt lại thành công gửi token cùng mật khẩu rồi hiện màn thành công',
    (tester) async {
      final adapter = await _pump(tester, {
        _resetRoute: const FakeReply(200, {'data': {}}),
      });

      await _fillAndSubmit(tester, password: 'matkhau1', confirm: 'matkhau1');

      expect(adapter.postsTo('/auth/reset-password').single.body, {
        'token': 'tok-123',
        'password': 'matkhau1',
      });
      expect(find.text(l10n.resetPassword_successTitle), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets('từ màn thành công bấm Đăng nhập chuyển sang trang đăng nhập', (
    tester,
  ) async {
    await _pump(tester, {
      _resetRoute: const FakeReply(200, {'data': {}}),
    });
    await _fillAndSubmit(tester, password: 'matkhau1', confirm: 'matkhau1');

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('LOGIN PAGE'), findsOneWidget);
  });

  testWidgets(
    'token hết hạn (400) hiện thông báo lỗi và giữ nguyên form để thử lại',
    (tester) async {
      await _pump(tester, {
        _resetRoute: const FakeReply(400, {'message': 'Token đã hết hạn'}),
      });

      await _fillAndSubmit(tester, password: 'matkhau1', confirm: 'matkhau1');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(l10n.resetPassword_successTitle), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    },
  );
}
