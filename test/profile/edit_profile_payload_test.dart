import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/club_notification_pref_model.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/user_repository.dart';
import 'package:app_quanly_giaidau/features/profile/screens/settings_screen.dart';
import 'package:app_quanly_giaidau/features/profile/utils/edit_profile_payload.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, role: UserRole.viewer);
}

class _FakeRegions implements IRegionRepository {
  @override
  Future<List<Region>> getProvinces() async => const [];
  @override
  Future<List<Region>> getWardsByProvince(String c) async => const [];
  @override
  Future<List<Region>> searchRegions(String q, {int limit = 10}) async =>
      const [];
}

class _FakeUsers implements IUserRepository {
  final saved = <Map<String, dynamic>>[];

  @override
  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    saved.add(data);
    return const UserProfile(id: 'u1');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCommunity implements ICommunityRepository {
  int calls = 0;
  bool fail = true;

  @override
  Future<List<ClubNotificationPrefModel>> getMyNotificationPreferences() async {
    calls++;
    if (fail) throw Exception('boom');
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<AppLocalizations> _pumpScreen(
  WidgetTester tester, {
  required _FakeUsers users,
  required _FakeCommunity community,
  ThemeData? theme,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(_AuthNotifier.new),
        userProfileProvider.overrideWith(
          (ref) async => const UserProfile(
            id: 'u1',
            fullName: 'Alex Player',
            email: 'alex@example.com',
            bio: 'cũ',
          ),
        ),
        userRepositoryProvider.overrideWithValue(users),
        communityRepositoryProvider.overrideWithValue(community),
        regionRepositoryProvider.overrideWithValue(_FakeRegions()),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
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

Map<String, dynamic> _build({
  String name = ' Alex ',
  String phone = '',
  DateTime? dob,
  String? gender,
  bool genderLocked = false,
  String address = '',
  String provinceCode = '',
  String bio = '',
}) => buildEditProfilePayload(
  fullName: name,
  phone: phone,
  dateOfBirth: dob,
  gender: gender,
  genderLocked: genderLocked,
  address: address,
  provinceCode: provinceCode,
  bio: bio,
);

void main() {
  group('isValidVnPhone', () {
    test('chấp nhận +84 và 0[35789] kèm 8 số', () {
      // Backend: '+84' rồi đúng 8 số (không phải 9) nên đây là mẫu hợp lệ.
      expect(isValidVnPhone('+8491234567'), isTrue);
      expect(isValidVnPhone('0912345678'), isTrue);
      expect(isValidVnPhone('0356789012'), isTrue);
    });

    test('từ chối đầu số sai, độ dài sai và số bàn', () {
      expect(isValidVnPhone('+84912345678'), isFalse); // Backend cũng từ chối
      expect(isValidVnPhone('01234567890'), isFalse);
      expect(isValidVnPhone('02812345678'), isFalse);
      expect(isValidVnPhone('0212345678'), isFalse);
      expect(isValidVnPhone('091234567'), isFalse);
      expect(isValidVnPhone('abc'), isFalse);
      expect(isValidVnPhone(''), isFalse);
    });
  });

  group('buildEditProfilePayload', () {
    test('không gửi phoneNumber khi trống', () {
      final p = _build(phone: '   ');
      expect(p.containsKey('phoneNumber'), isFalse);
      expect(p['fullName'], 'Alex');
    });

    test('gửi phoneNumber đã cắt khoảng trắng khi có', () {
      expect(_build(phone: ' 0912345678 ')['phoneNumber'], '0912345678');
    });

    test('bio và address rỗng vẫn được gửi để xóa', () {
      final p = _build();
      expect(p['bio'], '');
      expect(p['address'], '');
    });

    test('gender bị khóa hoặc chưa chọn thì không gửi', () {
      expect(
        _build(gender: 'Nam', genderLocked: true).containsKey('gender'),
        isFalse,
      );
      expect(_build().containsKey('gender'), isFalse);
      expect(_build(gender: 'Nữ')['gender'], 'Nữ');
    });

    test('ngày sinh định dạng YYYY-MM-DD, tỉnh chỉ gửi khi có', () {
      final p = _build(dob: DateTime(2000, 3, 7), provinceCode: '79');
      expect(p['dateOfBirth'], '2000-03-07');
      expect(p['provinceCode'], '79');
      expect(_build().containsKey('provinceCode'), isFalse);
      expect(_build().containsKey('dateOfBirth'), isFalse);
    });
  });

  group('màn Sửa hồ sơ', () {
    for (final dark in [false, true]) {
      testWidgets('lưu gửi đúng payload (${dark ? 'tối' : 'sáng'})', (
        tester,
      ) async {
        final users = _FakeUsers();
        final l10n = await _pumpScreen(
          tester,
          users: users,
          community: _FakeCommunity(),
          theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
        );
        expect(find.text(l10n.settingsEditProfile), findsOneWidget);
        expect(
          find.byKey(const ValueKey('settings-language-card')),
          findsNothing,
        );

        await tester.enterText(
          find.widgetWithText(TextField, l10n.settingsBio),
          '',
        );
        await tester.tap(find.text(l10n.settingsSaveButton));
        await tester.pumpAndSettle();

        expect(users.saved, hasLength(1));
        expect(users.saved.single['fullName'], 'Alex Player');
        expect(users.saved.single.containsKey('phoneNumber'), isFalse);
        expect(users.saved.single['bio'], '');
        expect(users.saved.single['address'], '');
      });
    }

    testWidgets('lỗi tải CLB hiện lỗi và thử lại, không báo không có CLB', (
      tester,
    ) async {
      final community = _FakeCommunity();
      final l10n = await _pumpScreen(
        tester,
        users: _FakeUsers(),
        community: community,
      );
      await tester.tap(find.widgetWithText(Tab, l10n.settingsSecurityTab));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(l10n.lavishRetry),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(l10n.settingsNoClubsForNotifications), findsNothing);

      community.fail = false;
      await tester.tap(find.text(l10n.lavishRetry));
      await tester.pumpAndSettle();
      expect(community.calls, 2);
      expect(find.text(l10n.settingsNoClubsForNotifications), findsOneWidget);
    });
  });
}
