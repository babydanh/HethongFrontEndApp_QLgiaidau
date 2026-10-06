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
  _FakeLocationRepository({this.resolved, this.failure});

  final SocialPlace? resolved;
  final Object? failure;
  final reverseCalls = <LatLng>[];

  @override
  Future<SocialPlace> reverseLookup(LatLng pin) async {
    reverseCalls.add(pin);
    if (failure != null) throw failure!;
    return resolved!;
  }

  @override
  Future<List<SocialPlace>> search(String query, {LatLng? bias}) async =>
      const [];

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

Widget _app(_FakeLocationRepository repository) => ProviderScope(
  overrides: [socialLocationRepositoryProvider.overrideWithValue(repository)],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: Locale('vi'),
    home: Scaffold(body: SocialLocationFlow()),
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
}
