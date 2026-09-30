import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/data/repositories/api/api_social_location_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

class _LocationAdapter implements HttpClientAdapter {
  _LocationAdapter(this.reply);

  final ResponseBody Function(RequestOptions) reply;
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

final _places = {
  'features': [
    {
      'properties': {
        'name': 'Nhà thi đấu Phú Thọ',
        'housenumber': '1',
        'street': 'Lữ Gia',
        'city': 'Hồ Chí Minh',
        'country': 'Việt Nam',
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [106.657, 10.762],
      },
    },
  ],
};

void main() {
  test('searches names and addresses and returns a readable place', () async {
    final adapter = _LocationAdapter((_) => _json(_places));
    final repository = ApiSocialLocationRepository(
      dio: Dio()..httpClientAdapter = adapter,
    );

    final byName = await repository.search('Nhà thi đấu Phú Thọ');
    final byAddress = await repository.search('1 Lữ Gia');

    expect(byName.single.name, 'Nhà thi đấu Phú Thọ');
    expect(byName.single.formattedAddress, '1 Lữ Gia, Hồ Chí Minh, Việt Nam');
    expect(byAddress.single.latitude, 10.762);
    expect(byAddress.single.longitude, 106.657);
    expect(adapter.requested.map((uri) => uri.path), everyElement('/api'));
    expect(adapter.requested.last.queryParameters['q'], '1 Lữ Gia');
  });

  test('resolves a full address to a pinned place', () async {
    final adapter = _LocationAdapter((_) => _json(_places));
    final repository = ApiSocialLocationRepository(
      dio: Dio()..httpClientAdapter = adapter,
    );

    final place = await repository.resolveInput(' 1 Lữ Gia, Hồ Chí Minh ');

    expect(place.name, 'Nhà thi đấu Phú Thọ');
    expect(place.latitude, 10.762);
    expect(
      adapter.requested.single.queryParameters['q'],
      '1 Lữ Gia, Hồ Chí Minh',
    );
  });

  test('address resolution skips an unrelated Photon first result', () async {
    final unrelated = {
      'properties': {
        'name': 'Quán Ăn Vương Gia Tửu',
        'housenumber': '15',
        'street': 'Hoa Phượng',
        'city': 'Hồ Chí Minh',
      },
      'geometry': {
        'coordinates': [106.687, 10.797],
      },
    };
    final repository = ApiSocialLocationRepository(
      dio: Dio()
        ..httpClientAdapter = _LocationAdapter(
          (_) => _json({
            'features': [unrelated, ..._places['features']!],
          }),
        ),
    );

    final place = await repository.resolveInput('1 Lữ Gia, Hồ Chí Minh');
    expect(place.name, 'Nhà thi đấu Phú Thọ');
    expect(place.formattedAddress, startsWith('1 Lữ Gia'));
  });

  test('a district centroid cannot be previewed as a street address', () async {
    final repository = ApiSocialLocationRepository(
      dio: Dio()
        ..httpClientAdapter = _LocationAdapter(
          (_) => _json({
            'features': [
              {
                'properties': {
                  'name': 'Bình Trưng',
                  'district': 'Phường Bình Trưng',
                  'city': 'Hồ Chí Minh',
                },
                'geometry': {
                  'coordinates': [106.8, 10.78],
                },
              },
            ],
          }),
        ),
    );

    expect(await repository.search('Bình Trưng'), hasLength(1));
    await expectLater(
      repository.resolveInput('Bình Trưng'),
      throwsA(isA<LocationNotFound>()),
    );
  });

  test('resolves a Google Maps coordinate link by reverse lookup', () async {
    final adapter = _LocationAdapter((options) {
      expect(options.uri.path, '/reverse');
      return _json(_places);
    });
    final repository = ApiSocialLocationRepository(
      dio: Dio()..httpClientAdapter = adapter,
    );

    final place = await repository.resolveInput(
      'https://www.google.com/maps/search/?api=1&query=10.762,106.657',
    );

    expect(place.formattedAddress, contains('Lữ Gia'));
    expect(place.latitude, 10.762);
    expect(adapter.requested.single.queryParameters['lat'], '10.762');
  });

  test('reverse lookup preserves the exact selected pin', () async {
    final repository = ApiSocialLocationRepository(
      dio: Dio()..httpClientAdapter = _LocationAdapter((_) => _json(_places)),
    );

    final place = await repository.reverseLookup(const LatLng(10.761, 106.658));

    expect(place.formattedAddress, contains('Lữ Gia'));
    expect(place.latitude, 10.761);
    expect(place.longitude, 106.658);
  });

  test('rejects unsupported links without requesting them', () async {
    final adapter = _LocationAdapter((_) => _json(_places));
    final repository = ApiSocialLocationRepository(
      dio: Dio()..httpClientAdapter = adapter,
    );

    expect(
      () => repository.resolveInput('https://evil.example/maps?q=1'),
      throwsA(isA<UnsupportedLocationLink>()),
    );
    expect(adapter.requested, isEmpty);
    await expectLater(
      repository.resolveInput('HTTPS://evil.example/maps?q=1'),
      throwsA(isA<UnsupportedLocationLink>()),
    );
    expect(adapter.requested, isEmpty);
  });

  test(
    'expands an allowed short link and rejects an off-host redirect',
    () async {
      final allowed = _LocationAdapter((options) {
        if (options.uri.host == 'maps.app.goo.gl') {
          return ResponseBody.fromString(
            '',
            302,
            headers: {
              'location': [
                'https://www.google.com/maps/search/?api=1&query=1%20L%E1%BB%AF%20Gia',
              ],
            },
          );
        }
        return _json(_places);
      });
      final repository = ApiSocialLocationRepository(
        dio: Dio()..httpClientAdapter = allowed,
      );

      final place = await repository.resolveInput(
        'https://maps.app.goo.gl/abc',
      );

      expect(place.name, 'Nhà thi đấu Phú Thọ');
      expect(allowed.requested.map((uri) => uri.host), [
        'maps.app.goo.gl',
        'photon.komoot.io',
      ]);

      final unsafe = _LocationAdapter(
        (_) => ResponseBody.fromString(
          '',
          302,
          headers: {
            'location': ['https://evil.example/steal'],
          },
        ),
      );
      final unsafeRepository = ApiSocialLocationRepository(
        dio: Dio()..httpClientAdapter = unsafe,
      );
      await expectLater(
        unsafeRepository.resolveInput('https://maps.app.goo.gl/abc'),
        throwsA(isA<UnsupportedLocationLink>()),
      );
      expect(unsafe.requested, hasLength(1));
    },
  );

  test('rejects results without a street-level readable address', () async {
    final repository = ApiSocialLocationRepository(
      dio: Dio()
        ..httpClientAdapter = _LocationAdapter(
          (_) => _json({
            'features': [
              {
                'properties': {'name': 'Hồ Chí Minh', 'country': 'Việt Nam'},
                'geometry': {
                  'type': 'Point',
                  'coordinates': [106.7, 10.8],
                },
              },
            ],
          }),
        ),
    );

    expect(
      () => repository.reverseLookup(const LatLng(10.8, 106.7)),
      throwsA(isA<UnresolvableLocation>()),
    );
  });

  test(
    'uses a named road as the street address when Photon omits street',
    () async {
      final repository = ApiSocialLocationRepository(
        dio: Dio()
          ..httpClientAdapter = _LocationAdapter(
            (_) => _json({
              'features': [
                {
                  'properties': {
                    'name': 'Hẻm 12 Lữ Gia',
                    'osm_key': 'highway',
                    'city': 'Hồ Chí Minh',
                    'country': 'Việt Nam',
                  },
                  'geometry': {
                    'type': 'Point',
                    'coordinates': [106.657, 10.762],
                  },
                },
              ],
            }),
          ),
      );

      final place = await repository.reverseLookup(
        const LatLng(10.762, 106.657),
      );

      expect(place.name, 'Hẻm 12 Lữ Gia');
      expect(place.formattedAddress, 'Hẻm 12 Lữ Gia, Hồ Chí Minh, Việt Nam');
    },
  );

  test(
    'accepts district-level VN results without a street and biases VN',
    () async {
      final adapter = _LocationAdapter(
        (_) => _json({
          'features': [
            {
              'properties': {
                'name': 'Bình Trưng',
                'district': 'Phường Bình Trưng',
                'city': 'TP Hồ Chí Minh',
                'state': 'Hồ Chí Minh',
                'country': 'Việt Nam',
              },
              'geometry': {
                'type': 'Point',
                'coordinates': [106.8, 10.78],
              },
            },
          ],
        }),
      );
      final repository = ApiSocialLocationRepository(
        dio: Dio()..httpClientAdapter = adapter,
      );

      final results = await repository.search('Bình Trưng');

      expect(results, hasLength(1));
      expect(results.single.name, 'Bình Trưng');
      expect(
        results.single.formattedAddress,
        'Phường Bình Trưng, TP Hồ Chí Minh, Hồ Chí Minh, Việt Nam',
      );
      expect(adapter.requested.single.queryParameters['bbox'], isNotEmpty);
    },
  );

  test('distinguishes empty results from network failure', () async {
    final empty = ApiSocialLocationRepository(
      dio: Dio()
        ..httpClientAdapter = _LocationAdapter((_) => _json({'features': []})),
    );
    final offline = ApiSocialLocationRepository(
      dio: Dio()
        ..httpClientAdapter = _LocationAdapter(
          (_) => throw DioException(
            requestOptions: RequestOptions(path: '/api'),
            type: DioExceptionType.connectionError,
          ),
        ),
    );

    expect(await empty.search('missing'), isEmpty);
    expect(
      () => empty.resolveInput('1 Lữ Gia'),
      throwsA(isA<LocationNotFound>()),
    );
    expect(
      () => offline.search('1 Lữ Gia'),
      throwsA(isA<LocationNetworkFailure>()),
    );
  });
}
