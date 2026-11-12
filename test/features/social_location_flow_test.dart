import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_location_flow.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class _FakeLocationRepository implements ISocialLocationRepository {
  _FakeLocationRepository({this.resolved, this.failure, this.results = const []});

  final SocialPlace? resolved;
  final Object? failure;
  final List<SocialPlace> results;
  final reverseCalls = <LatLng>[];
  final searchCategoryIds = <String?>[];

  @override
  Future<SocialPlace> reverseLookup(LatLng pin) async {
    reverseCalls.add(pin);
    if (failure != null) throw failure!;
    return resolved!;
  }

  @override
  Future<List<SocialPlace>> search(
    String query, {
    LatLng? bias,
    String? categoryId,
  }) async {
    searchCategoryIds.add(categoryId);
    return results;
  }

  @override
  Future<SocialPlace> getVenueDetail(String venueId) =>
      throw UnimplementedError();

  @override
  Future<SocialPlace> getPlaceDetail(String placeId) =>
      throw UnimplementedError();

  @override
  Future<SocialPlace> resolveInput(String addressOrMapsUrl) =>
      throw UnimplementedError();
}

Widget _app(_FakeLocationRepository repository, {String? categoryId}) => ProviderScope(
  overrides: [socialLocationRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: Scaffold(body: SocialLocationFlow(categoryId: categoryId)),
  ),
);

/// Đi qua bước search → nhập [input] → ghim trên bản đồ → xác nhận ghim.
Future<void> _pinAfterTyping(
  WidgetTester tester,
  _FakeLocationRepository repository,
  String input,
) async {
  await tester.pumpWidget(_app(repository));
  await tester.tap(find.text('Thêm địa điểm mới'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, input);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Chọn từ bản đồ'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Xác nhận vị trí'));
  await tester.pumpAndSettle();
}

SocialPlace _resolved() => const SocialPlace(
  name: 'Phường Mỹ Đình',
  formattedAddress: 'Phường Mỹ Đình, Hà Nội',
  latitude: 21.0278,
  longitude: 105.8342,
  provinceCode: '01',
  wardCode: '01-001',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // SocialLocationPicker đọc OSM_TILE_URL qua dotenv khi dựng bản đồ.
  setUpAll(() {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');
  });

  testWidgets('tên sân thuần thì lấy địa chỉ hành chính từ ghim', (
    tester,
  ) async {
    final repository = _FakeLocationRepository(resolved: _resolved());
    await _pinAfterTyping(tester, repository, 'Sân nhà anh Tuấn');

    // Bước preview: tên sân và địa chỉ phải là hai giá trị khác nhau.
    expect(find.text('Xác nhận địa điểm'), findsOneWidget);
    expect(find.text('Sân nhà anh Tuấn'), findsOneWidget);
    expect(find.text('Phường Mỹ Đình, Hà Nội'), findsOneWidget);
  });

  testWidgets('giữ nguyên street-level khi người dùng gõ địa chỉ', (
    tester,
  ) async {
    final repository = _FakeLocationRepository(resolved: _resolved());
    await _pinAfterTyping(tester, repository, '30 Tân Thắng, P.15, Q.Tân Bình');

    expect(find.text('30 Tân Thắng, P.15, Q.Tân Bình'), findsWidgets);
    expect(find.text('Phường Mỹ Đình, Hà Nội'), findsNothing);
  });

  testWidgets('báo lỗi và không vào preview khi không tra được địa chỉ', (
    tester,
  ) async {
    final repository = _FakeLocationRepository(
      failure: const UnresolvableLocation(),
    );
    await _pinAfterTyping(tester, repository, 'Sân nhà anh Tuấn');

    expect(find.text('Xác nhận địa điểm'), findsNothing);
    expect(find.textContaining('Hãy chọn ghim khác'), findsOneWidget);
  });

  testWidgets('giữ đúng tọa độ ghim, không dùng tâm phường', (tester) async {
    final repository = _FakeLocationRepository(resolved: _resolved());
    await _pinAfterTyping(tester, repository, 'Sân nhà anh Tuấn');

    // Tâm bản đồ mặc định khi chưa có vị trí nào; đây là ghim người dùng chọn,
    // không phải centerLat/centerLng (21.0278/105.8342) của phường.
    expect(repository.reverseCalls.single, const LatLng(10.7769, 106.7009));
  });

  testWidgets('xác nhận ở preview trả về địa chỉ đã tra', (tester) async {
    final repository = _FakeLocationRepository(resolved: _resolved());
    SocialPlace? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialLocationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await SocialLocationFlow.show(
                    context,
                    initialCenter: const LatLng(10.7769, 106.7009),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm địa điểm mới'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Sân nhà anh Tuấn');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn từ bản đồ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận vị trí'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Sân nhà anh Tuấn');
    expect(result!.formattedAddress, 'Phường Mỹ Đình, Hà Nội');
    expect(result!.latitude, 10.7769);
    expect(result!.longitude, 106.7009);
  });

  group('tìm sân theo môn', () {
    const venue = SocialPlace(
      name: 'Sân Pickleball A',
      formattedAddress: '1 Đường X',
      latitude: 10.0,
      longitude: 106.0,
      venueId: 'v1',
      isVerified: true,
    );
    const unverified = SocialPlace(
      name: 'Sân Pickleball B',
      formattedAddress: '2 Đường Y',
      latitude: 10.0,
      longitude: 106.0,
      venueId: 'v2',
    );

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField).first, text);
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
    }

    testWidgets('TC-VENUE-07 gửi categoryId của môn xuống repository', (
      tester,
    ) async {
      final repository = _FakeLocationRepository(results: [venue]);
      await tester.pumpWidget(_app(repository, categoryId: 'cat-pickle'));
      await type(tester, 'sân pic');

      expect(repository.searchCategoryIds, ['cat-pickle']);
    });

    testWidgets('TC-VENUE-08 hiện nhãn Đã xác minh chỉ ở sân đã xác minh', (
      tester,
    ) async {
      final repository = _FakeLocationRepository(results: [venue, unverified]);
      await tester.pumpWidget(_app(repository, categoryId: 'cat-pickle'));
      await type(tester, 'sân pic');

      expect(find.text('Sân Pickleball A'), findsOneWidget);
      expect(find.text('Sân Pickleball B'), findsOneWidget);
      expect(find.text('Đã xác minh'), findsOneWidget);
    });

    testWidgets('TC-VENUE-09 đổi môn thì tìm lại với môn mới', (tester) async {
      final repository = _FakeLocationRepository(results: [venue]);
      await tester.pumpWidget(_app(repository, categoryId: 'cat-pickle'));
      await type(tester, 'sân pic');
      await tester.pumpWidget(_app(repository, categoryId: 'cat-football'));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();

      expect(repository.searchCategoryIds, ['cat-pickle', 'cat-football']);
    });

    testWidgets('TC-VENUE-10 vẫn hiện nguồn © OpenStreetMap', (tester) async {
      final repository = _FakeLocationRepository(results: [venue]);
      await tester.pumpWidget(_app(repository, categoryId: 'cat-pickle'));
      await tester.tap(find.text('Thêm địa điểm mới'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Sân A');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chọn từ bản đồ'));
      await tester.pumpAndSettle();

      expect(find.textContaining('OpenStreetMap'), findsWidgets);
    });
  });
}
