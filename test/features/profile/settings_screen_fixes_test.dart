import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/club_notification_pref_model.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/user_repository.dart';
import 'package:app_quanly_giaidau/features/profile/screens/settings_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends AuthNotifier {
  static int signOuts = 0;
  static bool failSignOut = false;

  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.viewer);

  @override
  Future<void> signOut({String? reason}) async {
    signOuts++;
    if (failSignOut) throw Exception('signOut boom');
  }
}

class _Regions implements IRegionRepository {
  const _Regions([this.provinces = const []]);
  final List<Region> provinces;

  @override
  Future<List<Region>> getProvinces() async => provinces;
  @override
  Future<List<Region>> getWardsByProvince(String c) async => const [];
  @override
  Future<List<Region>> searchRegions(String q, {int limit = 10}) async =>
      const [];
}

class _Users implements IUserRepository {
  final saved = <Map<String, dynamic>>[];
  final deleted = <String>[];

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    saved.add(data);
    return const UserProfile(id: 'u1');
  }

  @override
  Future<void> deleteAccount(String password) async => deleted.add(password);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Community implements ICommunityRepository {
  _Community(this.clubs);
  final List<ClubNotificationPrefModel> clubs;
  final pending = <String, Completer<void>>{};

  @override
  Future<List<ClubNotificationPrefModel>>
  getMyNotificationPreferences() async => clubs;

  @override
  Future<void> updateNotificationPreference(String id, String pref) {
    final c = Completer<void>();
    pending[id] = c;
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ClubNotificationPrefModel _club(String id) => ClubNotificationPrefModel(
  communityId: id,
  communityName: 'CLB $id',
  role: 'MEMBER',
  notificationPreference: 'ALL',
);

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  UserProfile profile = const UserProfile(
    id: 'u1',
    fullName: 'Alex Player',
    email: 'alex@example.com',
  ),
  required _Users users,
  _Community? community,
  List<Region> provinces = const [],
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(430, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    initialLocation: '/profile/edit',
    routes: [
      GoRoute(path: '/profile/edit', builder: (_, _) => const SettingsScreen()),
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
        userProfileProvider.overrideWith((ref) async => profile),
        userRepositoryProvider.overrideWithValue(users),
        communityRepositoryProvider.overrideWithValue(
          community ?? _Community(const []),
        ),
        regionRepositoryProvider.overrideWithValue(_Regions(provinces)),
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
  return AppLocalizations.of(tester.element(find.byType(SettingsScreen)))!;
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

Future<void> _openDeleteDialog(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await _tapTab(tester, l10n.settingsSecurityTab);
  final btn = find.text(l10n.settingsDeleteAccount);
  await tester.scrollUntilVisible(
    btn,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _Auth.signOuts = 0;
    _Auth.failSignOut = false;
  });

  group('giới tính', () {
    testWidgets(
      'giá trị Backend MALE hiện đúng "Nam", không phải "Chưa chọn"',
      (tester) async {
        final users = _Users();
        final l10n = await _pump(
          tester,
          users: users,
          profile: const UserProfile(
            id: 'u1',
            fullName: 'Alex',
            gender: 'MALE',
          ),
        );
        expect(find.text(l10n.settingsGenderMale), findsOneWidget);
        expect(find.text(l10n.settingsGenderNotSelected), findsNothing);

        await tester.tap(find.text(l10n.settingsSaveButton));
        await tester.pumpAndSettle();
        // Backend chuẩn hoá 'Nam' -> MALE, nên vẫn gửi được giá trị hợp lệ.
        expect(users.saved.single['gender'], 'Nam');
      },
    );

    testWidgets('FEMALE hiện "Nữ"', (tester) async {
      final l10n = await _pump(
        tester,
        users: _Users(),
        profile: const UserProfile(
          id: 'u1',
          fullName: 'Alex',
          gender: 'FEMALE',
        ),
      );
      expect(find.text(l10n.settingsGenderFemale), findsOneWidget);
    });
  });

  group('tỉnh thi đấu', () {
    // TC-PROFILE-PROVINCE-DUP-01
    testWidgets('hai tỉnh trùng tên không làm vỡ ô chọn tỉnh', (tester) async {
      await _pump(
        tester,
        users: _Users(),
        profile: const UserProfile(
          id: 'u1',
          fullName: 'Alex',
          provinceCode: '80',
        ),
        provinces: const [
          Region(code: '79', name: 'Tỉnh Tây Ninh'),
          Region(code: '80', name: 'Tỉnh Tây Ninh'),
        ],
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Tỉnh Tây Ninh'), findsOneWidget);
    });
  });

  group('giữ state tab', () {
    testWidgets('đổi tab không mất dữ liệu đang nhập ở tab Hồ sơ', (
      tester,
    ) async {
      final l10n = await _pump(tester, users: _Users());
      await tester.enterText(
        find.widgetWithText(TextField, l10n.settingsBio),
        'đang gõ dở',
      );
      // Ô đang focus tự giữ state; bỏ focus để chỉ còn mixin của tab giữ.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _tapTab(tester, l10n.settingsSecurityTab);
      await _tapTab(tester, l10n.settingsProfileTab);
      expect(find.text('đang gõ dở'), findsOneWidget);
    });

    testWidgets('đổi tab không mất dữ liệu đang nhập ở tab Ngân hàng', (
      tester,
    ) async {
      final l10n = await _pump(tester, users: _Users());
      await _tapTab(tester, l10n.settingsBankTab);
      await tester.enterText(find.byType(TextField).first, '0123456789');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await _tapTab(tester, l10n.settingsSecurityTab);
      await _tapTab(tester, l10n.settingsBankTab);
      expect(find.text('0123456789'), findsOneWidget);
    });
  });

  group('tên chủ tài khoản ngân hàng', () {
    testWidgets('lưu gửi tên viết hoa không dấu, có Ý', (tester) async {
      final users = _Users();
      final l10n = await _pump(tester, users: users);
      await _tapTab(tester, l10n.settingsBankTab);
      final fields = find.byType(TextField);
      await tester.enterText(fields.last, 'Ngô Ý');
      await tester.tap(find.text(l10n.settingsSaveButton));
      await tester.pumpAndSettle();
      expect(users.saved.last['bankAccountName'], 'NGO Y');
    });
  });

  group('tab Bảo mật', () {
    testWidgets(
      'không còn dòng tĩnh "Mật khẩu mạnh" và "Thiết bị hiện tại - Online"',
      (tester) async {
        final l10n = await _pump(tester, users: _Users());
        await _tapTab(tester, l10n.settingsSecurityTab);
        expect(find.text(l10n.settingsChangePassword), findsOneWidget);
        expect(find.text(l10n.settingsStrongPassword), findsNothing);
        expect(find.text(l10n.settingsOnline), findsNothing);
        expect(find.text(l10n.settingsCurrentDevice), findsNothing);
      },
    );

    testWidgets('xóa tài khoản: signOut lỗi vẫn điều hướng /home', (
      tester,
    ) async {
      _Auth.failSignOut = true;
      final users = _Users();
      final l10n = await _pump(tester, users: users);
      await _openDeleteDialog(tester, l10n);
      await tester.enterText(
        find.widgetWithText(TextField, l10n.settingsConfirmPassword),
        'mat-khau',
      );
      await tester.tap(find.text(l10n.settingsConfirmDelete));
      await tester.pumpAndSettle();

      expect(users.deleted, ['mat-khau']);
      expect(_Auth.signOuts, 1);
      expect(find.text('home-page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'xóa tài khoản thành công: đóng hộp thoại không lỗi controller',
      (tester) async {
        final l10n = await _pump(tester, users: _Users());
        await _openDeleteDialog(tester, l10n);
        await tester.enterText(
          find.widgetWithText(TextField, l10n.settingsConfirmPassword),
          'mat-khau',
        );
        await tester.tap(find.text(l10n.settingsConfirmDelete));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        expect(find.text('home-page'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'thông báo CLB: hai CLB cập nhật song song đều giữ trạng thái bận',
      (tester) async {
        final community = _Community([_club('a'), _club('b')]);
        final l10n = await _pump(tester, users: _Users(), community: community);
        await _tapTab(tester, l10n.settingsSecurityTab);
        final muted = find.text(l10n.settingsNotificationMuted);
        await tester.scrollUntilVisible(
          muted.first,
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(muted.at(0));
        await tester.pump();
        await tester.ensureVisible(muted.at(1));
        await tester.tap(muted.at(1));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

        community.pending['a']!.complete();
        await tester.pump();
        // CLB b vẫn đang cập nhật, không bị CLB a xóa cờ bận.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        community.pending['b']!.complete();
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });
}
