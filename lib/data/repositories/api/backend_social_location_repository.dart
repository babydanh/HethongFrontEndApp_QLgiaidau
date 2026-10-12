import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Internal directory adapter. Pins and labels are host supplied; this adapter
/// never geocodes, expands links, or contacts a third-party location service.
class BackendSocialLocationRepository implements ISocialLocationRepository {
  BackendSocialLocationRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;
  CancelToken? _searchToken;

  @override
  Future<List<SocialPlace>> search(String query, {LatLng? bias}) async {
    final value = query.trim();
    if (value.length < 3) return const [];
    _searchToken?.cancel();
    final token = CancelToken();
    _searchToken = token;
    try {
      final response = await _dio.get<dynamic>(
        '/social-locations/search',
        queryParameters: {'q': value, 'limit': 10},
        options: Options(extra: {'noCache': true}),
        cancelToken: token,
      );
      final data = response.data is Map
          ? (response.data as Map)['data']
          : response.data;
      if (data is! List) throw const UnresolvableLocation();
      final places = data
          .whereType<Map>()
          .map(_venue)
          .where((venue) => venue.canApply && venue.hasPin)
          .toList();
      if (bias != null) {
        const distance = Distance();
        places.sort(
          (a, b) => distance
              .as(LengthUnit.Meter, bias, LatLng(a.latitude!, a.longitude!))
              .compareTo(
                distance.as(
                  LengthUnit.Meter,
                  bias,
                  LatLng(b.latitude!, b.longitude!),
                ),
              ),
        );
      }
      return places;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return const [];
      throw _failure(error);
    }
  }

  @override
  Future<SocialPlace> getVenueDetail(String venueId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/venues/${Uri.encodeComponent(venueId)}',
        options: Options(extra: {'noCache': true}),
      );
      final envelope = response.data;
      final data = envelope is Map ? envelope['data'] ?? envelope : envelope;
      if (data is! Map) throw const UnresolvableLocation();
      return _venue(data);
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  @override
  Future<SocialPlace> getPlaceDetail(String placeId) => getVenueDetail(placeId);

  @override
  Future<SocialPlace> resolveInput(String addressOrMapsUrl) async {
    throw const UnresolvableLocation();
  }

  /// Điểm ghim không có geocode provider nào (endpoint `/social-locations/reverse`
  /// đã bị backend gỡ với 410). Địa chỉ lấy từ `/regions/resolve` — phường bao
  /// phủ điểm — nên là địa chỉ hành chính, không phải số nhà/số đường.
  @override
  Future<SocialPlace> reverseLookup(LatLng pin) async {
    try {
      final response = await _dio.get<dynamic>(
        '/regions/resolve',
        queryParameters: {
          'lat': pin.latitude.toString(),
          'lng': pin.longitude.toString(),
        },
        options: Options(extra: {'noCache': true}),
      );
      final envelope = response.data;
      final raw = envelope is Map ? envelope['data'] ?? envelope : envelope;
      if (raw is! Map) throw const UnresolvableLocation();
      return _region(raw, pin);
    } on DioException catch (error) {
      throw _failure(error);
    }
  }

  /// `GET /regions/resolve`: `wardName` + `provinceName` là nguồn địa chỉ duy
  /// nhất cho điểm ghim. `centerLat/centerLng` là tâm phường nên bỏ qua, giữ
  /// đúng toạ độ người dùng chọn.
  SocialPlace _region(Map raw, LatLng pin) {
    final wardName = raw['wardName']?.toString().trim() ?? '';
    final provinceName = raw['provinceName']?.toString().trim() ?? '';
    final address = <String>[
      if (wardName.isNotEmpty) wardName,
      if (provinceName.isNotEmpty && provinceName != wardName) provinceName,
    ].join(', ');
    if (address.isEmpty) throw const UnresolvableLocation();
    return SocialPlace(
      name: wardName.isNotEmpty ? wardName : provinceName,
      formattedAddress: address,
      latitude: pin.latitude,
      longitude: pin.longitude,
      provinceCode: raw['provinceCode']?.toString(),
      wardCode: raw['wardCode']?.toString(),
      regionEstimated: raw['isEstimated'] == true,
    );
  }

  SocialPlace _venue(Map raw) {
    final name = raw['name']?.toString().trim() ?? '';
    final address =
        (raw['formattedAddress'] ?? raw['locationAddress'])
            ?.toString()
            .trim() ??
        '';
    final latitude = (raw['latitude'] as num?)?.toDouble();
    final longitude = (raw['longitude'] as num?)?.toDouble();
    if (name.isEmpty ||
        address.isEmpty ||
        ((latitude == null) != (longitude == null))) {
      throw const UnresolvableLocation();
    }
    return SocialPlace(
      name: name,
      formattedAddress: address,
      latitude: latitude,
      longitude: longitude,
      venueId: (raw['venueId'] ?? raw['id'])?.toString(),
      provinceCode: raw['provinceCode']?.toString(),
      wardCode: raw['wardCode']?.toString(),
    );
  }

  SocialLocationFailure _failure(DioException error) {
    final status = error.response?.statusCode;
    if (status == 404) return const LocationNotFound();
    if (status == 400 || status == 422) return const UnresolvableLocation();
    return const LocationNetworkFailure();
  }
}
