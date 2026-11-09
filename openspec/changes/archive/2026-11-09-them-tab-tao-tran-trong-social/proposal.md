# Proposal

## Why

App đã có sẵn logic "tạo trận đấu riêng" trong CLB (`ClubStandaloneMatchDialog`, ghép Đội A/Đội B thủ công, gọi `POST /club-match-sessions/standalone-matches`) nhưng chỉ mở được từ tab Hoạt động CLB. Màn chi tiết buổi Social (`social_detail_screen.dart`) hiện chỉ có 4 tab Chi tiết/Người tham gia/[Thanh toán]/Trò chuyện, không có cách tạo trận đấu bắt cặp ngay trong một buổi giao lưu đã gắn CLB — người dùng phải thoát ra CLB để tạo trận rồi tự nhớ liên hệ lại buổi Social, trải nghiệm rời rạc.

## What Changes

- Thêm 1 tab mới "Trận đấu" vào `social_detail_screen.dart`, chỉ hiển thị khi buổi Social có `communityId` khác rỗng.
- Tab mới liệt kê các trận đã tạo cho buổi (qua `communityId`, lọc theo thời điểm buổi diễn ra) và có nút tạo trận mới.
- Tạo trận mới tái dùng đúng logic ghép đội thủ công của `ClubStandaloneMatchDialog` (chạm avatar gán Đội A/Đội B), nhưng danh sách người để chọn mặc định lấy từ người tham gia đã duyệt của buổi Social thay vì toàn bộ thành viên CLB.
- Gọi đúng API đã có sẵn: `POST /club-match-sessions/standalone-matches` (tạo trận) và `POST /club-match-sessions/matches/:matchId/complete` (nhập kết quả) — không gọi API mới.

Không có thay đổi nào ở đây là **BREAKING** — đây là một tab bổ sung, không đổi hành vi tab nào đang có.

### Ngoài phạm vi (out of scope)

- Không sửa Backend — dùng nguyên API `club-match-sessions` đã có.
- Không thêm ghép cặp ngẫu nhiên/tự động.
- Không hiện tab này cho buổi Social không gắn CLB (`communityId` rỗng).
- Không đồng bộ ngược: nếu buổi Social bị hủy sau khi đã tạo trận, trận đã tạo (`club_standalone_matches`) không tự hủy theo — giữ nguyên hành vi độc lập hiện có của 2 module.
- Không sửa Web (`HethongFrontEndWeb_QLgiaidau`) — đó là một OpenSpec change độc lập (`lam-lai-social-web-api-that`) đang chạy song song ở worktree khác.

## Capabilities

### New Capabilities
- `social-match-creation`: tạo và xem trận đấu bắt cặp được tạo bên trong một buổi Social đã gắn CLB, trên App Flutter.

### Modified Capabilities
(không có)

## Impact

- **App**: `lib/features/social/screens/social_detail_screen.dart` (thêm tab), tạo widget mới trong `lib/features/social/widgets/match_tab/`, tái sử dụng `lib/features/community/widgets/club_standalone_match_dialog.dart` và `club_standalone_match_result_dialog.dart` (điều chỉnh để nhận danh sách người chọn trước từ buổi Social), `lib/data/repositories/api/api_club_match_session_repository.dart` (gọi thêm, không sửa chữ ký có sẵn), `lib/l10n/app_vi.arb` + `app_en.arb` (chuỗi mới).
- **Backend** (chỉ tiêu thụ, không sửa): `src/modules/club-match-sessions/club-match-sessions.controller.ts`, `src/modules/club-match-sessions/dto/club-match-session.dto.ts`.
- **Web** (tham chiếu, không sửa trong change này): change song song `lam-lai-social-web-api-that` làm phần tương đương bên Web.
