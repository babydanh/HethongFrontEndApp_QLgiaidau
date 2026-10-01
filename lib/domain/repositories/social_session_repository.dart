import 'package:app_quanly_giaidau/data/models/social_session_model.dart';

abstract class ISocialSessionRepository {
  /// 4.2 - Danh sách theo ngày (GET /social-sessions?date=YYYY-MM-DD)
  ///
  /// [date] bỏ trống được **chỉ khi** có [search]: backend nới `date` đúng
  /// trường hợp đó. Bỏ trống mà không có [search] sẽ bị backend từ chối 400.
  /// [lat]/[lng]: vị trí user — bật lọc bán kính + sort DISTANCE (gần lên trước).
  /// [radiusKm]: bán kính lọc (km, backend 0.5–50). [sortBy]: 'TIME' | 'DISTANCE'.
  Future<SocialSessionListResponse> listByDate({
    String? date,
    String? sport,
    String? communityId,
    String? search,
    int page = 1,
    int limit = 20,
    double? lat,
    double? lng,
    double? radiusKm,
    String? sortBy,
  });

  /// Danh sách kèo gần bạn (GET /socials/nearby?lat=...&lng=...&radius=...&limit=...&cursor=...)
  /// [lat]/[lng]: tọa độ user (bắt buộc).
  /// [radius]: bán kính lọc bằng mét (100–50000, mặc định 10000).
  /// [limit]: số lượng mỗi trang (1–50, mặc định 20).
  /// [cursor]: chuỗi con trỏ trang kế tiếp từ nextCursor (bỏ trống trang đầu).
  Future<NearbySocialSessionsResponse> listNearby({
    required double lat,
    required double lng,
    int? radius,
    int limit = 20,
    String? cursor,
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
    double? lat,
    double? lng,
    double? radiusKm,
    String? sortBy,
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
