import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/community_search_models.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_community_search_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_search_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final communitySearchRepositoryProvider = Provider<ICommunitySearchRepository>((
  ref,
) {
  return ApiCommunitySearchRepository(ref.watch(dioClientProvider));
});

final communitySearchProvider = FutureProvider.autoDispose
    .family<CommunitySearchResults, CommunitySearchRequest>((ref, request) {
      return ref
          .watch(communitySearchRepositoryProvider)
          .search(
            request.communityId,
            query: request.query,
            type: request.type,
            limit: request.limit,
          );
    });

class CommunitySearchRequest {
  final String communityId;
  final String query;
  final CommunitySearchType type;
  final int limit;

  const CommunitySearchRequest({
    required this.communityId,
    required this.query,
    required this.type,
    this.limit = 10,
  });

  @override
  bool operator ==(Object other) =>
      other is CommunitySearchRequest &&
      other.communityId == communityId &&
      other.query == query &&
      other.type == type &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(communityId, query, type, limit);
}
