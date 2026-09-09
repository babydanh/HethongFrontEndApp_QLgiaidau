import 'package:app_quanly_giaidau/data/models/community_search_models.dart';

abstract class ICommunitySearchRepository {
  Future<CommunitySearchResults> search(
    String communityId, {
    required String query,
    CommunitySearchType type = CommunitySearchType.all,
    int limit = 10,
  });
}
