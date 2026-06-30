import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/gallery_image_model.dart';
import 'package:app_quanly_giaidau/data/models/community_ranking_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_community_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final communityRepositoryProvider = Provider<ICommunityRepository>((ref) {
  return ApiCommunityRepository(ref.watch(dioClientProvider));
});

/// Provider danh sách CLB có filter + search
final communitiesProvider = FutureProvider.family<List<Community>, String?>((ref, search) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getCommunities(search: search, page: 1, limit: 50);
});

/// Provider CLB của tôi
final myCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  try {
    return await repo.getMyCommunities();
  } catch (e) {
    return [];
  }
});

/// Provider chi tiết 1 CLB
final communityDetailProvider = FutureProvider.family<Community?, String>((ref, id) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getCommunityById(id);
});

/// Provider danh sách thành viên CLB
final communityMembersProvider = FutureProvider.family<List<CommunityMemberModel>, String>((ref, communityId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getMembers(communityId);
});

/// Provider danh sách giải đấu trong CLB
final communityTournamentsProvider = FutureProvider.family<List<CommunityTournamentModel>, String>((ref, communityId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getTournaments(communityId);
});

/// Provider gallery ảnh CLB
final communityGalleryProvider = FutureProvider.family<List<GalleryImageModel>, String>((ref, communityId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getGallery(communityId);
});

/// Provider bảng xếp hạng CLB
final communityRankingsProvider = FutureProvider.family<List<CommunityRankingModel>, String>((ref, communityId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getRankings(communityId);
});
