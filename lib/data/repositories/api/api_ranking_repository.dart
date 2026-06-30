import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/domain/entities/ranking.dart';
import 'package:app_quanly_giaidau/domain/repositories/ranking_repository.dart';

class ApiRankingRepository implements IRankingRepository {
  static const _log = AppLogger('ApiRankingRepo');
  final DioClient _dioClient;

  ApiRankingRepository(this._dioClient);

  @override
  Future<List<PlayerRanking>> getRankings({
    int? page,
    int? limit,
    String? categoryId,
  }) async {
    _log.info('Tải bảng xếp hạng: page=$page, limit=$limit, categoryId=$categoryId');
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (limit != null) queryParams['limit'] = limit;
      if (categoryId != null) queryParams['categoryId'] = categoryId;

      final response = await _dioClient.dio.get(
        '/rankings',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        return dataList
            .map((json) => PlayerRanking.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Không thể tải bảng xếp hạng');
    } catch (e, stack) {
      _log.error('Lỗi tải bảng xếp hạng', e, stack);
      rethrow;
    }
  }

  @override
  Future<UserRankResponse> getUserRank(
    String userId,
    String categoryId,
  ) async {
    _log.info('Tải rank của user: $userId trong category: $categoryId');
    try {
      final response = await _dioClient.dio.get(
        '/rankings/user/$userId',
        queryParameters: categoryId.isNotEmpty ? {'categoryId': categoryId} : null,
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        final data = raw['data'] as Map<String, dynamic>? ?? raw as Map<String, dynamic>?;
        // API trả về { publicRanks: [...], communityRanks: [...] }
        // Tìm rank trong publicRanks theo categoryId
        if (data != null) {
          final publicRanks = data['publicRanks'] as List<dynamic>? ?? [];
          for (final r in publicRanks) {
            final rank = PlayerRanking.fromJson(r as Map<String, dynamic>);
            if (rank.categoryId == categoryId || categoryId.isEmpty) {
              return UserRankResponse(eloPoints: rank.eloPoints, tierName: rank.tierName, categoryId: rank.categoryId);
            }
          }
          return UserRankResponse(eloPoints: 1000, tierName: 'Chưa xếp hạng', categoryId: categoryId);
        }
      }

      throw Exception('Không thể tải thông tin xếp hạng của người dùng');
    } catch (e, stack) {
      _log.error('Lỗi tải user rank', e, stack);
      rethrow;
    }
  }
}
