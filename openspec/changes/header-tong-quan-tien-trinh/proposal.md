## Why
Trang quản lý giải trên App chưa giống Web: đầu trang chỉ có tên giải và khung 4 ô số, còn thanh tiến trình và nút bước tiếp theo nằm tận tab Cài đặt. Người dùng đã duyệt bản vẽ Lavish "Phương án A" (`~/.lavish/app-header-tong-quan.html`): logo giải đè lên banner, thanh tiến trình 4 bước đúng Web ngay đầu trang, bỏ khung 4 ô số vì phần bên dưới đã có đủ, lệ phí nằm trong danh sách Tổng quan.

## What Changes
- Logo giải (hình tròn) đè lên mép dưới banner; tên giải và chip trạng thái giữ nguyên ở dưới.
- Bỏ hẳn khung 4 ô số (ngày thi đấu, VĐV, lệ phí, hạn ĐK) ở đầu trang.
- Thanh tiến trình đổi sang 4 bước như Web (Đăng ký, Lịch thi đấu, Đang thi đấu, Kết thúc), vòng tròn nối nhau; nút hành động của bước nằm ngay dưới thanh, dời từ tab Cài đặt lên đầu trang.
- Tab Cài đặt chỉ còn nhóm "Khác" (Chia sẻ, Xoá giải).
- Dòng "Lệ phí giải" hiện ở tab Tổng quan (trước đây bị ẩn khi `compact`), bấm mở mục Tài chính như cũ.

## Out of scope
- Công tắc Thu phí/Miễn phí (Web không có), dòng phí sàn, thay đổi Backend/API.
- Giải câu lạc bộ rút gọn (`isClubLite`) vẫn không có banner nên không có logo.

## Capabilities

### New Capabilities
- `tournament-header-progress`: đầu trang quản lý giải có logo, thanh tiến trình 4 bước và nút bước tiếp theo.

### Modified Capabilities
- (không)

## Impact
- `lib/features/tournament/widgets/tournament_management_header.dart`, `lifecycle_stepper.dart`, `overview_tab.dart`
- `lib/features/tournament/screens/tournament_management_hub_screen.dart`, `tournament_management_section_screen.dart`
- `lib/l10n/app_vi.arb`, `app_en.arb` (+ file sinh)
- Test: `lifecycle_stepper_test.dart`, `tournament_management_hub_screen_test.dart`, `integration_test/organizer_flow_test.dart`
