## Why
Tab Tổng quan của hub quản lý thiếu mốc "Kết thúc giải", banner không có nút ẩn/hiện chữ, con mắt Ban tổ chức không có tác dụng khi giải ở chế độ liên hệ nhập tay, và mỗi popup sửa là một bố cục khác nhau (cao cố định, chừa trống, phải cuộn).

## What Changes
- Lộ trình giải đấu thêm dòng "Kết thúc giải" sửa được bằng cùng bộ chọn ngày giờ như "Hạn chót đăng ký".
- Banner quản lý có nút con mắt bật/tắt `hideFeaturedCardText`, lưu ngay.
- Con mắt Ban tổ chức: khi hiện lại mà giải đang MANUAL thì chuyển `displayMode` về PROFILE cùng lúc.
- Một khung popup chung `TournamentEditSheet` (tiêu đề, nút đóng, thân co theo nội dung, thanh Lưu dính đáy) cho mọi popup sửa ở Tổng quan.

## Out of scope
Backend, màn hình Cài đặt đầy đủ, nội dung bên trong form lệ phí/địa điểm.

## Capabilities
### New Capabilities
- `overview-edit`: sửa nhanh từng mục ở tab Tổng quan bằng popup thống nhất.

### Modified Capabilities
(không)

## Impact
`overview_tab.dart`, `tournament_management_header.dart`, `tournament_management_hub_screen.dart`, `tournament_management_section_screen.dart`, `tournament_edit_popup.dart`, `tournament_contact.dart`; test tương ứng.
