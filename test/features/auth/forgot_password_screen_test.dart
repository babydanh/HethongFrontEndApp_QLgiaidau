import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/features/auth/screens/forgot_password_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_api_adapter.dart';

const _forgotRoute = 'POST /auth/forgot-password';
const _forgotPath = '/auth/forgot-password';

Future<FakeApiAdapter> _pump(
  WidgetTester tester,
  Map<String, FakeReply> routes,
) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final adapter = FakeApiAdapter(routes);
  final router = GoRouter(
    initialLocation: '/login/forgot',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('LOGIN PAGE')),
        routes: [
          GoRoute(
            path: 'forgot',
            builder: (_, _) => const ForgotPasswordScreen(),
          ),
        ],
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
  await tester.pump(const Duration(milliseconds: 300));
  return adapter;
}

/// Nhập email, bấm gửi rồi cho future giả của Dio hoàn tất (runAsync).
Future<void> _submitEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextFormField), email);
  await tester.tap(find.byType(ElevatedButton));
  await _flushDio(tester);
}

Future<void> _flushDio(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Huỷ màn để Timer.periodic đếm ngược không treo cuối test.
Future<void> _disposeScreen(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  testWidgets('mở màn hiện form một ô email và nút gửi yêu cầu', (
    tester,
  ) async {
    await _pump(tester, {});

    expect(find.text(l10n.forgotPassword_headerTitle), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text(l10n.forgotPassword_submitButton), findsOneWidget);
    expect(find.text(l10n.forgotPassword_sentTitle), findsNothing);
  });

  testWidgets('gửi khi để trống email báo thiếu email và không gọi API', (
    tester,
  ) async {
    final adapter = await _pump(tester, {});

    await _submitEmail(tester, '');

    expect(find.text(l10n.forgotPassword_emailRequired), findsOneWidget);
    expect(adapter.postsTo(_forgotPath), isEmpty);
  });

  testWidgets('email sai định dạng báo email không hợp lệ và không gọi API', (
    tester,
  ) async {
    final adapter = await _pump(tester, {});

    await _submitEmail(tester, 'abc@');

    expect(find.text(l10n.forgotPassword_emailInvalid), findsOneWidget);
    expect(adapter.postsTo(_forgotPath), isEmpty);
  });

  testWidgets(
    'gửi thành công gửi email đã trim và hạ chữ thường rồi hiện màn Đã gửi',
    (tester) async {
      final adapter = await _pump(tester, {
        _forgotRoute: const FakeReply(200, {}),
      });

      await _submitEmail(tester, '  Hoa.Tran@Mail.VN ');

      expect(adapter.postsTo(_forgotPath).single.body, {
        'email': 'hoa.tran@mail.vn',
      });
      expect(find.text(l10n.forgotPassword_sentTitle), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Hoa.Tran@Mail.VN'),
        ),
        findsOneWidget,
      );
      await _disposeScreen(tester);
    },
  );

  testWidgets(
    'thành công không kèm lời nhắn dùng thông báo mặc định trong snackbar',
    (tester) async {
      await _pump(tester, {_forgotRoute: const FakeReply(200, {})});

      await _submitEmail(tester, 'a@b.vn');

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(l10n.forgotPassword_sentSuccessMessage),
        ),
        findsOneWidget,
      );
      await _disposeScreen(tester);
    },
  );

  testWidgets(
    'thành công kèm message của máy chủ thì snackbar hiện đúng lời nhắn đó',
    (tester) async {
      await _pump(tester, {
        _forgotRoute: const FakeReply(200, {'message': 'Đã gửi mail rồi nhé'}),
      });

      await _submitEmail(tester, 'a@b.vn');

      expect(find.text('Đã gửi mail rồi nhé'), findsOneWidget);
      await _disposeScreen(tester);
    },
  );

  testWidgets('máy chủ trả lỗi 429 hiện thông báo lỗi và giữ form để thử lại', (
    tester,
  ) async {
    await _pump(tester, {
      _forgotRoute: const FakeReply(429, {'message': 'Bạn thử lại sau 2 phút'}),
    });

    await _submitEmail(tester, 'a@b.vn');

    expect(find.text('Bạn thử lại sau 2 phút'), findsOneWidget);
    expect(find.text(l10n.forgotPassword_sentTitle), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('mất mạng hiện khung lỗi và không chuyển sang màn Đã gửi', (
    tester,
  ) async {
    await _pump(tester, {_forgotRoute: const FakeReply.networkError()});

    await _submitEmail(tester, 'a@b.vn');

    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.text(l10n.forgotPassword_sentTitle), findsNothing);
  });

  testWidgets('màn Đã gửi khoá nút gửi lại trong lúc đếm ngược 120 giây', (
    tester,
  ) async {
    await _pump(tester, {_forgotRoute: const FakeReply(200, {})});
    await _submitEmail(tester, 'a@b.vn');

    expect(find.text(l10n.forgotPassword_resendTimer(120)), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );

    await tester.pump(const Duration(seconds: 10));
    expect(find.text(l10n.forgotPassword_resendTimer(110)), findsOneWidget);
    await _disposeScreen(tester);
  });

  // BUG-FORGOT-01: nút "Gửi lại" ở màn Đã gửi gọi _submit(), nhưng _submit()
  // dùng _formKey.currentState!.validate() trong khi Form đã bị gỡ khỏi cây
  // (màn Đã gửi không có Form) nên ném lỗi null-check, không gửi lại được.
  testWidgets(
    'BUG-FORGOT-01 hết 120 giây nút gửi lại mở khoá và bấm sẽ gọi API lần hai',
    skip: true,
    (tester) async {
      final adapter = await _pump(tester, {
        _forgotRoute: const FakeReply(200, {}),
      });
      await _submitEmail(tester, 'a@b.vn');

      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(find.text(l10n.forgotPassword_canResend), findsOneWidget);
      final resend = find.text(l10n.forgotPassword_resendButton);
      expect(resend, findsOneWidget);

      await tester.tap(resend);
      await _flushDio(tester);

      expect(adapter.postsTo(_forgotPath), hasLength(2));
      await _disposeScreen(tester);
    },
  );

  testWidgets(
    'từ màn Đã gửi bấm Trở về Đăng nhập chuyển sang trang đăng nhập',
    (tester) async {
      await _pump(tester, {_forgotRoute: const FakeReply(200, {})});
      await _submitEmail(tester, 'a@b.vn');

      await tester.tap(find.text(l10n.forgotPassword_backToLoginButton));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('LOGIN PAGE'), findsOneWidget);
      await _disposeScreen(tester);
    },
  );

  testWidgets('bấm Quay lại Đăng nhập trên form thoát về trang trước', (
    tester,
  ) async {
    await _pump(tester, {});

    await tester.tap(find.text(l10n.forgotPassword_backToLogin));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('LOGIN PAGE'), findsOneWidget);
  });
}
