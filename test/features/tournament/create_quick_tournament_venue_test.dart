import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'create_quick_tournament_harness.dart';

class _FakeLocations implements ISocialLocationRepository {
  _FakeLocations(this.results, {this.fail = false});

  final List<SocialPlace> results;
  final bool fail;
  final List<String> queries = [];

  @override
  Future<List<SocialPlace>> search(
    String query, {
    LatLng? bias,
    String? categoryId,
    bool requirePin = true,
  }) async {
    queries.add(query);
    if (fail) throw const LocationNetworkFailure();
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
  @override
  Future<SocialPlace> reverseLookup(LatLng pin) => throw UnimplementedError();
}

const _kyHoa = SocialPlace(
  name: 'Sân Kỳ Hòa',
  formattedAddress: '238 Kỳ Đồng, Quận 3',
  venueId: 'v-kyhoa',
  provinceCode: '79',
  wardCode: '9001',
);

final _venueName = find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == 'VD: Sân Cầu Lông Kỳ Hòa',
);
final _address = find.byWidgetPredicate(
  (w) =>
      w is TextField &&
      w.decoration?.hintText == 'VD: 238 Kỳ Đồng, Quận 3, TP.HCM',
);

Future<void> _type(WidgetTester tester, Finder field, String text) async {
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _pickFromList(WidgetTester tester) async {
  await _type(tester, _venueName, 'Kỳ Hòa');
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.text('Sân Kỳ Hòa'));
  await settle(tester);
}

Future<void> _submit(WidgetTester tester) async {
  await enterName(tester, 'Giải địa điểm');
  await tapSubmit(tester);
}

void main() {
  setUpAll(setUpEnv);

  group('CreatePublicQuickTournamentScreen địa điểm: nhập tay', () {
    testWidgets('hiện ô tên địa điểm và ô địa chỉ, cả hai đều tuỳ chọn', (
      tester,
    ) async {
      await pumpCreateScreen(tester);
      expect(find.text('Địa điểm thi đấu (Tùy chọn)'), findsOneWidget);
      expect(_venueName, findsOneWidget);
      expect(_address, findsOneWidget);
    });

    testWidgets(
      'bỏ trống địa điểm vẫn gửi được và body không có khoá địa điểm',
      (tester) async {
        final h = await pumpCreateScreen(tester);
        await _submit(tester);
        expect(h.submitCount, 1);
        for (final key in ['venueName', 'locationAddress', 'venueId']) {
          expect(h.lastBody.containsKey(key), isFalse, reason: key);
        }
      },
    );

    testWidgets('chỉ nhập tên địa điểm thì gửi venueName, không gửi địa chỉ', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _type(tester, _venueName, '  Sân Cầu Lông Kỳ Hòa  ');
      await _submit(tester);
      expect(h.lastBody['venueName'], 'Sân Cầu Lông Kỳ Hòa');
      expect(h.lastBody.containsKey('locationAddress'), isFalse);
    });

    testWidgets('chỉ nhập địa chỉ thì gửi locationAddress, không gửi tên', (
      tester,
    ) async {
      final h = await pumpCreateScreen(tester);
      await _type(tester, _address, '12 Lê Lợi');
      await _submit(tester);
      expect(h.lastBody['locationAddress'], '12 Lê Lợi');
      expect(h.lastBody.containsKey('venueName'), isFalse);
    });

    testWidgets('địa điểm nhập tay không có venueId', (tester) async {
      final h = await pumpCreateScreen(tester);
      await _type(tester, _venueName, 'Sân nhà');
      await _type(tester, _address, '12 Lê Lợi');
      await _submit(tester);
      expect(h.lastBody.containsKey('venueId'), isFalse);
    });
  });

  group('CreatePublicQuickTournamentScreen địa điểm: gợi ý sân', () {
    testWidgets('gõ dưới 3 ký tự thì không tìm sân', (tester) async {
      final repo = _FakeLocations(const [_kyHoa]);
      await pumpCreateScreen(tester, locationRepository: repo);
      await _type(tester, _venueName, 'Kỳ');
      await tester.pump(const Duration(milliseconds: 500));
      expect(repo.queries, isEmpty);
    });

    testWidgets('gõ từ 3 ký tự thì hiện danh sách sân gợi ý', (tester) async {
      final repo = _FakeLocations(const [_kyHoa]);
      await pumpCreateScreen(tester, locationRepository: repo);
      await _type(tester, _venueName, 'Kỳ Hòa');
      await tester.pump(const Duration(milliseconds: 500));
      expect(repo.queries, ['Kỳ Hòa']);
      expect(find.text('Sân Kỳ Hòa'), findsOneWidget);
    });

    testWidgets('chọn sân gợi ý điền cả tên và địa chỉ', (tester) async {
      final repo = _FakeLocations(const [_kyHoa]);
      await pumpCreateScreen(tester, locationRepository: repo);
      await _pickFromList(tester);
      expect(
        tester.widget<TextField>(_venueName).controller!.text,
        'Sân Kỳ Hòa',
      );
      expect(
        tester.widget<TextField>(_address).controller!.text,
        '238 Kỳ Đồng, Quận 3',
      );
    });

    testWidgets('gửi giải với sân đã chọn kèm venueId, tên và địa chỉ', (
      tester,
    ) async {
      final repo = _FakeLocations(const [_kyHoa]);
      final h = await pumpCreateScreen(tester, locationRepository: repo);
      await _pickFromList(tester);
      await _submit(tester);
      expect(h.lastBody['venueId'], 'v-kyhoa');
      expect(h.lastBody['venueName'], 'Sân Kỳ Hòa');
      expect(h.lastBody['locationAddress'], '238 Kỳ Đồng, Quận 3');
    });

    testWidgets('sân đã chọn mang theo tỉnh và phường của danh bạ', (
      tester,
    ) async {
      final repo = _FakeLocations(const [_kyHoa]);
      final h = await pumpCreateScreen(tester, locationRepository: repo);
      await _pickFromList(tester);
      await _submit(tester);
      expect(h.lastBody['provinceCode'], '79');
      expect(h.lastBody['province'], 'TP. Hồ Chí Minh');
      expect(h.lastBody['wardCode'], '9001');
      expect(h.lastBody['ward'], 'Phường Bến Nghé');
    });

    testWidgets('sửa tên sau khi chọn sân thì bỏ venueId', (tester) async {
      final repo = _FakeLocations(const [_kyHoa]);
      final h = await pumpCreateScreen(tester, locationRepository: repo);
      await _pickFromList(tester);
      await _type(tester, _venueName, 'Sân Kỳ Hòa 2');
      await _submit(tester);
      expect(h.lastBody.containsKey('venueId'), isFalse);
      expect(h.lastBody['venueName'], 'Sân Kỳ Hòa 2');
    });

    testWidgets('sửa địa chỉ sau khi chọn sân thì bỏ venueId', (tester) async {
      final repo = _FakeLocations(const [_kyHoa]);
      final h = await pumpCreateScreen(tester, locationRepository: repo);
      await _pickFromList(tester);
      await _type(tester, _address, '999 Đường khác');
      await _submit(tester);
      expect(h.lastBody.containsKey('venueId'), isFalse);
    });

    testWidgets('tìm sân lỗi mạng thì không có gợi ý và vẫn nhập tay được', (
      tester,
    ) async {
      final repo = _FakeLocations(const [], fail: true);
      final h = await pumpCreateScreen(tester, locationRepository: repo);
      await _type(tester, _venueName, 'Sân nhà');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.stadium_outlined), findsNothing);
      await _submit(tester);
      expect(h.lastBody['venueName'], 'Sân nhà');
    });
  });
}
