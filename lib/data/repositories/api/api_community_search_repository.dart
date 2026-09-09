import 'package:app_quanly_giaidau/core/services/dio_client.dart';
import 'package:app_quanly_giaidau/data/models/community_search_models.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_search_repository.dart';

class ApiCommunitySearchRepository implements ICommunitySearchRepository {
  final DioClient _dioClient;

  ApiCommunitySearchRepository(this._dioClient);

  @override
  Future<CommunitySearchResults> search(
    String communityId, {
    required String query,
    CommunitySearchType type = CommunitySearchType.all,
    int limit = 10,
  }) async {
    final response = await _dioClient.dio.get(
      '/communities/$communityId/search',
      queryParameters: {
        'q': query.trim(),
        'type': type.apiValue,
        'limit': limit.clamp(1, 20),
      },
    );
    final body = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : const <String, dynamic>{};
    final data = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : body;
    return CommunitySearchResults.fromJson(data);
  }
}
