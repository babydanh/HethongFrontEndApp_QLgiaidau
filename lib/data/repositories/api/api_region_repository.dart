import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';

class ApiRegionRepository implements IRegionRepository {
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
    return _fetch('/regions/wards', query: {'provinceCode': provinceCode});
  }

  Future<List<Region>> _fetch(String path, {Map<String, String>? query}) async {
    try {
      final response = await _dioClient.dio.get(path, queryParameters: query);
      final raw = response.data is Map ? response.data['data'] : response.data;
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((item) => Region.fromJson(Map<String, dynamic>.from(item)))
          .where((region) => region.code.isNotEmpty && region.name.isNotEmpty)
          .toList();
    } catch (e, stack) {
      _log.error('Lỗi tải đơn vị hành chính: $path', e, stack);
      return [];
    }
  }
}
