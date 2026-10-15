import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/features/profile/screens/profile_settings_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this.initialState);

  final AuthState initialState;

  @override
  AuthState build() => initialState;
}

GoRouter _router() => GoRouter(
  initialLocation: '/profile/settings',
  routes: [
    GoRoute(
      path: '/profile/settings',
      builder: (_, _) => const ProfileSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (_, _) => const Scaffold(body: Text('edit destination')),
    ),
    GoRoute(
      path: '/profile/reports',
      builder: (_, _) => const Scaffold(body: Text('reports destination')),
    ),
  ],
);

Future<AppLocalizations> _pumpSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  PackageInfo.setMockInitialValues(
    appName: 'Test',
    packageName: 'test.app',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  tester.view.physicalSize = const Size(430, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = _router();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(
          () => _TestAuthNotifier(
            const AuthState(
              status: AuthStatus.authenticated,
              role: UserRole.viewer,
            ),
          ),
        ),
        userProfileProvider.overrideWith(
          (ref) async =>
              const UserProfile(id: 'user-1', fullName: 'Alex Player'),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return AppLocalizations.of(
    tester.element(find.byType(ProfileSettingsScreen)),
  )!;
}

void main() {
  testWidgets('Cài đặt có nhóm Tài khoản, Ứng dụng; Lối tắt đóng sẵn', (
    tester,
  ) async {
    final l10n = await _pumpSettings(tester);

    expect(find.text(l10n.accountSettingsAccountSection), findsOneWidget);
    expect(find.text(l10n.accountSettingsPersonalProfile), findsOneWidget);
    expect(find.text(l10n.accountSettingsAppSection), findsOneWidget);
    expect(find.text(l10n.settingsLanguage), findsOneWidget);
    expect(find.text(l10n.settingsDarkMode), findsOneWidget);
    expect(find.text(l10n.settingsNotifications), findsOneWidget);
    expect(find.text(l10n.coreCheckForUpdate), findsOneWidget);

    final shortcuts = tester.widget<ExpansionTile>(
      find.widgetWithText(ExpansionTile, l10n.accountSettingsShortcuts),
    );
    expect(shortcuts.initiallyExpanded, isFalse);
    expect(find.text(l10n.myReportsTitle), findsNothing);
    expect(find.text(l10n.settingsLogout), findsOneWidget);
  });

  testWidgets('Lối tắt chứa đủ mục điều hướng và Báo cáo của tôi', (
    tester,
  ) async {
    final l10n = await _pumpSettings(tester);

    await tester.tap(find.text(l10n.accountSettingsShortcuts));
    await tester.pumpAndSettle();

    for (final label in [
      l10n.settingsDashboard,
      l10n.navRankings,
      l10n.settingsPaymentHistory,
      l10n.settingsSeries,
      l10n.settingsClubInvites,
      l10n.settingsEloHistory,
      l10n.myReportsTitle,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('Bỏ mục Đổi mật khẩu và Đăng ký BTC riêng khỏi cài đặt', (
    tester,
  ) async {
    final l10n = await _pumpSettings(tester);

    await tester.tap(find.text(l10n.accountSettingsShortcuts));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsChangePassword), findsNothing);
    expect(find.text(l10n.organizer_becomeOrganizer), findsNothing);
  });

  testWidgets('Hồ sơ cá nhân mở /profile/edit', (tester) async {
    final l10n = await _pumpSettings(tester);

    await tester.tap(find.text(l10n.accountSettingsPersonalProfile));
    await tester.pumpAndSettle();

    expect(find.text('edit destination'), findsOneWidget);
  });

  testWidgets('Báo cáo của tôi trong Lối tắt mở /profile/reports', (
    tester,
  ) async {
    final l10n = await _pumpSettings(tester);

    await tester.tap(find.text(l10n.accountSettingsShortcuts));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.myReportsTitle));
    await tester.pumpAndSettle();

    expect(find.text('reports destination'), findsOneWidget);
  });
}
