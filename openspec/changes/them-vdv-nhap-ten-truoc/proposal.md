## Why

Popup "Thêm VĐV" mở ra tab tìm bạn bè/CLB trước, trong khi người tổ chức thường nhập tên tay. Các ô trên tab "Nhập tên" cũng lệch nhau (ô có bộ đếm, ô có dòng gợi ý, ô Điểm hẹp và thấp hơn ô khác).

## What Changes

- Popup mở ở tab "Nhập tên"; chip "Nhập tên" nằm trước "Bạn bè & CLB". Giải bóng đá (không có tab nhập tên) giữ tab tài khoản.
- Danh sách bạn bè/CLB chỉ tải khi mở tab "Bạn bè & CLB".
- Các ô nhập tay cùng chiều cao tối thiểu, bỏ bộ đếm ký tự và dòng gợi ý email; hàng Điểm chia hai nửa bằng nhau, Loại điểm là ô chọn ELO/DUPR cùng kiểu.

## Out of scope

- Logic gửi, hàng chờ, Backend.

## Capabilities

### New Capabilities
- `add-athlete-entry-layout`: tab mặc định và bố cục đồng đều của form nhập tay.

### Modified Capabilities
(không)

## Impact

- `lib/features/organizer_ops/screens/add_athlete_sheet.dart`
- `test/organizer_ops/add_athlete_entry_test.dart`
