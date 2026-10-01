import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/data/repositories/api/backend_social_location_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);
  final ResponseBody Function(RequestOptions) reply;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

const _place = {
  'name': 'MK Building',
  'formattedAddress': '1 Lữ Gia, Hồ Chí Minh, Việt Nam',
  'latitude': 10.762,
  'longitude': 106.657,
};

void main() {
  test('search uses authenticated backend route and reads envelope', () async {
    final adapter = _Adapter(
      (_) => _json({
        'statusCode': 200,
        'data': [_place],
      }),
    );
    final repository = BackendSocialLocationRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://sporto.asia/api/v1'))
        ..httpClientAdapter = adapter,
    );

    final places = await repository.search('MK building');

    expect(places.single.canPreview, isTrue);
    expect(adapter.requests.single.uri.path, '/api/v1/social-locations/search');
    expect(adapter.requests.single.uri.queryParameters['q'], 'MK building');
    expect(adapter.requests.single.extra['noCache'], isTrue);
  });

  test('resolve and reverse preserve a pinned result', () async {
    final adapter = _Adapter((_) => _json({'data': _place}));
    final repository = BackendSocialLocationRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://sporto.asia/api/v1'))
        ..httpClientAdapter = adapter,
    );

    expect((await repository.resolveInput('1 Lữ Gia')).canPreview, isTrue);
    expect(
      (await repository.reverseLookup(
        const LatLng(10.762, 106.657),
      )).canPreview,
      isTrue,
    );
    expect(adapter.requests.map((r) => r.uri.path), [
      '/api/v1/social-locations/resolve',
      '/api/v1/social-locations/reverse',
    ]);
  });

  test('upstream 503 stays a network failure', () async {
    final repository = BackendSocialLocationRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://sporto.asia/api/v1'))
        ..httpClientAdapter = _Adapter(
          (_) => _json({'message': 'unavailable'}, 503),
        ),
    );
    await expectLater(
      repository.search('MK'),
      throwsA(isA<LocationNetworkFailure>()),
    );
  });

  test(
    'Google place URL resolves its named place instead of viewport coordinates',
    () async {
      final adapter = _Adapter((_) => _json({'data': _place}));
      final repository = BackendSocialLocationRepository(
        dio: Dio(BaseOptions(baseUrl: 'https://sporto.asia/api/v1'))
          ..httpClientAdapter = adapter,
      );

      await repository.resolveInput(
        'https://www.google.com/maps/place/MK+Building/@10.1,106.1,17z',
      );

      expect(
        adapter.requests.single.uri.path,
        '/api/v1/social-locations/resolve',
      );
    },
  );

  test('short Google link expands locally before backend resolution', () async {
    final backend = _Adapter((_) => _json({'data': _place}));
    final links = _Adapter(
      (_) => ResponseBody.fromString(
        '',
        302,
        headers: {
          'location': ['https://www.google.com/maps/search/?query=MK+Building'],
        },
      ),
    );
    final repository = BackendSocialLocationRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://sporto.asia/api/v1'))
        ..httpClientAdapter = backend,
      linkDio: Dio()..httpClientAdapter = links,
    );

    await repository.resolveInput('https://maps.app.goo.gl/short');

    expect(links.requests.single.uri.host, 'maps.app.goo.gl');
    expect(links.requests.single.connectTimeout, isNotNull);
    expect(links.requests.single.receiveTimeout, isNotNull);
    expect(
      backend.requests.single.uri.path,
      '/api/v1/social-locations/resolve',
    );
  });
}
