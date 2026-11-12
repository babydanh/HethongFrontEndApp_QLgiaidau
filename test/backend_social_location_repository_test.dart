import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/data/repositories/api/backend_social_location_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter({this.body, this.timeout = false});

  final Object? body;
  final bool timeout;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (timeout) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, Object?> _venue(
  String id,
  double lat,
  double lng, {
  bool? verified,
}) => {
  'venueId': id,
  'name': 'Sân $id',
  'formattedAddress': 'Địa chỉ $id',
  'latitude': lat,
  'longitude': lng,
  'provinceCode': null,
  'wardCode': null,
  if (verified != null) 'isVerified': verified,
  'score': 0.9,
};

BackendSocialLocationRepository _repo(_Adapter adapter) =>
    BackendSocialLocationRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter,
    );

void main() {
  const bias = LatLng(10.0, 106.0);
  // 0.001 độ vĩ ≈ 111 m.
  const near = 0.001;
  const far = 0.003;

  test('TC-VENUE-01 gửi categoryId khi có môn', () async {
    final adapter = _Adapter(body: {'data': <Object>[]});
    await _repo(adapter).search('sân abc', categoryId: 'cat-1');
    expect(adapter.requests.single.queryParameters, {
      'q': 'sân abc',
      'limit': 10,
      'categoryId': 'cat-1',
    });
  });

  test('TC-VENUE-02 không gửi categoryId khi null, mảng rỗng', () async {
    final adapter = _Adapter(body: {'data': <Object>[]});
    final result = await _repo(adapter).search('sân abc');
    expect(
      adapter.requests.single.queryParameters.containsKey('categoryId'),
      isFalse,
    );
    expect(result, isEmpty);
  });

  test('TC-VENUE-03 đọc isVerified, thiếu trường thì false', () async {
    final adapter = _Adapter(
      body: {
        'data': [_venue('a', 10, 106, verified: true), _venue('b', 10, 106)],
      },
    );
    final result = await _repo(adapter).search('sân', categoryId: 'c');
    expect(result.map((p) => p.isVerified), [true, false]);
  });

  test('TC-VENUE-04 có bias: xác minh đứng trước khi chênh dưới 200 m',
      () async {
    final adapter = _Adapter(
      body: {
        'data': [
          _venue('gan-chua', 10 + near, 106, verified: false),
          _venue('xa-hon-xm', 10 + near + 0.0009, 106, verified: true),
        ],
      },
    );
    final result = await _repo(adapter).search('sân', bias: bias);
    expect(result.map((p) => p.venueId), ['xa-hon-xm', 'gan-chua']);
  });

  test('TC-VENUE-05 có bias: chênh từ 200 m thì gần hơn đứng trước', () async {
    final adapter = _Adapter(
      body: {
        'data': [
          _venue('xa-xm', 10 + far, 106, verified: true),
          _venue('gan-chua', 10 + near, 106, verified: false),
        ],
      },
    );
    final result = await _repo(adapter).search('sân', bias: bias);
    expect(result.map((p) => p.venueId), ['gan-chua', 'xa-xm']);
  });

  test('TC-VENUE-06 timeout giữ LocationNetworkFailure', () async {
    expect(
      _repo(_Adapter(timeout: true)).search('sân abc', categoryId: 'c'),
      throwsA(isA<LocationNetworkFailure>()),
    );
  });
}
