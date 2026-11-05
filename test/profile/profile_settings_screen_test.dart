import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/auth_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/session_repository.dart';
import 'package:app_quanly_giaidau/domain/usecases/auth/clear_session_use_case.dart';
import 'package:app_quanly_giaidau/features/profile/screens/profile_settings_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/theme_provider.dart' as tp;
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSession implements ISessionRepository {
  _FakeSession(this.events);
  final List<String> events;

  @override
  Future<void> clearAuthTokens() async => events.add('clearAuth');
  @override
  Future<void> clearInviteToken() async => events.add('clearInvite');
  @override
  Future<String?> getSavedInviteToken() async => null;
  @override
  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
  @override
  Future<void> saveInviteToken(String tokenCode) async {}
}

class _FakeAuth implements IAuthRepository {
  _FakeAuth(this.events, {this.fail = false});
  final List<String> events;
  final bool fail;

  @override
  Future<void> logout({required String refreshToken}) async {
    events.add('logout:$refreshToken');
    if (fail) throw Exception('network down');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _RecordingAuthNotifier extends AuthNotifier {
  static int signOuts = 0;

  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);

  @override
  Future<void> signOut({String? reason}) async {
    signOuts++;
  }
}

void main() {
  group('ClearSessionUseCase', () {
    test('revokes the refresh token on the API before clearing local session',
        () async {
      final events = <String>[];
      final useCase = ClearSessionUseCase(
        _FakeSession(events),
        authRepository: _FakeAuth(events),
        readRefreshToken: () async => 'rt-1',
        unregisterDevice: () async => events.add('unregisterDevice'),
      );

      await useCase();

      expect(events, [
        'unregisterDevice',
        'logout:rt-1',
        'clearInvite',
        'clearAuth',
      ]);
    });

    test('still clears the local session when the logout API fails', () async {
      final events = <String>[];
      final useCase = ClearSessionUseCase(
        _FakeSession(events),
        authRepository: _FakeAuth(events, fail: true),
        readRefreshToken: () async => 'rt-1',
        unregisterDevice: () async => throw Exception('push down'),
      );

      await useCase();

      expect(events, contains('clearAuth'));
      expect(events, contains('clearInvite'));
    });

    test('runs device unregister and logout in parallel, clears after both',
        () async {
      final events = <String>[];
      final gate = Completer<void>();
      final useCase = ClearSessionUseCase(
        _FakeSession(events),
        authRepository: _FakeAuth(events),
        readRefreshToken: () async => 'rt-1',
        unregisterDevice: () async {
          events.add('unregister:start');
          await gate.future;
          events.add('unregister:end');
        },
      );

      final done = useCase();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // logout đã chạy dù unregister chưa xong
      expect(events, ['unregister:start', 'logout:rt-1']);
      gate.complete();
      await done;
      expect(events.last, 'clearAuth');
      expect(events.indexOf('unregister:end'),
          lessThan(events.indexOf('clearInvite')));
    });

    test('skips the API call when there is no refresh token', () async {
      final events = <String>[];
      final useCase = ClearSessionUseCase(
        _FakeSession(events),
        authRepository: _FakeAuth(events),
        readRefreshToken: () async => null,
      );

      await useCase();

      expect(events, ['clearInvite', 'clearAuth']);
    });
  });

  group('ProfileSettingsScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'app',
        packageName: 'app.test',
        version: '1.2.3',
        buildNumber: '45',
        buildSignature: '',
      );
      _RecordingAuthNotifier.signOuts = 0;
    });

    Future<ProviderContainer> pump(
      WidgetTester tester, {
      ThemeData? theme,
    }) async {
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
          GoRoute(
            path: '/profile/edit',
            builder: (_, _) => const Scaffold(body: Text('edit-page')),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(_RecordingAuthNotifier.new),
          userProfileProvider.overrideWith(
            (ref) async => const UserProfile(
              id: 'u1',
              fullName: 'Nguyen An',
              email: 'an@example.com',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            theme: theme ?? AppTheme.lightTheme,
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
      return container;
    }

    for (final dark in [false, true]) {
      testWidgets(
        'renders account card and logout in ${dark ? 'dark' : 'light'}',
        (tester) async {
          await pump(
            tester,
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
          );

          expect(find.text('Nguyen An'), findsOneWidget);
          expect(find.text('an@example.com'), findsOneWidget);
          expect(find.text('Đăng xuất'), findsOneWidget);
          expect(find.text('Chế độ tối'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('tapping the account card opens /profile/edit', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Nguyen An'));
      await tester.pumpAndSettle();

      expect(find.text('edit-page'), findsOneWidget);
    });

    testWidgets('dark mode switch toggles the theme', (tester) async {
      final container = await pump(tester);
      expect(container.read(tp.themeProvider), isNot(ThemeMode.dark));

      await tester.tap(find.byKey(const ValueKey('settings-dark-switch')));
      await tester.pump();

      expect(container.read(tp.themeProvider), ThemeMode.dark);
    });

    testWidgets('logout asks for confirmation; cancel keeps the session',
        (tester) async {
      await pump(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('settings-logout')));
      await tester.tap(find.byKey(const ValueKey('settings-logout')));
      await tester.pumpAndSettle();
      expect(find.text('Đăng xuất?'), findsOneWidget);

      await tester.tap(find.text('Hủy bỏ'));
      await tester.pumpAndSettle();

      expect(_RecordingAuthNotifier.signOuts, 0);
      expect(find.text('Đăng xuất?'), findsNothing);
    });

    testWidgets('confirming logout signs out and goes to /home',
        (tester) async {
      await pump(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('settings-logout')));
      await tester.tap(find.byKey(const ValueKey('settings-logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('settings-logout-confirm')));
      await tester.pumpAndSettle();

      expect(_RecordingAuthNotifier.signOuts, 1);
      expect(find.text('home-page'), findsOneWidget);
    });
  });
}
