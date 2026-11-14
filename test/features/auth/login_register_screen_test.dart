import 'dart:async';

import 'package:app_quanly_giaidau/features/auth/screens/login_register_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// AuthNotifier giả: không đụng token manager, ghi lại lệnh gọi và trả kết quả
/// theo kịch bản (hoặc treo chờ [gate] để kiểm tra trạng thái đang tải).
class _FakeAuth extends AuthNotifier {
  _FakeAuth({this.succeed = false, this.errorMessage, this.gate});

  final bool succeed;
  final String? errorMessage;
  final Completer<void>? gate;
  final List<String> loginCalls = [];
  final List<String> registerCalls = [];

  @override
  AuthState build() => const AuthState();

  Future<bool> _finish() async {
    if (gate != null) await gate!.future;
    state = succeed
        ? const AuthState(status: AuthStatus.authenticated)
        : AuthState(status: AuthStatus.invalid, errorMessage: errorMessage);
    return succeed;
  }

  @override
  Future<bool> loginWithEmailPassword(String email, String password) {
    loginCalls.add('$email|$password');
    return _finish();
  }

  @override
  Future<bool> registerWithEmailPassword(
    String email,
    String password,
    String fullName,
  ) {
    registerCalls.add('$email|$password|$fullName');
    return _finish();
  }
}

Future<_FakeAuth> _pump(
  WidgetTester tester, {
  _FakeAuth? auth,
  String? redirectPath,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fake = auth ?? _FakeAuth();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => LoginRegisterScreen(redirectPath: redirectPath),
      ),
      GoRoute(
        path: '/login-loading',
        builder: (_, state) =>
            Scaffold(body: Text('LOADING extra=${state.extra}')),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const Scaffold(body: Text('FORGOT PAGE')),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('HOME PAGE')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authProvider.overrideWith(() => fake)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData.light(),
      ),
    ),
  );
  await _settle(tester);
  return fake;
}

/// Chờ hoạt ảnh vào và chuyển trang (không dùng pumpAndSettle).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Finder _field(int index) => find.byType(TextFormField).at(index);

Future<void> _tapSubmit(WidgetTester tester, String label) async {
  final button = find.widgetWithText(TextButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await _settle(tester);
}

Future<void> _fillLogin(WidgetTester tester, String email, String pass) async {
  await tester.enterText(_field(0), email);
  await tester.enterText(_field(1), pass);
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  group('LoginRegisterScreen chế độ và form', () {
    testWidgets(
      'mở màn hiện chế độ đăng nhập với hai ô và liên kết quên mật khẩu',
      (tester) async {
        await _pump(tester);

        expect(find.text(l10n.loginTitle), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text(l10n.loginRegister_forgotPassword), findsOneWidget);
        expect(find.text(l10n.noAccount), findsOneWidget);
      },
    );

    testWidgets(
      'bấm Đăng ký ngay chuyển sang đăng ký, thêm ô họ tên, ẩn quên mật khẩu',
      (tester) async {
        await _pump(tester);

        await tester.tap(find.text(l10n.registerNow));
        await _settle(tester);

        expect(find.text(l10n.registerTitle), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(3));
        expect(find.text(l10n.fullNameLabel), findsOneWidget);
        expect(find.text(l10n.loginRegister_forgotPassword), findsNothing);
        expect(find.text(l10n.hasAccount), findsOneWidget);
      },
    );

    testWidgets('từ đăng ký bấm Đăng nhập ngay quay lại đăng nhập', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text(l10n.registerNow));
      await _settle(tester);

      await tester.tap(find.text(l10n.loginRegister_loginNowAction));
      await _settle(tester);

      expect(find.text(l10n.loginTitle), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('nút mắt đổi ô mật khẩu giữa ẩn và hiện', (tester) async {
      await _pump(tester);
      bool obscured() => tester
          .widget<EditableText>(
            find.descendant(of: _field(1), matching: find.byType(EditableText)),
          )
          .obscureText;
      expect(obscured(), isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(obscured(), isFalse);
    });
  });

  group('LoginRegisterScreen kiểm tra dữ liệu nhập', () {
    testWidgets(
      'gửi form trống báo thiếu email và mật khẩu, không gọi đăng nhập',
      (tester) async {
        final auth = await _pump(tester);

        await _tapSubmit(tester, l10n.loginButton);

        expect(find.text(l10n.loginRegister_emailRequired), findsOneWidget);
        expect(find.text(l10n.loginRegister_passwordRequired), findsOneWidget);
        expect(auth.loginCalls, isEmpty);
      },
    );

    testWidgets('email sai định dạng báo email không hợp lệ', (tester) async {
      final auth = await _pump(tester);
      await _fillLogin(tester, 'khong-phai-email', 'matkhau1');

      await _tapSubmit(tester, l10n.loginButton);

      expect(find.text(l10n.loginRegister_emailInvalid), findsOneWidget);
      expect(auth.loginCalls, isEmpty);
    });

    testWidgets('mật khẩu dưới 6 ký tự báo độ dài tối thiểu', (tester) async {
      final auth = await _pump(tester);
      await _fillLogin(tester, 'a@b.vn', '12345');

      await _tapSubmit(tester, l10n.loginButton);

      expect(find.text(l10n.loginRegister_passwordMinLength), findsOneWidget);
      expect(auth.loginCalls, isEmpty);
    });

    testWidgets('đăng ký thiếu họ tên báo lỗi và không gọi đăng ký', (
      tester,
    ) async {
      final auth = await _pump(tester);
      await tester.tap(find.text(l10n.registerNow));
      await _settle(tester);
      await tester.enterText(_field(1), 'a@b.vn');
      await tester.enterText(_field(2), 'matkhau1');

      await _tapSubmit(tester, l10n.registerButton);

      expect(find.text(l10n.loginRegister_fullNameRequired), findsOneWidget);
      expect(auth.registerCalls, isEmpty);
    });
  });

  group('LoginRegisterScreen gửi đăng nhập/đăng ký', () {
    testWidgets(
      'đăng nhập đúng gửi email đã trim và hạ chữ thường rồi sang màn tải kèm redirect',
      (tester) async {
        final auth = await _pump(
          tester,
          auth: _FakeAuth(succeed: true),
          redirectPath: '/tournament/abc',
        );
        await _fillLogin(tester, '  Nguoi.Dung@Mail.VN ', 'matkhau1');

        await _tapSubmit(tester, l10n.loginButton);

        expect(auth.loginCalls, ['nguoi.dung@mail.vn|matkhau1']);
        expect(find.text('LOADING extra=/tournament/abc'), findsOneWidget);
      },
    );

    testWidgets(
      'sai mật khẩu hiện thông báo lỗi từ máy chủ và giữ nguyên form',
      (tester) async {
        await _pump(
          tester,
          auth: _FakeAuth(errorMessage: 'Sai email hoặc mật khẩu'),
        );
        await _fillLogin(tester, 'a@b.vn', 'saimatkhau');

        await _tapSubmit(tester, l10n.loginButton);

        expect(find.text('Sai email hoặc mật khẩu'), findsOneWidget);
        expect(find.text(l10n.loginTitle), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(
                find.widgetWithText(TextButton, l10n.loginButton),
              )
              .onPressed,
          isNotNull,
        );
      },
    );

    testWidgets('đăng nhập thất bại không kèm lý do dùng thông báo mặc định', (
      tester,
    ) async {
      await _pump(tester);
      await _fillLogin(tester, 'a@b.vn', 'matkhau1');

      await _tapSubmit(tester, l10n.loginButton);

      expect(find.text(l10n.loginRegister_loginFailed), findsOneWidget);
    });

    testWidgets('đang chờ phản hồi hiện vòng tải và khoá nút gửi', (
      tester,
    ) async {
      final gate = Completer<void>();
      await _pump(tester, auth: _FakeAuth(gate: gate));
      await _fillLogin(tester, 'a@b.vn', 'matkhau1');

      final button = find.widgetWithText(TextButton, l10n.loginButton);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 300));

      final loadingButton = find.byWidgetPredicate(
        (w) => w is TextButton && w.onPressed == null,
      );
      expect(loadingButton, findsOneWidget);
      expect(
        find.descendant(
          of: loadingButton,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      gate.complete();
      await _settle(tester);
    });

    testWidgets('đăng ký đúng gọi đăng ký với họ tên đã trim', (tester) async {
      final auth = await _pump(tester, auth: _FakeAuth(succeed: true));
      await tester.tap(find.text(l10n.registerNow));
      await _settle(tester);
      await tester.enterText(_field(0), '  Nguyễn Văn A ');
      await tester.enterText(_field(1), 'a@b.vn');
      await tester.enterText(_field(2), 'matkhau1');

      await _tapSubmit(tester, l10n.registerButton);

      expect(auth.registerCalls, ['a@b.vn|matkhau1|Nguyễn Văn A']);
      expect(auth.loginCalls, isEmpty);
    });

    testWidgets('đổi chế độ xoá thông báo lỗi của lần trước', (tester) async {
      await _pump(tester, auth: _FakeAuth(errorMessage: 'Sai mật khẩu'));
      await _fillLogin(tester, 'a@b.vn', 'saimatkhau');
      await _tapSubmit(tester, l10n.loginButton);
      expect(find.text('Sai mật khẩu'), findsOneWidget);

      await tester.tap(find.text(l10n.registerNow));
      await _settle(tester);

      expect(find.text('Sai mật khẩu'), findsNothing);
    });
  });

  group('LoginRegisterScreen đăng nhập mạng xã hội và điều hướng', () {
    testWidgets('nút Google luôn hiện còn nút Apple bị ẩn trên Android', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text(l10n.loginRegister_googleSignInButton), findsOneWidget);
      expect(find.byType(SignInWithAppleButton), findsNothing);
    });

    testWidgets('nút Apple hiện trên iOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await _pump(tester);

        expect(find.byType(SignInWithAppleButton), findsOneWidget);
        expect(
          find.text(l10n.loginRegister_googleSignInButton),
          findsOneWidget,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('bấm Quên mật khẩu mở màn quên mật khẩu', (tester) async {
      await _pump(tester);

      await tester.tap(find.text(l10n.loginRegister_forgotPassword));
      await _settle(tester);

      expect(find.text('FORGOT PAGE'), findsOneWidget);
    });

    testWidgets('bấm Khám phá không cần đăng nhập đi tới trang chủ', (
      tester,
    ) async {
      await _pump(tester);
      final skip = find.text(l10n.exploreWithoutLogin);
      await tester.ensureVisible(skip);

      await tester.tap(skip);
      await _settle(tester);

      expect(find.text('HOME PAGE'), findsOneWidget);
    });
  });
}
