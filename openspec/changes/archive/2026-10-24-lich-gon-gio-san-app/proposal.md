## Why

Web đã làm lịch gọn (change `lich-gon-gio-san`, commit 999cad85). Lưới lịch trên App còn cao (ô 15 phút 144dp), tên sân ghi dài "Sân N" ở tiêu đề cột, thẻ trận chỉ có giờ trơn, chưa phân biệt được sân bằng màu. App cần cùng cách đọc với Web.

## What Changes

- Header thẻ trận (`_fullHeader`) gộp "🕐 giờ / chip sân" một dòng; nhãn hạng mục vẫn nằm bên phải.
- Tên sân hiển thị rút gọn "Sân 1" thành "1" (chỉ hiển thị; khoá/tên lưu không đổi). Tên đầy đủ nằm ở tooltip/semantics.
- Chip sân tô màu theo CHỈ SỐ sân, 8 tông ổn định (vòng lại khi nhiều hơn 8 sân), bỏ tông đỏ/hồng/tím vì trùng nghĩa LIVE/nháp. Tiêu đề cột sân dùng cùng chip để nối màu cột với thẻ.
- Thu nhỏ thang giờ: `ScheduleGrid.slotHeight` mặc định 144 thành 112, lưới công khai 120 thành 112, giới hạn kéo giãn 96..288 thành 80..224. 112 là mức nhỏ nhất vẫn chứa trọn thẻ trận đôi 15 phút (108dp) mà không bị đẩy sang lane thứ hai.
- Helper mới `schedule_court_label.dart` (tên sân ngắn + màu chip) có test.

## Out of scope

- Web (đã xong ở change riêng), Backend, schema, API.
- Không thêm khoá i18n, không đổi màu trạng thái của thẻ.
- Không thu nhỏ avatar/khối đội (thuộc `core/participants`), nên không đạt 30% như Web.

## Capabilities

### New Capabilities
- `schedule-card-compact-app`: thẻ trận lịch App gọn, giờ/sân một cụm, màu chip theo sân.

### Modified Capabilities
(không)

## Impact

- App: `lib/features/tournament/widgets/schedule_grid.dart`, `matches_tab.dart`, `tournament_schedule_court_grid.dart`, mới `lib/features/tournament/utils/schedule_court_label.dart`.
- Test: mới `test/features/schedule_court_label_test.dart`; sửa `schedule_grid_zoom_test.dart`, `tournament_schedule_tab_test.dart`, `hub_schedule_court_grid_test.dart`, `ops_matches_view_toggle_test.dart` (số 144/120 và chữ "Sân N" ở tiêu đề cột).
- Giao diện lệch pixel với Web chấp nhận được: App là lưới cột theo sân, Web là hàng theo sân.
