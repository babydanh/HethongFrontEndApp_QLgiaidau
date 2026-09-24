import 'package:app_quanly_giaidau/data/models/social_session_model.dart';

abstract class ISocialSessionRepository {
  /// 4.2 - Danh sách theo ngày (GET /social-sessions?date=YYYY-MM-DD)
  Future<SocialSessionListResponse> listByDate({
    required String date,
    String? sport,
    String? communityId,
    String? search,
    int page = 1,
    int limit = 20,
  });

  /// 4.3 - Chi tiết (GET /social-sessions/:id)
  Future<SocialSessionModel> getDetail(String sessionId);

  /// 4.1 - Tạo kèo (POST /social-sessions)
  Future<SocialSessionModel> create(CreateSocialSessionRequest request);

  /// 4.2b - Danh sách theo CLB (GET /social-sessions/by-community/:communityId)
  /// Backend: QuerySocialByCommunityDto { status, from, to, sport, search, page, limit }
  Future<SocialSessionListResponse> listByCommunity({
    required String communityId,
    String? status,
    String? sport,
    String? search,
    String? from,
    String? to,
    int page = 1,
    int limit = 20,
  });

  /// 4.6 - Sửa kèo (PATCH /social-sessions/:id)
  Future<SocialSessionModel> update(String sessionId, Map<String, dynamic> fields);

  /// 4.8 - Hủy kèo (PATCH /social-sessions/:id/cancel)
  Future<void> cancel(String sessionId);

  /// 4.8b - Xóa kèo vĩnh viễn (DELETE /social-sessions/:id)
  Future<void> delete(String sessionId);

  /// 4.9 - Lấy tin nhắn chat (GET /social-sessions/:id/messages)
  Future<List<SocialChatMessageModel>> getMessages(
    String sessionId, {
    int page = 1,
    int limit = 50,
  });

  /// 4.4 - Member tự join (POST /social-sessions/:id/join)
  Future<JoinSessionResponse> join(String sessionId, {int ticketCount = 1});

  /// 4.5 - Admin thêm người (POST /social-sessions/:id/participants)
  Future<void> addParticipant(
    String sessionId, {
    required String userId,
    int ticketCount = 1,
  });

  /// Thêm khách ngoài CLB (POST /social-sessions/:id/participants với guestName).
  /// Không cần tài khoản, không tạo user mới, chỉ đánh dấu slot đã có người.
  Future<void> addGuestParticipant(
    String sessionId, {
    required String guestName,
    int ticketCount = 1,
  });

  /// Thêm hàng loạt thành viên CLB (POST /social-sessions/:id/participants/batch).
  Future<BatchAddParticipantsResponse> addParticipantsBatch(
    String sessionId, {
    required List<String> userIds,
    int ticketCount = 1,
  });

  /// 4.8 - Xóa người khỏi kèo (DELETE /social-sessions/:id/participants/:userId)
  Future<void> removeParticipant(String sessionId, String userId);

  /// 4.7 - Cập nhật thu tiền (PATCH /social-sessions/:id/participants/:userId/payment)
  Future<void> updatePaymentStatus(
    String sessionId,
    String userId, {
    required String paymentStatus,
  });
}
