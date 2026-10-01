import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Uses the Sporto API for geocoding. Only Google link expansion bypasses it.
class BackendSocialLocationRepository implements ISocialLocationRepository {
  BackendSocialLocationRepository({required Dio dio, Dio? linkDio})
    : _dio = dio,
      _linkDio = linkDio ?? Dio();

  final Dio _dio;
  final Dio _linkDio;
  CancelToken? _searchToken;

  static const _googleHosts = {
    'google.com',
    'www.google.com',
    'maps.google.com',
    'maps.app.goo.gl',
    'goo.gl',
  };

  @override
  Future<List<SocialPlace>> search(String query, {LatLng? bias}) async {
    final value = query.trim();
    if (value.length < 3) return const [];
    _searchToken?.cancel();
    final token = CancelToken();
    _searchToken = token;
    try {
      final queryParams = <String, dynamic>{'q': value, 'limit': 8};
      if (bias != null &&
          bias.latitude >= -90 &&
          bias.latitude <= 90 &&
          bias.longitude >= -180 &&
          bias.longitude <= 180) {
        queryParams['lat'] = bias.latitude;
        queryParams['lng'] = bias.longitude;
      }
      final response = await _dio.get<dynamic>(
        '/places/autocomplete',
        queryParameters: queryParams,
        options: Options(extra: {'noCache': true}),
        cancelToken: token,
      );
      final data = _data(response.data);
      if (data is! List) throw const UnresolvableLocation();
      return data.whereType<Map>().map(_place).toList(growable: false);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const [];
      throw _failure(error);
    }
  }

  @override
  Future<SocialPlace> getPlaceDetail(String placeId) async {
    final value = placeId.trim();
    if (value.isEmpty) throw const LocationNotFound();
    try {
      final response = await _dio.get<dynamic>(
        '/places/${Uri.encodeComponent(value)}',
        options: Options(extra: {'noCache': true}),
      );
      return _place(_map(_data(response.data)));
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<SocialPlace> resolveInput(String addressOrMapsUrl) async {
    var value = addressOrMapsUrl.trim();
    if (value.isEmpty) throw const LocationNotFound();
    if (value.startsWith('photon:')) {
      return getPlaceDetail(value);
    }
    if (RegExp(
      r'^[a-z][a-z0-9+.-]*://',
      caseSensitive: false,
    ).hasMatch(value)) {
      final initial = Uri.tryParse(value);
      if (initial == null || !_allowed(initial)) {
        throw const UnsupportedLocationLink();
      }
      final uri = await _expand(initial);
      final pair = _coordinates(
        uri.queryParameters['query'] ??
            uri.queryParameters['q'] ??
            uri.queryParameters['ll'],
      );
      if (pair != null) return reverseLookup(pair);
      final segments = uri.pathSegments;
      final index = segments.indexOf('place');
      value =
          uri.queryParameters['query'] ??
          uri.queryParameters['q'] ??
          (index >= 0 && index + 1 < segments.length
              ? segments[index + 1].replaceAll('+', ' ')
              : '');
      if (value.trim().isEmpty) {
        final pathPair = RegExp(
          r'@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)',
        ).firstMatch(uri.path);
        if (pathPair != null) {
          final pin = _coordinates('${pathPair.group(1)},${pathPair.group(2)}');
          if (pin != null) return reverseLookup(pin);
        }
      }
      if (value.trim().isEmpty) throw const UnsupportedLocationLink();
    }
    try {
      final response = await _dio.post<dynamic>(
        '/social-locations/resolve',
        data: {'text': value},
      );
      return _place(_map(_data(response.data)));
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<SocialPlace> reverseLookup(LatLng pin) async {
    try {
      final response = await _dio.get<dynamic>(
        '/places/reverse',
        queryParameters: {'lat': pin.latitude, 'lng': pin.longitude},
        options: Options(extra: {'noCache': true}),
      );
      final place = _place(_map(_data(response.data)));
      return SocialPlace(
        name: place.name,
        formattedAddress: place.formattedAddress,
        latitude: pin.latitude,
        longitude: pin.longitude,
        placeId: place.placeId,
        sourceProvince: place.sourceProvince,
        sourceWard: place.sourceWard,
        provinceCode: place.provinceCode,
        wardCode: place.wardCode,
        regionEstimated: place.regionEstimated,
      );
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  dynamic _data(dynamic raw) => raw is Map ? raw['data'] : raw;

  Map _map(dynamic raw) {
    if (raw is Map) return raw;
    throw const UnresolvableLocation();
  }

  SocialPlace _place(Map raw) {
    final name = raw['name']?.toString().trim() ?? '';
    final address = raw['formattedAddress']?.toString().trim() ?? '';
    final lat = (raw['latitude'] as num?)?.toDouble();
    final lon = (raw['longitude'] as num?)?.toDouble();
    if (name.isEmpty ||
        address.isEmpty ||
        lat == null ||
        lon == null ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      throw const UnresolvableLocation();
    }
    return SocialPlace(
      name: name,
      formattedAddress: address,
      latitude: lat,
      longitude: lon,
      placeId: raw['placeId']?.toString(),
      sourceProvince: raw['sourceProvince']?.toString(),
      sourceWard: raw['sourceWard']?.toString(),
      provinceCode: raw['provinceCode']?.toString(),
      wardCode: raw['wardCode']?.toString(),
      regionEstimated: raw['regionEstimated'] == true,
    );
  }

  SocialLocationFailure _failure(DioException error) {
    final status = error.response?.statusCode;
    final rawData = error.response?.data;
    final code = rawData is Map ? rawData['code']?.toString() : null;

    if (code == 'LOCATION_PAIR_REQUIRED') {
      return const UnresolvableLocation();
    }
    if (code == 'PLACE_NOT_FOUND' || status == 404) {
      return const LocationNotFound();
    }
    if (code == 'INCOMPLETE_PLACE' || status == 422) {
      return const UnresolvableLocation();
    }
    if (code == 'PLACE_PROVIDER_UNAVAILABLE' ||
        code == 'PLACE_QUOTA_EXCEEDED' ||
        status == 503) {
      return const LocationNetworkFailure();
    }

    switch (status) {
      case 404:
        return const LocationNotFound();
      case 422:
        return const UnresolvableLocation();
      default:
        return const LocationNetworkFailure();
    }
  }

  bool _allowed(Uri uri) =>
      uri.scheme == 'https' && _googleHosts.contains(uri.host.toLowerCase());

  Future<Uri> _expand(Uri initial) async {
    var current = initial;
    for (var hop = 0; hop < 5; hop++) {
      if (!_allowed(current)) throw const UnsupportedLocationLink();
      if (current.host != 'maps.app.goo.gl' && current.host != 'goo.gl') {
        return current;
      }
      try {
        final response = await _linkDio.getUri<dynamic>(
          current,
          options: Options(
            followRedirects: false,
            validateStatus: (status) => status != null && status < 400,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
        final location = response.headers.value('location');
        if (location == null || location.isEmpty) {
          throw const UnresolvableLocation();
        }
        current = current.resolve(location);
      } on DioException {
        throw const LocationNetworkFailure();
      }
    }
    throw const UnsupportedLocationLink();
  }

  LatLng? _coordinates(String? value) {
    final match = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(value ?? '');
    if (match == null) return null;
    final lat = double.tryParse(match.group(1)!);
    final lon = double.tryParse(match.group(2)!);
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
      return null;
    }
    return LatLng(lat, lon);
  }
}
