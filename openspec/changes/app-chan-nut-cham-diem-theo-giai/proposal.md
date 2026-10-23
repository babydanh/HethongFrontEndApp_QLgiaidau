## Why

Màn "Chi Tiết Trận Đấu" của App có hai lỗi người dùng thấy trên máy thật:

1. Nút chấm điểm (AppBar: "Bắt đầu trận" / bảng điểm) hiện cho mọi tài khoản ADMIN ở mọi giải, vì cổng quyền dùng `auth.canScore` (vai trò toàn cục ADMIN/REFEREE/ORGANIZER) mà không xét giải hay trận. Web đã chuẩn hoá (`canControlTournamentLive`): ADMIN chỉ thấy nút khi là người tạo giải hoặc trọng tài được gán đúng trận.
2. Khung video khi trận chưa có luồng phát (`_NoSignalBox`) chỉ cao bằng nội dung (icon + một dòng chữ, ~70dp) thay vì khung 16:9, nên bảng điểm, nhãn camera, chip H2H/Sơ đồ chồng lên nhau và chữ "Chưa có tín hiệu phát trực tiếp" bị cắt.

## What Changes

- Thêm hàm thuần `canControlTournamentLive` (cùng quy tắc Web) và provider đọc `GET /matches/:id/score-access` (không sửa Backend).
- `live_score_screen.dart`: nút chấm điểm và tiêu đề "bàn trọng tài" dùng cổng mới thay cho `auth.canScore`; giữ nhánh Super Lite (người đăng nhập chấm được).
- `LiveVideoBox`: `_NoSignalBox` có tỉ lệ 16:9 như `LiveVideoPlayer`.

## Out of scope

- Backend `score-access` và `matches.service.ts`.
- `official_score_modal.dart`, `pickleball_court_panel.dart` (chỉ mở được từ nút AppBar đã được chặn).
- Trận CLB (`canEditScore`), màn tạo/quản lý giải.

## Capabilities

### New Capabilities
- `live-score-access`: ai thấy nút chấm điểm trên màn chi tiết trận.

### Modified Capabilities
- `live-score-video-panel`: khung "chưa có tín hiệu" giữ tỉ lệ 16:9.

## Impact

- App: `lib/domain/services/live_control_access.dart` (mới), `lib/providers/match_score_access_provider.dart` (mới), `lib/features/match/screens/live_score_screen.dart`, `lib/features/match/widgets/live_video_box.dart`; test mới tương ứng.
- Thêm một lời gọi GET nhẹ cho người đăng nhập không phải ADMIN/chủ giải/trọng tài trận khi mở màn trận.
