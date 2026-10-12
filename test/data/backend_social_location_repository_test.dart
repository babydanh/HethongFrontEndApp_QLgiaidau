import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/data/repositories/api/backend_social_location_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);

  final ResponseBody Function(RequestOptions options) reply;
  final requested = <Uri>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object value, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(value),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

BackendSocialLocationRepository _repository(_Adapter adapter) =>
    BackendSocialLocationRepository(dio: Dio()..httpClientAdapter = adapter);

void main() {
  group('reverseLookup', () {
    test('dùng /regions/resolve và trả địa chỉ hành chính', () async {
      final adapter = _Adapter(
        (_) => _json({
          'data': {
            'wardCode': '01-001',
            'wardName': 'Phường Mỹ Đình',
            'centerLat': 21.0278,
            'centerLng': 105.8342,
            'provinceCode': '01',
            'provinceName': 'Hà Nội',
            'isEstimated': false,
          },
        }),
      );

      final place = await _repository(
        adapter,
      ).reverseLookup(const LatLng(21.0280, 105.8340));

      expect(place.name, 'Phường Mỹ Đình');
      expect(place.formattedAddress, 'Phường Mỹ Đình, Hà Nội');
      expect(place.wardCode, '01-001');
      expect(place.provinceCode, '01');
      expect(place.regionEstimated, isFalse);
      // Giữ đúng điểm ghim, không dùng tâm phường.
      expect(place.latitude, 21.0280);
      expect(place.longitude, 105.8340);
      expect(adapter.requested.single.path, '/regions/resolve');
      expect(adapter.requested.single.queryParameters['lat'], '21.028');
      expect(adapter.requested.single.queryParameters['lng'], '105.834');
    });

    test('bỏ phần tỉnh trùng với tên phường', () async {
      final adapter = _Adapter(
        (_) => _json({
          'data': {
            'wardCode': '01-001',
            'wardName': 'Hà Nội',
            'provinceCode': '01',
            'provinceName': 'Hà Nội',
            'isEstimated': false,
          },
        }),
      );

      final place = await _repository(
        adapter,
      ).reverseLookup(const LatLng(21.028, 105.834));

      expect(place.formattedAddress, 'Hà Nội');
    });

    test('chấp nhận response không bọc envelope', () async {
      final adapter = _Adapter(
        (_) => _json({
          'wardCode': '79-001',
          'wardName': 'Phường 1',
          'provinceCode': '79',
          'provinceName': 'Thành phố Hồ Chí Minh',
          'isEstimated': false,
        }),
      );

      final place = await _repository(
        adapter,
      ).reverseLookup(const LatLng(10.7769, 106.7009));

      expect(place.formattedAddress, 'Phường 1, Thành phố Hồ Chí Minh');
    });

    test('ném UnresolvableLocation khi điểm nằm ngoài polygon', () async {
      final adapter = _Adapter((_) => _json({'data': null}));

      await expectLater(
        _repository(adapter).reverseLookup(const LatLng(0, 0)),
        throwsA(isA<UnresolvableLocation>()),
      );
    });

    test('phân biệt lỗi mạng với địa chỉ không tra được', () async {
      final adapter = _Adapter(
        (_) => throw DioException(
          requestOptions: RequestOptions(path: '/regions/resolve'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        _repository(adapter).reverseLookup(const LatLng(10.8, 106.7)),
        throwsA(isA<LocationNetworkFailure>()),
      );
    });
  });

  group('resolveInput', () {
    test('luôn ném lỗi vì backend đã bỏ link geocode', () async {
      final adapter = _Adapter((_) => _json({'data': null}));

      await expectLater(
        _repository(adapter).resolveInput('https://maps.app.goo.gl/abc'),
        throwsA(isA<UnresolvableLocation>()),
      );
      expect(adapter.requested, isEmpty);
    });
  });
}
