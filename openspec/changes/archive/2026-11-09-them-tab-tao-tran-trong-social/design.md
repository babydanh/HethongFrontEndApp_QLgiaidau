# Design

## Context

`social_detail_screen.dart` dựng tab bằng `TabController` dựa theo `session.communityId` khác rỗng để thêm tab Thanh toán; tab Trận đấu dùng chung cơ chế gate này.

Logic tạo trận bắt cặp thủ công đã có sẵn và chạy tốt trong CLB: `club_activity_tab.dart` mở `ClubStandaloneMatchDialog` (chạm avatar gán Đội A/Đội B, `_cycleMemberTeam`/`_canSubmit` chỉ cho xác nhận khi đủ người mỗi bên), gọi `api_club_match_session_repository.dart` → `POST /club-match-sessions/standalone-matches`; nhập kết quả qua `ClubStandaloneMatchResultDialog` → `.../matches/:matchId/complete`. Dialog hiện nhận danh sách toàn bộ thành viên CLB để chọn; cần điều chỉnh để nhận trước một danh sách người (participants đã duyệt của buổi Social) thay vì tự load toàn bộ CLB.

Lưu ý dead-code đã phát hiện khi audit: tham số `sessionId` truyền vào `_handleCreateMatch` của `club_activity_tab.dart` hiện bị bỏ qua (không gắn vào request tạo trận) — giữ nguyên hành vi Backend (API không có field liên kết social-session), không cố gắng "sửa" chỗ này vì đó là hành vi đã biết của 2 module độc lập, không phải lỗi cần fix trong change này.

## Goals / Non-Goals

**Goals:**
- Cho phép tạo trận bắt cặp thủ công ngay trong tab mới của buổi Social đã gắn CLB, dùng đúng API/dialog CLB đã có.
- Danh sách người để chọn mặc định đúng người tham gia đã duyệt của buổi, không phải toàn bộ CLB.

**Non-Goals:**
- Không đổi Backend, không đổi Web (change song song riêng).
- Không ghép cặp tự động.
- Không đồng bộ 2 chiều giữa buổi Social và trận đã tạo.

## Decisions

- **Tái dùng `ClubStandaloneMatchDialog`/`ClubStandaloneMatchResultDialog` nguyên trạng**, chỉ thêm tham số đầu vào tùy chọn (danh sách người chọn trước) thay vì viết dialog mới — giữ đúng 1 chỗ sửa lỗi/logic ghép đội, tránh phân kỳ hành vi giữa CLB và Social.
- **Gate tab theo `communityId`** (đã chốt phương án A ở Lavish plan trước đó, khớp với quyết định bên Web): không nới điều kiện Backend.
- **Widget mới đặt tại `lib/features/social/widgets/match_tab/`**: tách khỏi `social_detail_screen.dart` để file chính không phình to, theo đúng tổ chức file hiện có của App (tách theo `features/<domain>/widgets/`).
- **Danh sách trận lọc theo `communityId`**: dùng lại repository `api_club_match_session_repository.dart` hiện có (không có field liên kết `socialSessionId` ở Backend), chấp nhận trận hiển thị trong tab là mọi trận standalone của CLB đó, không riêng buổi này — ghi chú rõ giới hạn này trong UI (ví dụ dòng phụ "trận của CLB" thay vì ngụ ý "trận của buổi này").

## Risks / Trade-offs

- [Rủi ro] Danh sách trận hiển thị trong tab là theo `communityId`, không lọc được chính xác theo buổi Social (Backend không có liên kết) → Chấp nhận, ghi chú rõ trong UI; đây là giới hạn đã biết của thiết kế, không phải lỗi.
- [Rủi ro] Sửa dialog CLB để nhận danh sách người chọn trước có thể ảnh hưởng luồng gọi cũ từ `club_activity_tab.dart` → Dùng tham số tùy chọn (mặc định `null` = hành vi cũ tự load toàn bộ CLB), không đổi chữ ký bắt buộc.

## Open Questions

(không còn — phương án A đã chốt trước khi viết spec/tasks này, đồng nhất với change Web song song)
