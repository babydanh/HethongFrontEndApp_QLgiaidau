## Context

`SocialMatchTab` hiện nhận `communityId` bắt buộc, gọi `standaloneMatches(communityId)` và dùng `ClubStandaloneMatchDialog` (ghép 2v2, `isRanked=false`) với danh sách người chơi lọc theo thành viên CLB JOINED. Backend `POST/GET /club-match-sessions/standalone-matches` nay nhận đúng một trong `communityId` hoặc `socialSessionId`; buổi cá nhân chỉ host (hoặc admin) được tạo/sửa/xoá và mọi người chơi phải là participant JOINED của buổi.

## Decisions

- Giữ nguyên chữ ký `standaloneMatches(String communityId)`; thêm `standaloneMatchesBySocialSession(String socialSessionId)` để không phá test và caller cũ.
- `createStandaloneMatch`: `communityId` và `socialSessionId` đều nullable, `assert` đúng một giá trị được truyền.
- `ClubStandaloneMatchDialog`: thêm `socialSessionId`, `communityId` thành nullable; khi không có `communityId` thì bắt buộc có `preselectedMembers` (không gọi `getMembers`).
- `SocialMatchTab`: nhận `sessionId`, `communityId?`, `isHost`. Nhánh cá nhân: bỏ `_fetchClubMemberIds` và `myCommunityMembershipProvider`; `_canCreateMatch = isHost`; người chọn = participant đã duyệt có `userId`, không phải khách.
- Bỏ dòng ghi chú "trận của cả CLB" ở nhánh cá nhân (không thêm chuỗi l10n mới).

## Risks

- Backend từ chối `403 FORBIDDEN_NOT_HOST` nếu App hiện nút nhầm: App chỉ ẩn nút theo `session.isHost`, Backend là chốt cuối.
- Buổi có dưới 4 người đã duyệt: giữ cảnh báo `social_matchNotEnoughParticipants` hiện có.
