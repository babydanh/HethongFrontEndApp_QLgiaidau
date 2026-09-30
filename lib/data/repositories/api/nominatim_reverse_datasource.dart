import 'package:app_quanly_giaidau/data/models/social_place.dart';
import 'package:app_quanly_giaidau/domain/repositories/social_location_repository.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Reverse-geocode fallback qua Nominatim, chỉ dùng khi Photon reverse
/// trả rỗng hoặc lỗi ở VN (theo quyết định dự án).
///
/// Tôn trọng chính sách sử dụng Nominatim: chỉ gọi khi cần (fallback),
/// kèm `User-Agent` định danh app, không gọi dồn/bulk.
class NominatimReverseDataSource {
  NominatimReverseDataSource({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _userAgent = 'asia.sporto.app';

  /// Phân giải [pin] thành địa chỉ đọc được, giữ nguyên tọa độ pin.
  /// Ném [UnresolvableLocation] khi không có địa chỉ,
  /// [LocationNetworkFailure] khi lỗi mạng.
  Future<SocialPlace> reverse(LatLng pin) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': pin.latitude.toString(),
      'lon': pin.longitude.toString(),
      'format': 'jsonv2',
      'accept-language': 'vi',
      'addressdetails': '1',
      'zoom': '18',
    });

    final Map<String, dynamic> data;
    try {
      final response = await _dio.getUri<dynamic>(
        uri,
        options: Options(
          validateStatus: (status) => status != null && status < 400,
          headers: {'Accept': 'application/json', 'User-Agent': _userAgent},
        ),
      );
      final raw = response.data;
      if (raw is! Map) throw const UnresolvableLocation();
      data = Map<String, dynamic>.from(raw);
    } on DioException {
      throw const LocationNetworkFailure();
    }
    if (data['error'] != null) throw const UnresolvableLocation();

    final address = data['address'] is Map
        ? Map<String, dynamic>.from(data['address'] as Map)
        : <String, dynamic>{};
    String part(String key) => (address[key]?.toString() ?? '').trim();

    final displayName = (data['display_name']?.toString() ?? '').trim();
    final road = [
      part('house_number'),
      part('road'),
    ].where((p) => p.isNotEmpty).join(' ');
    final formattedAddress = [
      road,
      part('suburb'),
      part('neighbourhood'),
      part('quarter'),
      part('city'),
      part('town'),
      part('village'),
      part('state'),
      part('country'),
    ].where((p) => p.isNotEmpty).toSet().join(', ');
    final resolvedAddress =
        formattedAddress.isNotEmpty ? formattedAddress : displayName;
    if (resolvedAddress.isEmpty) throw const UnresolvableLocation();

    final named = (data['name']?.toString() ?? '').trim();
    final firstSegment = displayName.split(',').first.trim();
    final name = named.isNotEmpty
        ? named
        : (road.isNotEmpty ? road : firstSegment);

    return SocialPlace(
      name: name.isEmpty ? resolvedAddress : name,
      formattedAddress: resolvedAddress,
      latitude: pin.latitude,
      longitude: pin.longitude,
    );
  }
}
