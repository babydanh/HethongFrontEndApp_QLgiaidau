import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/profile/screens/profile_settings_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends AuthNotifier {
  static int signOuts = 0;
  static Completer<void>? gate;
  static bool fail = false;

  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);

  @override
  Future<void> signOut({String? reason}) async {
    signOuts++;
    await gate?.future;
    if (fail) throw Exception('signOut boom');
  }
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw DioException.connectionError(
    requestOptions: options,
    reason: 'DioException raw connection detail',
  );

  @override
  void close({bool force = false}) {}
}

Future<AppLocalizations> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'app',
    packageName: 'app.test',
    version: '1.2.3',
    buildNumber: '45',
    buildSignature: '',
  );
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/profile/settings',
    routes: [
      GoRoute(
        path: '/profile/settings',
        builder: (_, _) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('home-page')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authProvider.overrideWith(_Auth.new),
        dioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: 'http://test'))
            ..httpClientAdapter = _FailingAdapter(),
        ),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(id: 'u1', fullName: 'Nguyen An'),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return AppLocalizations.of(
    tester.element(find.byType(ProfileSettingsScreen)),
  )!;
}

Future<void> _startLogout(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('settings-logout')));
  await tester.tap(find.byKey(const ValueKey('settings-logout')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('settings-logout-confirm')));
  await tester.pump();
}

void main() {
  setUp(() {
    _Auth.signOuts = 0;
    _Auth.gate = null;
    _Auth.fail = false;
  });

  testWidgets('signOut lỗi: nút không kẹt, không có lỗi chưa bắt', (
    tester,
  ) async {
    _Auth.fail = true;
    final l10n = await _pump(tester);
    await _startLogout(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('home-page'), findsNothing);
    expect(find.text(l10n.errorParserFallback), findsOneWidget);
    // Nút bấm lại được: mở lại hộp thoại xác nhận.
    await tester.ensureVisible(find.byKey(const ValueKey('settings-logout')));
    await tester.tap(find.byKey(const ValueKey('settings-logout')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsLvLogoutConfirmTitle), findsOneWidget);
  });

  testWidgets('đang đăng xuất thì bấm lại không mở hộp thoại / signOut lần 2', (
    tester,
  ) async {
    _Auth.gate = Completer<void>();
    final l10n = await _pump(tester);
    await _startLogout(tester);

    await tester.tap(
      find.byKey(const ValueKey('settings-logout')),
      warnIfMissed: false,
    );
    // Nút busy có spinner chạy mãi nên không dùng pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.settingsLvLogoutConfirmTitle), findsNothing);
    expect(_Auth.signOuts, 1);

    _Auth.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('home-page'), findsOneWidget);
  });

  testWidgets(
    'kiểm tra cập nhật lỗi hiện thông báo thân thiện, không lộ exception',
    (tester) async {
      await _pump(tester);
      await tester.tap(find.text('Kiểm tra bản cập nhật'));
      await tester.pumpAndSettle();

      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('raw connection'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );
}
