import 'package:app_quanly_giaidau/data/models/community_ranking_model.dart';
import 'package:app_quanly_giaidau/data/models/gallery_image_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/community_invite_model.dart';

/// Interface cho Community Repository — DIP
abstract class ICommunityRepository {
  Future<List<Community>> getCommunities({
    String? search,
    String? provinceCode,
    int limit = 20,
  });
  Future<List<Community>> getMyCommunities();
  Future<Community?> getCommunityById(String id);
  Future<List<CommunityMemberModel>> getMembers(
    String communityId, {
    int limit = 50,
    String? status,
  });
  Future<bool> joinCommunity(
    String communityId, {
    Map<String, dynamic>? answers,
  });
  Future<bool> leaveCommunity(String communityId, String userId);
  Future<List<CommunityTournamentModel>> getTournaments(String communityId);
  Future<CommunityTournamentModel?> createTournament(
    String communityId,
    Map<String, dynamic> data,
  );
  Future<Community?> createCommunity(Map<String, dynamic> data);
  Future<List<GalleryImageModel>> getGallery(String communityId);
  Future<List<CommunityRankingModel>> getRankings(
    String communityId, {
    int limit = 50,
  });

  /// Lấy danh sách yêu cầu tham gia CLB (OWNER/ADMIN thấy).
  /// GET /communities/:id/join-requests
  Future<List<CommunityMemberModel>> getJoinRequests(String communityId);

  /// Duyệt/từ chối yêu cầu tham gia.
  /// PATCH /communities/:id/join-requests/:memberId { action: 'APPROVE' | 'REJECT' }
  Future<void> reviewJoinRequest(
    String communityId,
    String memberId,
    String action,
  );

  /// Lấy danh sách CLB chờ duyệt (Admin).
  /// Danh sách CLB của tôi (chưa duyệt).
  /// GET /communities/pending (guard ADMIN/MODERATOR)
  Future<List<Community>> getPendingCommunities();

  /// Duyệt/từ chối CLB (Admin).
  /// PATCH /communities/:id/review { status, rejectedReason? }
  Future<void> reviewCommunity(
    String communityId,
    String status, {
    String? rejectedReason,
  });

  /// Cập nhật vai trò thành viên (OWNER/ADMIN/MODERATOR/MEMBER).
  /// PATCH /communities/:id/members/:memberId { role }
  Future<void> updateMemberRole(
    String communityId,
    String memberId,
    String role,
  );

  /// Xoá/kick thành viên khỏi CLB.
  /// DELETE /communities/:id/members/:userId
  Future<void> removeMember(String communityId, String userId);

  /// Mời thành viên vào CLB (OWNER/ADMIN).
  /// POST /communities/:id/invite { userId, role }
  Future<void> inviteMember(
    String communityId,
    String userId, {
    String role = 'MEMBER',
  });

  /// Lấy danh sách lời mời CLB của bản thân.
  /// GET /communities/my/invites
  Future<List<CommunityInviteModel>> getMyInvites();

  /// Cập nhật thông tin câu lạc bộ.
  /// PATCH /communities/:id
  Future<Community> updateCommunity(
    String communityId,
    Map<String, dynamic> data,
  );

  /// Phản hồi lời mời vào CLB.
  /// POST /communities/:id/invite/:action (ACCEPT | DECLINE)
  Future<void> respondToInvite(String communityId, String action);

  /// Gỡ cấm thành viên.
  /// DELETE /communities/:id/members/:userId/ban
  Future<void> unbanMember(String communityId, String userId);

  /// Gán/Xoá tag BQT cho thành viên (OWNER/MODERATOR).
  /// PATCH /communities/:id/members/:userId/tags { tags } — replace toàn bộ,
  /// tối đa 5 tag, mỗi tag 1-24 ký tự; mảng rỗng = xoá hết.
  Future<void> updateMemberTags(
    String communityId,
    String userId,
    List<String> tags,
  );

  /// Xoá câu lạc bộ (OWNER only).
  /// DELETE /communities/:id
  Future<void> deleteCommunity(String communityId);

  /// Membership của user hiện tại trong CLB (thay cho việc quét member list).
  /// GET /communities/:id/my-membership — trả {role, status, memberId, joinedAt};
  /// trả null khi user chưa phải member (404 NOT_MEMBER).
  Future<Map<String, dynamic>?> getMyMembership(String communityId);

  /// Theo dõi CLB.
  /// POST /communities/:id/follow
  Future<bool> followCommunity(String communityId);

  /// Bỏ theo dõi CLB.
  /// DELETE /communities/:id/follow
  Future<bool> unfollowCommunity(String communityId);

  /// Yêu thích CLB.
  /// POST /communities/:id/favorite
  Future<bool> favoriteCommunity(String communityId);

  /// Bỏ yêu thích CLB.
  /// DELETE /communities/:id/favorite
  Future<bool> unfavoriteCommunity(String communityId);

  /// Trạng thái theo dõi CLB của user hiện tại.
  Future<bool> isFollowing(String communityId);

  /// Trạng thái yêu thích CLB của user hiện tại.
  Future<bool> isFavorited(String communityId);
}
