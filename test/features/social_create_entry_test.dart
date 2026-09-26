import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/home/screens/home_screen.dart';
import 'package:app_quanly_giaidau/features/social/screens/create_social_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
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
}

Widget _homeApp(Locale locale) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(_AuthenticatedPreviewAuthNotifier.new),
      tournamentsProvider.overrideWith(
        (ref) => Stream.value(const <Tournament>[]),
      ),
      categoriesProvider.overrideWith((ref) => Future.value(_activeSports())),
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
      home: const HomeScreen(initialTab: 3),
    ),
  );
}

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
