import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/home/screens/home_screen.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Social create action opens the existing create form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(_homeApp(const Locale('vi')));

    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Social'));
    await tester.pump();

    final createAction = find.byKey(
      const ValueKey('home-social-create-action'),
    );
    expect(createAction, findsOneWidget);
    expect(find.text('Tạo kèo'), findsOneWidget);
    await tester.tap(createAction);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('TẠO KÈO'), findsOneWidget);
    expect(find.text('TÊN KÈO'), findsOneWidget);
    expect(find.text('Phí tham gia kèo'), findsOneWidget);
    expect(find.text('KÈO'), findsOneWidget);
    expect(find.byType(CreateSocialScreen), findsOneWidget);
    for (final sport in [
      'pickleball',
      'badminton',
      'tennis',
      'table_tennis',
      'football',
    ]) {
      expect(find.byKey(ValueKey('social-sport-$sport')), findsOneWidget);
    }
    for (final format in [
      'Giao lưu',
      'Đánh vòng tròn',
      'Đánh đơn',
      'Đánh đôi',
    ]) {
      expect(find.text(format), findsOneWidget);
    }
    final provinceField = find.byKey(
      const ValueKey('social-region-province-input'),
    );
    final wardField = find.byKey(const ValueKey('social-region-ward-input'));
    await tester.ensureVisible(provinceField);
    await tester.pumpAndSettle();
    expect(provinceField, findsOneWidget);
    expect(wardField, findsOneWidget);
    expect(
      find.text('Chọn tỉnh/thành và phường/xã (không bắt buộc)'),
      findsOneWidget,
    );
    expect(find.textContaining('Thành viên CLB có gắn thẻ'), findsNothing);

    final closeButton = find.descendant(
      of: find.byType(CreateSocialScreen),
      matching: find.byIcon(Icons.arrow_back),
    );
    await tester.ensureVisible(closeButton);
    await tester.pumpAndSettle();
    await tester.tap(closeButton);
    await tester.pumpAndSettle();
    expect(find.text('TẠO KÈO'), findsNothing);
    expect(createAction, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_homeApp(const Locale('en')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Social'));
    await tester.pump();
    expect(find.text('Create session'), findsOneWidget);
    final englishCreateAction = find.byKey(
      const ValueKey('home-social-create-action'),
    );
    await tester.tap(englishCreateAction);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    for (final format in ['Casual play', 'Round robin', 'Singles', 'Doubles']) {
      expect(find.text(format), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'club-linked session reads as a gathering, not an automatic invitation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      const clubForm = CreateSocialScreen(
        clubId: 'club-1',
        clubName: 'Câu lạc bộ Hồ Tây',
      );

      await tester.pumpWidget(_homeApp(const Locale('vi'), home: clubForm));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Vietnamese club layout');
      expect(find.text('TÊN BUỔI GIAO LƯU'), findsOneWidget);
      expect(find.text('Phí tham gia buổi giao lưu'), findsOneWidget);
      expect(find.text('TẠO BUỔI GIAO LƯU'), findsOneWidget);
      expect(find.text('BUỔI GIAO LƯU'), findsOneWidget);
      expect(find.text('KÈO'), findsNothing);
      expect(find.text('Tạo buổi giao lưu'), findsOneWidget);
      expect(
        find.text(
          'Buổi giao lưu được liên kết với CLB đã chọn. '
          'Thành viên không tự động được mời hoặc thêm vào danh sách tham gia.',
        ),
        findsOneWidget,
      );
      expect(find.text('Thay đổi'), findsNothing);
      expect(find.text('Xóa CLB'), findsOneWidget);
      await tester.ensureVisible(find.text('Công khai'));
      await tester.tap(find.text('Công khai'));
      await tester.pumpAndSettle();
      expect(find.text('Nội bộ CLB'), findsOneWidget);
      await tester.tap(find.text('Nội bộ CLB').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('social-sport-badminton')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('social-sport-pickleball')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('social-sport-football')), findsNothing);
      expect(
        tester
            .widget<InkWell>(
              find.byKey(const ValueKey('social-sport-badminton')),
            )
            .onTap,
        isNull,
      );
      expect(
        find.textContaining('Người tổ chức duyệt yêu cầu'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('social-max-slots-input')),
        findsOneWidget,
      );

      await tester.pumpWidget(_homeApp(const Locale('en'), home: clubForm));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'English club layout');
      expect(find.text('GATHERING TITLE'), findsOneWidget);
      expect(find.text('Gathering fee'), findsOneWidget);
      expect(find.text('CREATE CLUB GATHERING'), findsOneWidget);
      expect(find.text('CLUB GATHERING'), findsOneWidget);
      expect(find.text('Create club session'), findsOneWidget);
      expect(
        find.text(
          'This gathering is linked to the selected club. '
          'Members are not automatically invited or added as participants.',
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Xóa CLB'));
      await tester.tap(find.text('Xóa CLB'));
      await tester.pumpAndSettle();
      expect(find.text('SESSION TITLE'), findsOneWidget);
      expect(find.text('Participation fee'), findsOneWidget);
      expect(find.text('CREATE SESSION'), findsOneWidget);
      expect(find.text('SESSION'), findsOneWidget);
      expect(find.text('Create session'), findsOneWidget);
      expect(find.text('Linked to club'), findsNothing);
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets('invalid participant capacity prevents form submission', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _homeApp(
        const Locale('en'),
        home: const CreateSocialScreen(clubId: '', clubName: ''),
      ),
    );
    await tester.pumpAndSettle();

    final capacityField = find.byKey(const ValueKey('social-max-slots-input'));
    await tester.ensureVisible(capacityField);
    await tester.enterText(capacityField, '65');
    await tester.pumpAndSettle();
    expect(find.text('Enter a whole number from 2 to 64.'), findsOneWidget);

    final submitButton = find.text('CREATE SESSION');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Enter a whole number from 2 to 64.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('standalone privacy options do not include club-only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _homeApp(
        const Locale('vi'),
        home: const CreateSocialScreen(clubId: '', clubName: ''),
      ),
    );
    await tester.pumpAndSettle();
    final privacyLabel = find.text('Quyền riêng tư');
    await tester.ensureVisible(privacyLabel);
    await tester.tap(privacyLabel);
    await tester.pumpAndSettle();
    expect(find.text('Nội bộ CLB'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('club-only mode fails closed without active club sports', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      _homeApp(
        const Locale('vi'),
        home: const CreateSocialScreen(
          clubId: 'club-1',
          clubName: 'Câu lạc bộ Hồ Tây',
        ),
        communityOverride: Community(
          id: 'club-1',
          name: 'Câu lạc bộ Hồ Tây',
          sportCategoryIds: const {'badminton': 'inactive-category-id'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Câu lạc bộ chưa có môn thể thao đang hoạt động phù hợp cho buổi giao lưu nội bộ.',
      ),
      findsOneWidget,
    );
    final privacyLabel = find.text('Quyền riêng tư');
    await tester.ensureVisible(privacyLabel);
    await tester.tap(privacyLabel);
    await tester.pumpAndSettle();
    expect(find.text('Nội bộ CLB'), findsNothing);
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _homeApp(Locale locale, {Widget? home, Community? communityOverride}) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_AuthenticatedPreviewAuthNotifier.new),
      tournamentsProvider.overrideWith(
        (ref) => Stream.value(const <Tournament>[]),
      ),
      categoriesProvider.overrideWith((ref) => Future.value(_activeSports())),
      communityDetailProvider.overrideWith(
        (ref, id) async => communityOverride ?? _fixtureCommunity(id),
      ),
      liveMatchesProvider.overrideWith(
        (ref) => Future.value(const <MatchModel>[]),
      ),
      unreadCountProvider.overrideWith((ref) => Future.value(0)),
      regionRepositoryProvider.overrideWith((ref) => _FakeRegionRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home == null
          ? const HomeScreen(initialTab: 3)
          : Scaffold(body: home),
    ),
  );
}

Community _fixtureCommunity(String id) => Community(
  id: id,
  name: 'Câu lạc bộ Hồ Tây',
  sportCategoryIds: const {'badminton': '2'},
);

List<CategoryModel> _activeSports() => [
  CategoryModel(
    id: '1',
    name: 'Pickleball',
    slug: 'pickleball',
    description: '',
    isActive: true,
  ),
  CategoryModel(
    id: '2',
    name: 'Cầu lông',
    slug: 'badminton',
    description: '',
    isActive: true,
  ),
  CategoryModel(
    id: '3',
    name: 'Tennis',
    slug: 'tennis',
    description: '',
    isActive: true,
  ),
  CategoryModel(
    id: '4',
    name: 'Bóng bàn',
    slug: 'table_tennis',
    description: '',
    isActive: true,
  ),
  CategoryModel(
    id: '5',
    name: 'Bóng đá',
    slug: 'football',
    description: '',
    isActive: true,
  ),
];

class _FakeRegionRepository implements IRegionRepository {
  @override
  Future<List<Region>> getProvinces() async => const [
    Region(code: '79', name: 'Thành phố Hồ Chí Minh'),
  ];

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async => const [
    Region(code: '760', name: 'Phường 1'),
  ];
}

class _AuthenticatedPreviewAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    role: UserRole.viewer,
    tokenCode: 'fixture',
  );

  @override
  Future<void> init() async {}
}
