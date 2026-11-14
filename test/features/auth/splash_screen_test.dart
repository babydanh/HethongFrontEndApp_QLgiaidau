import 'dart:async';

import 'package:app_quanly_giaidau/features/auth/screens/splash_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// AuthNotifier giả: `init()` đặt trạng thái định sẵn (hoặc treo / ném lỗi).
class _FakeAuth extends AuthNotifier {
  _FakeAuth({
    this.afterInit = const AuthState(),
    this.hang = false,
    this.fail = false,
  });

  final AuthState afterInit;
  final bool hang;
  final bool fail;
  int initCalls = 0;

  @override
  AuthState build() => const AuthState();

  @override
  Future<void> init() async {
    initCalls++;
    if (hang) return Completer<void>().future;
    if (fail) throw StateError('init hỏng');
    state = afterInit;
  }
}

Future<_FakeAuth> _pump(WidgetTester tester, _FakeAuth auth) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('AT /home')),
      ),
      GoRoute(
        path: '/admin/tournament/:id',
        builder: (_, state) => Scaffold(
          body: Text('AT /admin/tournament/${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/referee',
        builder: (_, _) => const Scaffold(body: Text('AT /referee')),
      ),
      GoRoute(
        path: '/viewer',
        builder: (_, _) => const Scaffold(body: Text('AT /viewer')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authProvider.overrideWith(() => auth)],
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
  return auth;
}

/// Qua mốc 1,5 giây của splash rồi cho chuyển trang chạy xong.
Future<void> _waitForNavigation(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1600));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

AuthState _authed(UserRole role, {String? tournamentId}) => AuthState(
  status: AuthStatus.authenticated,
  role: role,
  tournamentId: tournamentId,
  tokenCode: 'SESSION',
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  testWidgets(
    'hiện khẩu hiệu và chưa điều hướng hay khởi tạo auth trước 1,5 giây',
    (tester) async {
      final auth = await _pump(tester, _FakeAuth());
      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text(l10n.appTagline), findsOneWidget);
      expect(auth.initCalls, 0);
      expect(find.text('AT /home'), findsNothing);

      await _waitForNavigation(tester);
    },
  );

  testWidgets('chưa đăng nhập thì sau khi init chuyển tới /home', (
    tester,
  ) async {
    final auth = await _pump(tester, _FakeAuth());

    await _waitForNavigation(tester);

    expect(auth.initCalls, 1);
    expect(find.text('AT /home'), findsOneWidget);
  });

  testWidgets('admin có tournamentId chuyển tới màn quản trị giải đó', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeAuth(afterInit: _authed(UserRole.admin, tournamentId: 't-42')),
    );

    await _waitForNavigation(tester);

    expect(find.text('AT /admin/tournament/t-42'), findsOneWidget);
  });

  testWidgets('trọng tài có tournamentId chuyển tới /referee', (tester) async {
    await _pump(
      tester,
      _FakeAuth(afterInit: _authed(UserRole.referee, tournamentId: 't-1')),
    );

    await _waitForNavigation(tester);

    expect(find.text('AT /referee'), findsOneWidget);
  });

  testWidgets('người xem có tournamentId chuyển tới /viewer', (tester) async {
    await _pump(
      tester,
      _FakeAuth(afterInit: _authed(UserRole.viewer, tournamentId: 't-1')),
    );

    await _waitForNavigation(tester);

    expect(find.text('AT /viewer'), findsOneWidget);
  });

  testWidgets('ban tổ chức có tournamentId vẫn về /home', (tester) async {
    await _pump(
      tester,
      _FakeAuth(afterInit: _authed(UserRole.organizer, tournamentId: 't-1')),
    );

    await _waitForNavigation(tester);

    expect(find.text('AT /home'), findsOneWidget);
  });

  testWidgets('đã đăng nhập nhưng không có tournamentId thì về /home', (
    tester,
  ) async {
    await _pump(tester, _FakeAuth(afterInit: _authed(UserRole.admin)));

    await _waitForNavigation(tester);

    expect(find.text('AT /home'), findsOneWidget);
    expect(find.text('AT /admin/tournament/null'), findsNothing);
  });

  testWidgets('init treo quá 4 giây thì bỏ chờ và vẫn về /home', (
    tester,
  ) async {
    await _pump(tester, _FakeAuth(hang: true));

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('AT /home'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(find.text('AT /home'), findsOneWidget);
  });

  testWidgets('init ném lỗi thì splash không crash và về /home', (
    tester,
  ) async {
    await _pump(tester, _FakeAuth(fail: true));

    await _waitForNavigation(tester);

    expect(find.text('AT /home'), findsOneWidget);
  });

  testWidgets('rời màn trước 1,5 giây thì huỷ hẹn giờ, không khởi tạo auth', (
    tester,
  ) async {
    final auth = await _pump(tester, _FakeAuth());

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));

    expect(auth.initCalls, 0);
  });
}
