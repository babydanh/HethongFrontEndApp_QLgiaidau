import 'dart:convert';
import 'dart:typed_data';

import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/data/repositories/api/hybrid_social_location_repository.dart';
import 'package:app_quanly_giaidau/data/repositories/api/nominatim_reverse_datasource.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

const _photonPlace = SocialPlace(
  name: 'Sân Phú Thọ',
  formattedAddress: '1 Lữ Gia, Hồ Chí Minh, Việt Nam',
  latitude: 10.762,
  longitude: 106.657,
);

const _ward = Region(
  code: '26860',
  name: 'Phường Bình Trưng',
  provinceCode: '79',
  type: 'ward',
  provinceName: 'TP Hồ Chí Minh',
);

class _FakePhoton implements ISocialLocationRepository {
  Future<List<SocialPlace>> Function(String)? onSearch;
  Future<SocialPlace> Function(String)? onResolve;
  Future<SocialPlace> Function(LatLng)? onReverse;

  @override
  Future<List<SocialPlace>> search(String query) =>
      onSearch?.call(query) ?? Future.value(const [_photonPlace]);

  @override
  Future<SocialPlace> resolveInput(String value) =>
      onResolve?.call(value) ?? Future.value(_photonPlace);

  @override
  Future<SocialPlace> reverseLookup(LatLng pin) =>
      onReverse?.call(pin) ?? Future.value(_photonPlace);
}

class _FakeRegions implements IRegionRepository {
  Future<List<Region>> Function(String, int)? onSearch;
  List<Region> provinces = const [];

  @override
  Future<List<Region>> getProvinces() async => provinces;

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async =>
      const [];

  @override
  Future<List<Region>> searchRegions(String query, {int limit = 10}) =>
      onSearch?.call(query, limit) ?? Future.value(const [_ward]);
}

class _NominatimAdapter implements HttpClientAdapter {
  _NominatimAdapter(this.reply);

  final ResponseBody Function(RequestOptions) reply;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => reply(options);

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

NominatimReverseDataSource _nominatim(Object reply) =>
    NominatimReverseDataSource(
      dio: Dio()..httpClientAdapter = _NominatimAdapter((_) => _json(reply)),
    );

HybridSocialLocationRepository _repo({
  _FakePhoton? photon,
  _FakeRegions? regions,
  NominatimReverseDataSource? nominatim,
}) => HybridSocialLocationRepository(
  photon: photon ?? _FakePhoton(),
  regions: regions ?? _FakeRegions(),
  nominatim: nominatim ?? NominatimReverseDataSource(),
);

void main() {
  test('search merges photon pins first and dedupes region areas', () async {
    final repository = _repo();

    final results = await repository.search('Bình Trưng');

    expect(results.first, _photonPlace);
    final area = results.last;
    expect(area.hasPin, isFalse);
    expect(area.name, 'Phường Bình Trưng');
    expect(area.formattedAddress, 'Phường Bình Trưng, TP Hồ Chí Minh');
    expect(area.canApply, isTrue);
  });

  test('search still returns region areas when photon fails', () async {
    final photon = _FakePhoton()
      ..onSearch = (_) async => throw const LocationNetworkFailure();
    final repository = _repo(photon: photon);

    final results = await repository.search('Bình Trưng');

    expect(results, hasLength(1));
    expect(results.single.name, 'Phường Bình Trưng');
  });

  test('search throws network failure only when both sources fail', () async {
    final photon = _FakePhoton()
      ..onSearch = (_) async => throw const LocationNetworkFailure();
    final regions = _FakeRegions()
      ..onSearch = (_, _) async => throw const RegionSearchFailure();
    final repository = _repo(photon: photon, regions: regions);

    expect(
      () => repository.search('Bình Trưng'),
      throwsA(isA<LocationNetworkFailure>()),
    );
  });

  test('resolveInput does not turn a missing address into a region', () async {
    final photon = _FakePhoton()
      ..onResolve = (_) async => throw const LocationNotFound();
    var regionSearched = false;
    final regions = _FakeRegions()
      ..onSearch = (_, _) async {
        regionSearched = true;
        return const [_ward];
      };
    final repository = _repo(photon: photon, regions: regions);

    await expectLater(
      repository.resolveInput('1 Lữ Gia, Phường Bình Trưng'),
      throwsA(isA<LocationNotFound>()),
    );
    expect(regionSearched, isFalse);
  });

  test('resolveInput preserves a Photon network failure', () async {
    final photon = _FakePhoton()
      ..onResolve = (_) async => throw const LocationNetworkFailure();
    await expectLater(
      _repo(photon: photon).resolveInput('1 Lữ Gia'),
      throwsA(isA<LocationNetworkFailure>()),
    );
  });

  test(
    'resolveInput rethrows unsupported links without region fallback',
    () async {
      final photon = _FakePhoton()
        ..onResolve = (_) async => throw const UnsupportedLocationLink();
      final regions = _FakeRegions()..onSearch = (_, _) async => const [_ward];
      final repository = _repo(photon: photon, regions: regions);

      expect(
        () => repository.resolveInput('https://evil.example/maps'),
        throwsA(isA<UnsupportedLocationLink>()),
      );
    },
  );

  test('reverseLookup falls back to nominatim when photon is empty', () async {
    final photon = _FakePhoton()
      ..onReverse = (_) async => throw const UnresolvableLocation();
    final nominatim = _nominatim({
      'display_name':
          '123 Nguyễn Trãi, Phường Bến Thành, TP Hồ Chí Minh, Việt Nam',
      'address': {
        'house_number': '123',
        'road': 'Nguyễn Trãi',
        'suburb': 'Phường Bến Thành',
        'city': 'TP Hồ Chí Minh',
        'country': 'Việt Nam',
      },
    });
    final repository = _repo(photon: photon, nominatim: nominatim);

    final place = await repository.reverseLookup(const LatLng(10.775, 106.699));

    expect(place.formattedAddress, contains('Nguyễn Trãi'));
    expect(place.latitude, 10.775);
    expect(place.longitude, 106.699);
  });

  test(
    'reverseLookup throws the photon error when nominatim also fails',
    () async {
      final photon = _FakePhoton()
        ..onReverse = (_) async => throw const UnresolvableLocation();
      final nominatim = _nominatim({'error': 'Unable to geocode'});
      final repository = _repo(photon: photon, nominatim: nominatim);

      expect(
        () => repository.reverseLookup(const LatLng(0, 0)),
        throwsA(isA<UnresolvableLocation>()),
      );
    },
  );
}
