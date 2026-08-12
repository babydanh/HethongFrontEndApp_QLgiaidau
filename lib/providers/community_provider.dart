import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/gallery_image_model.dart';
import 'package:app_quanly_giaidau/data/models/community_invite_model.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_community_repository.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final communityRepositoryProvider = Provider<ICommunityRepository>((ref) {
  return ApiCommunityRepository(ref.watch(dioClientProvider));
});

/// Bộ lọc danh sách CLB (search + tỉnh/thành — server-side như web).
typedef CommunityQuery = ({String? search, String? provinceCode});

/// Provider danh sách CLB có filter + search
final communitiesProvider = FutureProvider.family<List<Community>, CommunityQuery>((ref, query) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getCommunities(
    search: query.search,
    provinceCode: query.provinceCode,
    limit: 50,
  );
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

/// Makes every visible CLB list refetch after a mutation. `communitiesProvider`
/// is a family, so invalidating the family also covers search/province variants.
void invalidateCommunityCollections(dynamic ref) {
  ref.invalidate(communitiesProvider);
  ref.invalidate(myCommunitiesProvider);
}

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

/// Provider danh sách yêu cầu tham gia CLB (OWNER/ADMIN thấy).
final joinRequestsProvider = FutureProvider.family<List<CommunityMemberModel>, String>((ref, communityId) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getJoinRequests(communityId);
});

/// Provider danh sách CLB chờ duyệt (Admin).
final pendingCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getPendingCommunities();
});

/// Provider danh sách lời mời CLB của tôi
final myCommunityInvitesProvider = FutureProvider<List<CommunityInviteModel>>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getMyInvites();
});

/// Trạng thái theo dõi CLB của user hiện tại (P2E.2).
final isFollowingProvider = FutureProvider.family<bool, String>((
  ref,
  communityId,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.isFollowing(communityId);
});

/// Trạng thái yêu thích CLB của user hiện tại (P2E.2).
final isFavoritedProvider = FutureProvider.family<bool, String>((
  ref,
  communityId,
) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.isFavorited(communityId);
});
