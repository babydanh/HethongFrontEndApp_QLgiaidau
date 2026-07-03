import 'package:app_quanly_giaidau/data/models/community_ranking_model.dart';
import 'package:app_quanly_giaidau/data/models/gallery_image_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/data/models/community_member_model.dart';
import 'package:app_quanly_giaidau/data/models/community_tournament_model.dart';
import 'package:app_quanly_giaidau/data/models/community_invite_model.dart';

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

  /// Lấy danh sách yêu cầu tham gia CLB (OWNER/ADMIN thấy).
  /// GET /communities/:id/join-requests
  Future<List<CommunityMemberModel>> getJoinRequests(String communityId);

  /// Duyệt/từ chối yêu cầu tham gia.
  /// PATCH /communities/:id/join-requests/:memberId { action: 'APPROVE' | 'REJECT' }
  Future<void> reviewJoinRequest(String communityId, String memberId, String action);

  /// Lấy danh sách CLB chờ duyệt (Admin).
  /// GET /communities?status=PENDING
  Future<List<Community>> getPendingCommunities();

  /// Duyệt/từ chối CLB (Admin).
  /// PATCH /communities/:id/review { status, rejectedReason? }
  Future<void> reviewCommunity(String communityId, String status, {String? rejectedReason});

  /// Cập nhật vai trò thành viên (OWNER/ADMIN/MODERATOR/MEMBER).
  /// PATCH /communities/:id/members/:memberId/role { role }
  Future<void> updateMemberRole(String communityId, String memberId, String role);

  /// Xoá/kick thành viên khỏi CLB.
  /// DELETE /communities/:id/members/:userId
  Future<void> removeMember(String communityId, String userId);

  /// Mời thành viên vào CLB (OWNER/ADMIN).
  /// POST /communities/:id/invite { userId, role }
  Future<void> inviteMember(String communityId, String userId, {String role = 'MEMBER'});

  /// Lấy danh sách lời mời CLB của bản thân.
  /// GET /communities/my/invites
  Future<List<CommunityInviteModel>> getMyInvites();

  /// Cập nhật thông tin câu lạc bộ.
  /// PATCH /communities/:id
  Future<Community> updateCommunity(String communityId, Map<String, dynamic> data);

  /// Phản hồi lời mời vào CLB.
  /// POST /communities/:id/invite/:action (ACCEPT | DECLINE)
  Future<void> respondToInvite(String communityId, String action);

  /// Gỡ cấm thành viên.
  /// POST /communities/:id/unban/:userId
  Future<void> unbanMember(String communityId, String userId);
}
