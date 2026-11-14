import 'dart:async';

import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/auth/screens/login_loading_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _redirectDelay = Duration(milliseconds: 2200);

Future<void> _pump(
  WidgetTester tester, {
  String? redirectPath,
  FutureOr<UserProfile> Function()? profile,
  List<String>? visited,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => LoginLoadingScreen(redirectPath: redirectPath),
      ),
      for (final path in ['/home', '/join-team', '/intro/t1', '/login'])
        GoRoute(
          path: path,
          builder: (_, state) {
            visited?.add(state.uri.toString());
            return Scaffold(body: Text('AT ${state.uri}'));
          },
        ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        userProfileProvider.overrideWith(
          (ref) async =>
              profile?.call() ??
              const UserProfile(id: 'u1', fullName: 'Nguyễn Văn An'),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        theme: ThemeData.light(),
      ),
    ),
  );
}

/// Qua mốc chuyển trang 2,2 giây rồi cho transition chạy hết.
Future<void> _waitForRedirect(WidgetTester tester) async {
  await tester.pump(_redirectDelay + const Duration(milliseconds: 50));
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('vi'));

  testWidgets('hồ sơ đã tải: chào mừng quay lại kèm tên đầy đủ', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(l10n.loginLoading_welcomeBack), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text(l10n.loginLoading_defaultUserName), findsNothing);

    await _waitForRedirect(tester);
  });

  testWidgets('hồ sơ chưa có tên: dùng tên mặc định Vận động viên', (
    tester,
  ) async {
    await _pump(tester, profile: () => const UserProfile(id: 'u2'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(l10n.loginLoading_defaultUserName), findsOneWidget);

    await _waitForRedirect(tester);
  });

  testWidgets('đang tải hồ sơ: hiện vòng quay, chưa có lời chào', (
    tester,
  ) async {
    final gate = Completer<UserProfile>();
    await _pump(tester, profile: () => gate.future);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
    expect(find.text(l10n.loginLoading_welcomeBack), findsNothing);

    gate.complete(const UserProfile(id: 'u1', fullName: 'Chậm Một Chút'));
    await _waitForRedirect(tester);
  });

  testWidgets('tải hồ sơ lỗi: báo Đăng nhập thành công thay vì lời chào', (
    tester,
  ) async {
    await _pump(tester, profile: () => throw StateError('hồ sơ hỏng'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(l10n.loginLoading_loginSuccess), findsOneWidget);
    expect(find.text(l10n.loginLoading_welcomeBack), findsNothing);

    await _waitForRedirect(tester);
  });

  testWidgets('không có redirectPath: sau 2,2 giây chuyển về /home', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.text('AT /home'), findsNothing);

    await _waitForRedirect(tester);

    expect(find.text('AT /home'), findsOneWidget);
  });

  testWidgets(
    'redirectPath hợp lệ (bắt đầu bằng /): chuyển tới đúng đường dẫn kèm query',
    (tester) async {
      await _pump(
        tester,
        redirectPath: '/join-team?tournamentId=t1&pid=p1&token=ABC',
      );

      await _waitForRedirect(tester);

      expect(
        find.text('AT /join-team?tournamentId=t1&pid=p1&token=ABC'),
        findsOneWidget,
      );
      expect(find.text('AT /home'), findsNothing);
    },
  );

  testWidgets(
    'redirectPath dạng URL ngoài (không bắt đầu bằng /): bỏ qua, về /home',
    (tester) async {
      await _pump(tester, redirectPath: 'https://evil.example/phish');

      await _waitForRedirect(tester);

      expect(find.text('AT /home'), findsOneWidget);
    },
  );

  testWidgets('redirectPath rỗng: về /home', (tester) async {
    await _pump(tester, redirectPath: '');

    await _waitForRedirect(tester);

    expect(find.text('AT /home'), findsOneWidget);
  });

  testWidgets('rời màn trước 2,2 giây: không điều hướng muộn, không lỗi', (
    tester,
  ) async {
    final visited = <String>[];
    await _pump(tester, visited: visited);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(_redirectDelay + const Duration(seconds: 1));

    expect(visited, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chỉ điều hướng đúng một lần', (tester) async {
    final visited = <String>[];
    await _pump(tester, visited: visited);

    await _waitForRedirect(tester);
    await tester.pump(const Duration(seconds: 5));

    expect(visited.where((p) => p == '/home'), hasLength(1));
  });
}
