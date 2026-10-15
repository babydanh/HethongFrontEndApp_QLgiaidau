import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/features/profile/screens/settings_screen.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/organizer_verification_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(this.initialState);

  final AuthState initialState;

  @override
  AuthState build() => initialState;
}

class _FakeRegionRepository implements IRegionRepository {
  @override
  Future<List<Region>> getProvinces() async => const [];

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async => const [];

  @override
  Future<List<Region>> searchRegions(String query, {int limit = 10}) async =>
      const [];
}

const _unverifiedProfile = UserProfile(
  id: 'user-1',
  fullName: 'Alex Player',
  email: 'alex@example.com',
  isEmailVerified: false,
  isPhoneVerified: false,
);

Future<AppLocalizations> _pumpSettings(
  WidgetTester tester, {
  UserProfile profile = _unverifiedProfile,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(430, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
        userProfileProvider.overrideWith((ref) async => profile),
        regionRepositoryProvider.overrideWithValue(_FakeRegionRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return AppLocalizations.of(tester.element(find.byType(SettingsScreen)))!;
}

/// Cuộn thanh tab (có thể cuộn ngang) để tab nằm trong viewport rồi bấm.
Future<void> _tapTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Màn hồ sơ có 4 tab theo thứ tự Hồ sơ, Ngân hàng, Tổ chức, Bảo mật', (
    tester,
  ) async {
    final l10n = await _pumpSettings(tester);

    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    final labels = tabBar.tabs.map((tab) => (tab as Tab).text).toList();

    expect(labels, [
      l10n.settingsProfileTab,
      l10n.settingsBankTab,
      l10n.accountSettingsOrganizerTab,
      l10n.settingsSecurityTab,
    ]);
  });

  testWidgets('Xác minh email/SĐT nằm ở tab Hồ sơ, không còn ở tab Bảo mật', (
    tester,
  ) async {
    final l10n = await _pumpSettings(tester);

    expect(find.text(l10n.settingsVerificationStatus), findsOneWidget);
    expect(find.text(l10n.settingsVerifyEmail), findsOneWidget);
    expect(find.text(l10n.settingsVerifyPhone), findsOneWidget);

    await _tapTab(tester, l10n.settingsSecurityTab);

    expect(find.text(l10n.settingsChangePassword), findsOneWidget);
    expect(find.text(l10n.settingsVerificationStatus), findsNothing);
    expect(find.text(l10n.settingsVerifyEmail), findsNothing);
  });

  testWidgets('Tab Bảo mật không còn mục Báo cáo của tôi', (tester) async {
    final l10n = await _pumpSettings(tester);

    await _tapTab(tester, l10n.settingsSecurityTab);

    expect(find.text(l10n.settingsChangePassword), findsOneWidget);
    expect(find.text(l10n.settingsMyReports), findsNothing);
    expect(find.text(l10n.settingsCommunitySafety), findsNothing);
  });

  testWidgets('Tab Tổ chức hiện trạng thái chưa đăng ký và mở luồng đăng ký BTC', (
    tester,
  ) async {
    final l10n = await _pumpSettings(tester);

    await _tapTab(tester, l10n.accountSettingsOrganizerTab);

    expect(find.text(l10n.accountSettingsOrganizerRoleTitle), findsOneWidget);
    expect(
      find.text(l10n.accountSettingsOrganizerNotRegistered),
      findsOneWidget,
    );
    expect(
      find.text(l10n.accountSettingsOrganizerDescription),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.accountSettingsOrganizerOpenApplication));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(OrganizerVerificationSheet), findsOneWidget);
  });

  testWidgets('Đã là ORGANIZER thì tab Tổ chức hiện trạng thái đã xác minh', (
    tester,
  ) async {
    final l10n = await _pumpSettings(
      tester,
      profile: const UserProfile(
        id: 'user-1',
        fullName: 'Alex Player',
        role: 'ORGANIZER',
      ),
    );

    await _tapTab(tester, l10n.accountSettingsOrganizerTab);

    expect(find.text(l10n.accountSettingsOrganizerVerified), findsOneWidget);
    expect(
      find.text(l10n.accountSettingsOrganizerOpenApplication),
      findsNothing,
    );
  });
}
