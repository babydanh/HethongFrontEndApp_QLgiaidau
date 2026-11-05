## Why

Các màn tab Hồ sơ (Hồ sơ, Cài đặt, Sửa hồ sơ, Đổi mật khẩu, Báo cáo, Lịch sử ELO, Thông báo, Dashboard) dùng giao diện cũ (Card, nhiều chữ, icon xám) khác hẳn các trang quản lý giải đấu đã làm theo bộ Lavish. Audit đối chiếu Backend còn thấy nhiều chức năng gọi sai route nên hỏng thật: đổi mật khẩu, gửi báo cáo, chấp nhận/từ chối/hủy kết bạn; thông báo quản lý bị mất; ELO hiển thị sai và nuốt lỗi; sửa hồ sơ gửi SĐT sai định dạng; đăng xuất không thu hồi phiên.

## What Changes

- Thêm vào bộ Lavish các widget chung còn thiếu: khung màn, ô nhập, thanh lưu dính đáy, ô số liệu, trạng thái rỗng/lỗi/skeleton dùng chung.
- Vẽ lại 8 màn Hồ sơ theo khuôn Lavish (ít chữ, hàng phẳng, icon trong ô màu, pill trạng thái), có loading, rỗng, lỗi và thử lại.
- Sửa logic gọi API cho khớp Backend (xem spec).
- Không đổi Backend, không thêm tính năng mới ngoài danh sách dưới.

## Out of scope

- Màn BTC / Admin, đăng nhập Facebook (Backend chưa có route), tính năng gửi kết bạn mới, bộ lọc nâng cao của báo cáo, rút yêu cầu xác minh organizer.
- Đổi tên route hay cấu trúc router (chỉ sửa tham số `currentElo` của route ELO).

## Capabilities

### New Capabilities
- `profile-lavish-ui`: giao diện khuôn Lavish và hợp đồng API của các màn tab Hồ sơ.

### Modified Capabilities
(không)

## Impact

- `lib/features/tournament/widgets/lavish_kit*.dart`, `lib/features/profile/**`, `lib/features/reports/**`, `lib/features/notification/**`, `lib/features/dashboard/**`, `lib/features/rankings/screens/elo_history_screen.dart`, `lib/shared/widgets/report_sheet.dart`, `lib/providers/ranking_provider.dart`, `lib/core/router/app_router.dart` (chỉ dòng ELO), `lib/l10n/*.arb`.
- Không đổi API Backend.
