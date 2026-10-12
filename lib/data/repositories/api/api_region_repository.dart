import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';

class ApiRegionRepository
    implements IRegionRepository, IRegionCentroidRepository {
  static const _log = AppLogger('ApiRegionRepository');
  final DioClient _dioClient;

  ApiRegionRepository(this._dioClient);

  @override
  Future<List<Region>> getProvinces() async {
    _log.info('Lấy danh sách tỉnh/thành');
    return _fetch('/regions/provinces');
  }

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async {
    _log.info('Lấy danh sách phường/xã: provinceCode=$provinceCode');
    // Không gửi provinceCode rỗng: backend hiểu là "không lọc" và trả
    // ward toàn quốc theo ?search thay vì lọc eq('') ra rỗng.
    final query = provinceCode.trim().isEmpty
        ? null
        : {'provinceCode': provinceCode.trim()};
    return _fetch('/regions/wards', query: query);
  }

  @override
  Future<Region?> getWardCentroid(String provinceCode, String wardCode) async {
    try {
      final response = await _dioClient.dio.get(
        '/regions/wards/centroid',
        queryParameters: {'provinceCode': provinceCode, 'wardCode': wardCode},
      );
      final raw = response.data is Map ? response.data['data'] : response.data;
      if (raw is! Map) return null;
      final region = Region.fromJson(Map<String, dynamic>.from(raw));
      return region.latitude != null && region.longitude != null
          ? region
          : null;
    } catch (error, stack) {
      _log.error('Lỗi tải tâm phường', error, stack);
      throw const RegionLookupFailure();
    }
  }

  @override
  Future<List<Region>> searchRegions(String query, {int limit = 10}) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return const [];
    try {
      final response = await _dioClient.dio.get(
        '/regions/search',
        queryParameters: {'q': keyword, 'limit': '$limit'},
      );
      return _parseList(response.data);
    } catch (e, stack) {
      _log.error('Lỗi tìm kiếm khu vực: $keyword', e, stack);
      // Ném lỗi mạng để UI search phân biệt "rỗng" với "thất bại" (retry).
      // Các picker cũ dùng getProvinces/getWardsByProvince vẫn nhận [].
      throw const RegionSearchFailure();
    }
  }

  Future<List<Region>> _fetch(String path, {Map<String, String>? query}) async {
    try {
      final response = await _dioClient.dio.get(path, queryParameters: query);
      return _parseList(response.data);
    } catch (e, stack) {
      _log.error('Lỗi tải đơn vị hành chính: $path', e, stack);
      return [];
    }
  }

  List<Region> _parseList(dynamic data) {
    final raw = data is Map ? data['data'] : data;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Region.fromJson(Map<String, dynamic>.from(item)))
        .where((region) => region.code.isNotEmpty && region.name.isNotEmpty)
        .toList();
  }
}
