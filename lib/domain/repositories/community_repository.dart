import 'package:app_quanly_giaidau/data/models/community_ranking_model.dart';
import 'package:app_quanly_giaidau/data/models/gallery_image_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';

/// Interface cho Community Repository — DIP
abstract class ICommunityRepository {
  Future<List<Community>> getCommunities({String? search, int page = 1, int limit = 20});
  Future<List<Community>> getMyCommunities();
  Future<Community?> getCommunityById(String id);
  Future<List<CommunityMemberModel>> getMembers(String communityId, {int page = 1, int limit = 50});
  Future<bool> joinCommunity(String communityId, {Map<String, dynamic>? answers});
  Future<bool> leaveCommunity(String communityId, String userId);
  Future<List<CommunityTournamentModel>> getTournaments(String communityId);
  Future<CommunityTournamentModel?> createTournament(String communityId, Map<String, dynamic> data);
  Future<Community?> createCommunity(Map<String, dynamic> data);
  Future<List<GalleryImageModel>> getGallery(String communityId);
  Future<List<CommunityRankingModel>> getRankings(String communityId, {int limit = 50});
}
