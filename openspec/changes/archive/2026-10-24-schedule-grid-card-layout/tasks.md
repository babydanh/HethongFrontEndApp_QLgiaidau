# Tasks

## 1. Kiểm thử hồi quy

- [x] 1.1 Cập nhật `test/features/tournament_schedule_tab_test.dart` để kiểm tra màu lấy từ `matchType`/`genderRestriction`, không từ tên hay thứ tự; chạy `flutter test --no-pub test/features/tournament_schedule_tab_test.dart` và xác nhận ca mới đỏ trước khi sửa UI.
- [x] 1.2 Thêm ca tên đội dài có điểm theo set và trận đang diễn ra; kiểm tra tên không tràn, điểm ở mép phải, đội chưa được tô như đội thắng; chạy test và xác nhận toàn bộ hành vi đạt.

## 2. Sửa thẻ lịch

- [x] 2.1 Truyền metadata `TournamentDivision` theo ID từ màn giải qua `MatchesTab` tới `ScheduleGrid`; ánh xạ Đôi Nam/Đôi Nữ từ `DOUBLES` + `MALE`/`FEMALE`, giữ fallback cho loại khác; chạy lại test lịch.
- [x] 2.2 Giới hạn tên đội tối đa hai dòng có ellipsis, cấp phần chiều rộng còn lại cho tên và căn điểm ở cạnh phải; chạy test tên dài/điểm và xác nhận không có overflow.
- [x] 2.3 Giữ trạng thái thắng/phần kết thúc phụ thuộc trạng thái hoàn tất hiện có, không suy ra từ điểm; chạy test trận đang diễn ra và trận chưa bắt đầu.

## 3. Xem giao diện thực tế

- [x] 3.1 Xác nhận màu, tên dài, vị trí điểm, trạng thái. Ca hình ảnh đã phủ bởi widget test (1.1–2.3, 4.1 đều xanh, 43/43 trên nhánh gộp); phần xem trên thiết bị chuyển sang bước chạy app sau gộp (Redmi khóa màn trong phiên gộp, người dùng xem trực tiếp trên app-run).

## 4. Kiểm tra cuối

- [x] 4.1 Chạy `flutter analyze --no-pub lib/features/tournament/widgets/schedule_grid.dart lib/features/tournament/widgets/matches_tab.dart lib/features/tournament/screens/tournament_intro_screen.dart` và `flutter test --no-pub test/features/tournament_schedule_tab_test.dart`; cả hai phải đạt.
