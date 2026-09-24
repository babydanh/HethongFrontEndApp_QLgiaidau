import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/app_menu_sheet.dart';
import 'package:app_quanly_giaidau/core/widgets/floating_bottom_nav.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this.initialState);

  final AuthState initialState;

  @override
  AuthState build() => initialState;
}

GoRouter _testRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, _) => Scaffold(
        body: const Center(child: Text('home page')),
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: 0,
          onTabSelected: (_) {},
          onMenuTap: () => AppMenuSheet.show(context),
        ),
      ),
    ),
    GoRoute(
      path: '/chat',
      builder: (_, _) => const Scaffold(body: Text('chat destination')),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, _) => const Scaffold(body: Text('profile destination')),
    ),
  ],
);

Widget _testApp({
  required GoRouter router,
  required AuthState authState,
  required bool reduceMotion,
  Locale locale = const Locale('vi'),
  UserProfile? profile,
  bool profileFails = false,
  bool darkTheme = false,
}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _TestAuthNotifier(authState)),
      userProfileProvider.overrideWith((ref) async {
        if (profileFails) throw StateError('profile unavailable');
        return profile ?? const UserProfile(id: 'user-1', fullName: 'Alex');
      }),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      theme: darkTheme ? AppTheme.darkTheme : AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
    ),
  );
}

void main() {
  testWidgets('fifth tab opens a floating menu over the current page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = _testRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _testApp(
        router: router,
        authState: const AuthState(),
        reduceMotion: true,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.text('home page'));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.menuTitle).first);
    await tester.pumpAndSettle();

    expect(find.byType(AppMenuSheet), findsOneWidget);
    expect(find.text('home page'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(
      tester.getSize(find.byType(AppMenuSheet)).width,
      closeTo(390 * 0.72, 1),
    );
    expect(tester.getRect(find.byType(AppMenuSheet)).left, 16);
    expect(find.byKey(const ValueKey('app-menu-/home?tab=3')), findsOneWidget);
    expect(find.text(l10n.profileLoginButton), findsOneWidget);
  });

  testWidgets('member shortcuts navigate to existing routes', (tester) async {
    final router = _testRouter();
    addTearDown(router.dispose);
    const authState = AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.viewer,
    );
    await tester.pumpWidget(
      _testApp(
        router: router,
        authState: authState,
        profile: const UserProfile(id: 'u1', fullName: 'Alex Player'),
        reduceMotion: true,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.text('home page'));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.menuTitle).first);
    await tester.pumpAndSettle();
    expect(find.text(l10n.menuProfile), findsOneWidget);
    expect(find.text(l10n.menuMessages), findsOneWidget);
    expect(find.bySemanticsLabel(l10n.menuMessages), findsOneWidget);
    expect(find.text(l10n.settingsNotifications), findsOneWidget);

    await tester.tap(find.text(l10n.menuMessages));
    await tester.pumpAndSettle();
    expect(find.text('chat destination'), findsOneWidget);
    expect(find.byType(AppMenuSheet), findsNothing);
  });

  testWidgets('profile card keeps the existing profile route reachable', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);
    const authState = AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.viewer,
    );
    await tester.pumpWidget(
      _testApp(
        router: router,
        authState: authState,
        profile: const UserProfile(id: 'u1', fullName: 'Alex Player'),
        reduceMotion: true,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.text('home page'));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.menuTitle).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.menuProfile));
    await tester.pumpAndSettle();

    expect(find.text('profile destination'), findsOneWidget);
  });

  testWidgets('guest menu exposes public routes but not member actions', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _testApp(
        router: router,
        authState: const AuthState(),
        reduceMotion: true,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.text('home page'));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.menuTitle).first);
    await tester.pumpAndSettle();

    expect(find.text(l10n.profileLoginButton), findsOneWidget);
    expect(find.text(l10n.navClubs), findsOneWidget);
    expect(find.byKey(const ValueKey('app-menu-/home?tab=1')), findsOneWidget);
    expect(find.text(l10n.menuMessages), findsNothing);
    expect(find.text(l10n.settingsPaymentHistory), findsNothing);
  });

  testWidgets('profile request failure falls back without hiding navigation', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);
    const authState = AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.viewer,
    );
    await tester.pumpWidget(
      _testApp(
        router: router,
        authState: authState,
        profileFails: true,
        reduceMotion: true,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.text('home page'));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.menuTitle).first);
    await tester.pumpAndSettle();

    expect(find.text(l10n.routerDefaultUser), findsOneWidget);
    expect(find.text(l10n.menuMessages), findsOneWidget);
  });

  testWidgets('reduced motion renders menu rows without entrance transitions', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);
    const authState = AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.viewer,
    );
    await tester.pumpWidget(
      _testApp(router: router, authState: authState, reduceMotion: true),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.text('home page'));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.menuTitle).first);
    await tester.pumpAndSettle();

    final row = find.text(l10n.menuMessages);
    expect(
      find.ancestor(of: row, matching: find.byType(FadeTransition)),
      findsNothing,
    );
  });

  testWidgets('menu labels resolve in English', (tester) async {
    final router = _testRouter();
    addTearDown(router.dispose);
    const authState = AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.viewer,
    );
    await tester.pumpWidget(
      _testApp(
        router: router,
        authState: authState,
        reduceMotion: true,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Menu').first);
    await tester.pumpAndSettle();

    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
  testWidgets(
    'member sheet scrolls and inherits dark theme on compact screens',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = _testRouter();
      addTearDown(router.dispose);
      const authState = AuthState(
        status: AuthStatus.authenticated,
        role: UserRole.viewer,
      );
      await tester.pumpWidget(
        _testApp(
          router: router,
          authState: authState,
          reduceMotion: true,
          darkTheme: true,
          profile: const UserProfile(id: 'u1', fullName: 'Alex Player'),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.text('home page'));
      final l10n = AppLocalizations.of(context)!;
      await tester.tap(find.text(l10n.menuTitle).first);
      await tester.pumpAndSettle();

      expect(
        Theme.of(tester.element(find.byType(AppMenuSheet))).brightness,
        Brightness.dark,
      );
      await tester.ensureVisible(find.text(l10n.settingsTitle));
      expect(find.text(l10n.settingsTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('invalid avatar falls back without hiding menu actions', (
    tester,
  ) async {
    final router = _testRouter();
    addTearDown(router.dispose);
    const authState = AuthState(
      status: AuthStatus.authenticated,
      role: UserRole.viewer,
    );
    await tester.pumpWidget(
      _testApp(
        router: router,
        authState: authState,
        reduceMotion: true,
        profile: const UserProfile(
          id: 'u1',
          fullName: 'Alex Player',
          avatarUrl: 'https://avatar.invalid/menu.png',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.text('home page'));
    final l10n = AppLocalizations.of(context)!;
    await tester.tap(find.text(l10n.menuTitle).first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    expect(find.text(l10n.menuMessages), findsOneWidget);
  });
}
