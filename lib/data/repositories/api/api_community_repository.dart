import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';

class ApiCommunityRepository {
  static const _log = AppLogger('ApiCommunityRepo');
  final DioClient _dioClient;

  ApiCommunityRepository(this._dioClient);

  /// GET /communities?search=&page=1&limit=20
  Future<List<Community>> getCommunities({String? search, int page = 1, int limit = 20}) async {
    _log.info('Lấy danh sách CLB: search=$search, page=$page');
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _dioClient.dio.get('/communities', queryParameters: params);
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy danh sách CLB', e, stack);
      return [];
    }
  }

  /// GET /communities/my
  Future<List<Community>> getMyCommunities() async {
    _log.info('Lấy CLB của tôi');
    try {
      final response = await _dioClient.dio.get('/communities/my');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        return data.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, stack) {
      _log.error('Lỗi lấy CLB của tôi', e, stack);
      return [];
    }
  }

  /// GET /communities/:id
  Future<Community?> getCommunityById(String id) async {
    _log.info('Lấy chi tiết CLB: $id');
    try {
      final response = await _dioClient.dio.get('/communities/$id');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>? ?? response.data as Map<String, dynamic>?;
        if (data != null) return Community.fromJson(data);
      }
      return null;
    } catch (e, stack) {
      _log.error('Lỗi lấy chi tiết CLB', e, stack);
      return null;
    }
  }
}
