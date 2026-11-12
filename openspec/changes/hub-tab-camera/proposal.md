## Why

Chủ giải mở Quản lý giải trên App nhưng không thấy nút Bắt đầu/Dừng phát live của trận. Nút đã có trong `TournamentManagementCameraSection` (tab Camera của màn Vận hành), nhưng màn Quản lý nhúng màn Vận hành ở chế độ khoá "Trận" (`view: OrganizerOpsView.matches`) nên thanh tab bị ẩn; mục Livestream trong Cài đặt không có nút này. Chủ repo chọn phương án B: thêm tab Camera riêng vào thanh tab Quản lý.

## What Changes

- Thanh tab Quản lý giải có thêm tab "Camera" (key i18n có sẵn `opsCamera`), nằm ngay trước "Cài đặt".
- Tab Camera hiện `TournamentManagementCameraSection` (gán trận vào sân, camera theo sân, nút Bắt đầu/Dừng/MP4) cho nội dung đang chọn ở hub.
- Giải COMPLETED/CANCELLED/CANCELED/ARCHIVED/PENDING_DELETE mở tab ở chế độ chỉ-đọc, cùng luật với màn Vận hành (đưa hàm luật ra dùng chung `isReadOnlyTournamentStatus`).
- Nội dung tab chỉ dựng khi tab Camera đang được chọn, để lướt qua tab (vd mở Cài đặt) không gọi API camera/sân.

## Out of scope

- Không đổi Backend, Web; không thêm endpoint hay field.
- Không đổi mục Livestream trong Cài đặt, không đổi màn Vận hành mở riêng.
- Không đổi luật quyền: Backend vẫn là chốt (403 hiện lỗi như hiện tại).

## Capabilities

### New Capabilities
- `tournament-hub-camera-tab`: tab Camera trong màn Quản lý giải của App.

### Modified Capabilities
(không có)

## Impact

- App: `lib/features/tournament/screens/tournament_management_hub_screen.dart`, `lib/features/organizer_ops/screens/organizer_ops_screen.dart` (hàm luật chỉ-đọc dùng chung).
- Test: `test/features/tournament/management_camera_tab_test.dart` (mới), cập nhật số tab ở `test/features/tournament/management_results_tab_test.dart` và `test/features/tournament_management_hub_screen_test.dart`.
- Backend/Web: không ảnh hưởng.
