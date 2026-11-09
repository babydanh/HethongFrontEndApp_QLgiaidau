# Tasks

## 1. Repository và dialog (hợp đồng)

- [x] 1.1 Thêm gọi API theo `socialSessionId`; `createStandaloneMatch` nhận `communityId` hoặc `socialSessionId`. Tiêu chí: `dart analyze lib/data/repositories/api/api_club_match_session_repository.dart` → 0 lỗi.
  - Files: sửa `lib/data/repositories/api/api_club_match_session_repository.dart:185-235` (thêm `standaloneMatchesBySocialSession(String socialSessionId)` với query `{'socialSessionId': id}`; `createStandaloneMatch({String? communityId, String? socialSessionId, ...})` có `assert((communityId == null) != (socialSessionId == null))`, body chỉ chứa khoá được truyền)
  - Giao: `Future<List<ClubSessionMatchModel>> standaloneMatchesBySocialSession(String socialSessionId)`; `createStandaloneMatch({String? communityId, String? socialSessionId, required List<String> sideA, required List<String> sideB, required String key, required bool isRanked, String? matchType})` cho 1.2, 2.1 · Nhận: (không)
  - Chủ file chung: 1.1 giữ file repository
  - Phụ thuộc: (không, task gốc)
- [x] 1.2 `ClubStandaloneMatchDialog` nhận `socialSessionId`, `communityId` nullable; không gọi `getMembers` khi không có `communityId`. Tiêu chí: `dart analyze lib/features/community/widgets/club_standalone_match_dialog.dart` → 0 lỗi.
  - Files: sửa `lib/features/community/widgets/club_standalone_match_dialog.dart:15-55,99-131,163-170`
  - Giao: `ClubStandaloneMatchDialog.show(context, {String? communityId, String? socialSessionId, List<CommunityMemberModel>? preselectedMembers, ...})` cho 2.1 · Nhận: `createStandaloneMatch` từ 1.1
  - Chủ file chung: 1.2 giữ `club_standalone_match_dialog.dart`
  - Phụ thuộc: sau 1.1

## 2. Tab Trận đấu

- [x] 2.1 `SocialMatchTab` hỗ trợ buổi cá nhân (TDD: thêm test đỏ trước). Tiêu chí: `flutter test --no-pub test/features/social/social_match_tab_test.dart` → exit 0.
  - Files: sửa `lib/features/social/widgets/match_tab/social_match_tab.dart:25-142,198-249` (thêm `sessionId`, `isHost`, `communityId` nullable; nhánh cá nhân theo design.md); sửa `test/features/social/social_match_tab_test.dart` (fake repo thêm `standaloneMatchesBySocialSession`; thêm ca: gọi theo session, nút bật cho host, tắt cho người khác, không gọi `getMembers`)
  - Giao: `SocialMatchTab({required String sessionId, required bool isHost, String? communityId, required List<SocialParticipantModel> approvedParticipants})` cho 2.2 · Nhận: 1.1, 1.2
  - Chủ file chung: 2.1 giữ `social_match_tab.dart` và test của nó
  - Phụ thuộc: sau 1.1, 1.2
- [x] 2.2 Luôn hiện tab Trận đấu ở màn chi tiết. Tiêu chí: `dart analyze lib/features/social` → 0 lỗi mới và test ở 2.1 → exit 0.
  - Files: sửa `lib/features/social/screens/social_detail_screen.dart:234-235,294-302,363-367` (bỏ điều kiện `showMatchTab`; truyền `sessionId: session.id`, `isHost: host`, `communityId: session.communityId`)
  - Giao: (không) · Nhận: `SocialMatchTab` từ 2.1
  - Chủ file chung: 2.2 giữ `social_detail_screen.dart`
  - Phụ thuộc: sau 2.1

## 3. Kiểm chứng cuối

- [ ] 3.1 Chạy test hẹp + analyze; xem App trên máy thật (`app-run.py`) với một buổi cá nhân: tab hiện, host tạo được trận. Tiêu chí: lệnh ở 2.1, 2.2 → exit 0; `app-run.py status` không có `errors` của nhánh này.
  - Files: toàn bộ file ở 1.1–2.2
  - Giao: xác nhận sẵn sàng gộp · Nhận: 1.1–2.2
  - Chủ file chung: 3.1 chỉ tổng hợp kiểm chứng
  - Phụ thuộc: sau 2.2
