import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/vietnam_address_parser.dart';
import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Photon API adapter. The endpoint can point to a private Photon instance.
class ApiSocialLocationRepository implements ISocialLocationRepository {
  static const _log = AppLogger('ApiSocialLocationRepository');

  ApiSocialLocationRepository({Dio? dio, String? endpoint})
    : _dio = dio ?? Dio(),
      _endpoint = Uri.parse(
        endpoint ??
            const String.fromEnvironment(
              'SOCIAL_LOCATION_API_URL',
              defaultValue: 'https://photon.komoot.io',
            ),
      );

  final Dio _dio;
  final Uri _endpoint;

  static const _googleHosts = {
    'google.com',
    'www.google.com',
    'maps.google.com',
    'maps.app.goo.gl',
    'goo.gl',
  };

  /// Bbox Việt Nam (minLon,minLat,maxLon,maxLat) để ưu tiên kết quả trong nước.
  static const _vietnamBbox = '102.1,8.0,109.5,23.5';

  @override
  Future<List<SocialPlace>> search(String query, {LatLng? bias}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    return _searchFeatures(trimmed, bias: bias);
  }

  @override
  Future<SocialPlace> getPlaceDetail(String placeId) async {
    return resolveInput(placeId);
  }

  @override
  Future<SocialPlace> getVenueDetail(String venueId) => getPlaceDetail(venueId);

  Future<List<SocialPlace>> _searchFeatures(
    String query, {
    bool requireStreet = false,
    LatLng? bias,
  }) async {
    final params = <String, String>{
      'q': query,
      'limit': '8',
      'bbox': _vietnamBbox,
      'lang': 'default',
      if (bias != null) ...{
        'lat': bias.latitude.toString(),
        'lon': bias.longitude.toString(),
      },
    };
    final response = await _get(
      _endpoint.replace(
        path: '/api',
        queryParameters: params,
      ),
    );
    return _parseFeatures(response.data, requireStreet: requireStreet);
  }

  @override
  Future<SocialPlace> resolveInput(String addressOrMapsUrl) async {
    final value = addressOrMapsUrl.trim();
    if (value.isEmpty) throw const LocationNotFound();
    if (_looksLikeLink(value)) {
      final uri = Uri.tryParse(value);
      if (uri == null || !_allowedGoogleUri(uri)) {
        throw const UnsupportedLocationLink();
      }
      final expanded = await _expandGoogleLink(uri);
      final coordinates = _coordinatesFromGoogleUri(expanded);
      if (coordinates != null) return reverseLookup(coordinates);
      final text =
          expanded.queryParameters['query'] ??
          expanded.queryParameters['q'] ??
          _placeNameFromPath(expanded);
      if (text == null || text.trim().isEmpty) {
        throw const UnsupportedLocationLink();
      }
      return _resolveText(text);
    }
    return _resolveText(value);
  }

  @override
  Future<SocialPlace> reverseLookup(LatLng pin) async {
    final response = await _get(
      _endpoint.replace(
        path: '/reverse',
        queryParameters: {
          'lat': pin.latitude.toString(),
          'lon': pin.longitude.toString(),
          'limit': '1',
        },
      ),
    );
    final matches = _parseFeatures(response.data, requireStreet: true);
    if (matches.isEmpty) throw const UnresolvableLocation();
    final match = matches.first;
    return SocialPlace(
      name: match.name,
      formattedAddress: match.formattedAddress,
      latitude: pin.latitude,
      longitude: pin.longitude,
    );
  }

  Future<SocialPlace> _resolveText(String text) async {
    final results = await _searchFeatures(text, requireStreet: true);
    if (results.isEmpty) throw const LocationNotFound();
    final key = VietnamAddressParser.removeVietnameseTones(
      text.split(',').first,
    );
    final tokens = key.split(' ').where((token) => token.isNotEmpty);
    for (final place in results) {
      final normalized = VietnamAddressParser.removeVietnameseTones(
        '${place.name} ${place.formattedAddress}',
      );
      final words = normalized.split(' ').toSet();
      if (tokens.every(words.contains)) return place;
    }
    throw const LocationNotFound();
  }

  Future<Response<dynamic>> _get(Uri uri, {bool redirects = true}) async {
    try {
      return await _dio.getUri<dynamic>(
        uri,
        options: Options(
          followRedirects: redirects,
          validateStatus: (status) => status != null && status < 400,
          headers: {'Accept': 'application/json'},
        ),
      );
    } on DioException catch (error, stack) {
      _log.error(
        'Photon ${uri.path} failed (${error.type}, HTTP ${error.response?.statusCode})',
        error,
        stack,
      );
      throw const LocationNetworkFailure();
    }
  }

  Future<Uri> _expandGoogleLink(Uri initial) async {
    var current = initial;
    for (var hop = 0; hop < 5; hop++) {
      if (!_allowedGoogleUri(current)) throw const UnsupportedLocationLink();
      if (current.host != 'maps.app.goo.gl' && current.host != 'goo.gl') {
        return current;
      }
      final response = await _get(current, redirects: false);
      final location = response.headers.value('location');
      if (location == null || location.isEmpty) {
        throw const UnresolvableLocation();
      }
      current = current.resolve(location);
    }
    throw const UnsupportedLocationLink();
  }

  bool _allowedGoogleUri(Uri uri) =>
      uri.scheme == 'https' && _googleHosts.contains(uri.host.toLowerCase());

  bool _looksLikeLink(String value) =>
      RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(value);

  LatLng? _coordinatesFromGoogleUri(Uri uri) {
    final query =
        uri.queryParameters['query'] ??
        uri.queryParameters['q'] ??
        uri.queryParameters['ll'];
    final pair = _parseCoordinatePair(query);
    if (pair != null) return pair;
    final match = RegExp(
      r'@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)',
    ).firstMatch(uri.path);
    if (match == null) return null;
    return _parseCoordinatePair('${match.group(1)},${match.group(2)}');
  }

  LatLng? _parseCoordinatePair(String? value) {
    if (value == null) return null;
    final match = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(value);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1)!);
    final lon = double.tryParse(match.group(2)!);
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
      return null;
    }
    return LatLng(lat, lon);
  }

  String? _placeNameFromPath(Uri uri) {
    final segments = uri.pathSegments;
    final index = segments.indexOf('place');
    return index >= 0 && index + 1 < segments.length
        ? segments[index + 1].replaceAll('+', ' ')
        : null;
  }

  List<SocialPlace> _parseFeatures(dynamic raw, {bool requireStreet = false}) {
    if (raw is! Map || raw['features'] is! List) {
      throw const UnresolvableLocation();
    }
    final places = <SocialPlace>[];
    for (final item in raw['features'] as List) {
      if (item is! Map ||
          item['properties'] is! Map ||
          item['geometry'] is! Map) {
        continue;
      }
      final properties = item['properties'] as Map;
      final geometry = item['geometry'] as Map;
      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.length < 2) continue;
      final lon = _number(coordinates[0]);
      final lat = _number(coordinates[1]);
      if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) {
        continue;
      }
      final name = _value(properties['name']);
      // Photon ở VN thường thiếu street/housenumber (chỉ có district/city/
      // state). Không loại kết quả thiếu street nữa; dựng địa chỉ từ mọi
      // part có sẵn, fallback tên khi thiếu hẳn địa chỉ.
      var street = _value(properties['street']);
      if (street.isEmpty &&
          _value(properties['osm_key']) == 'highway' &&
          name.isNotEmpty) {
        street = name;
      }
      final house = _value(properties['housenumber']);
      final streetLine = [
        house,
        street,
      ].where((part) => part.isNotEmpty).join(' ');
      if (requireStreet && streetLine.isEmpty) continue;
      final country = _value(properties['country']);
      final address = [
        streetLine,
        _value(properties['district']),
        _value(properties['city']),
        _value(properties['state']),
        country,
      ].where((part) => part.isNotEmpty).toSet().join(', ');
      if (address.isEmpty && name.isEmpty) continue;
      // Kết quả chỉ còn đúng tên quốc gia thì quá thô để làm địa chỉ sân
      // (giữ hành vi cũ: từ chối), còn cấp quận/huyện/tỉnh/thành vẫn nhận.
      if (country.isNotEmpty && address == country) continue;
      final displayName = name.isEmpty ? address : name;
      final displayAddress = address.isEmpty ? name : address;
      places.add(
        SocialPlace(
          name: displayName,
          formattedAddress: displayAddress,
          latitude: lat,
          longitude: lon,
        ),
      );
    }
    return places;
  }

  String _value(dynamic raw) => raw?.toString().trim() ?? '';

  double? _number(dynamic raw) =>
      raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '');
}
