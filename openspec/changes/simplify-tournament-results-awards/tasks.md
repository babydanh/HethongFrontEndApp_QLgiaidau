# Tasks

## 1. Kiểm thử hành vi kết quả

- [x] 1.1 Tạo kiểm thử widget cho kết quả hạng mục đơn/đôi được chọn, xác nhận tên đội và tên thành viên đúng, không có bục, và trạng thái rỗng không có thẻ giải; chạy `flutter test --no-pub test/features/tournament/results_tab_test.dart` để thấy các hành vi mới chưa đạt trước khi sửa giao diện.
- [x] 1.2 Mở rộng kiểm thử avatar: ảnh có URL, fallback chữ cái đầu khi thiếu hoặc lỗi ảnh, avatar một người cho đơn và hai thành viên cho đôi; chạy lại `flutter test --no-pub test/features/tournament/results_tab_test.dart`.

## 2. Triển khai hiển thị kết quả

- [x] 2.1 Truyền `matchType` từ hạng mục đang chọn vào `ResultsTab`, dùng `SINGLES`, `DOUBLES` hoặc `MIXED_DOUBLES` để hiển thị thành viên; giữ bộ chọn và truy vấn theo ID hiện có, xác nhận kiểm thử widget hạng mục đơn/đôi đạt.
- [x] 2.2 Bỏ bục vinh danh; sửa thẻ để hiện tên đội, tên thành viên và avatar theo wireframe, giảm màu/đổ bóng/viền; xác nhận kiểm thử widget kiểm tra không có bục, danh sách và trạng thái rỗng đạt.

## 3. Kiểm tra tích hợp

- [x] 3.1 Chạy `flutter analyze --no-pub lib/features/tournament` và `flutter test --no-pub test/features/tournament/results_tab_test.dart`; ghi nhận 20 thông tin lint tại tệp không sửa, xác nhận phân tích riêng hai tệp Dart đã sửa không lỗi, rồi chạy `openspec validate simplify-tournament-results-awards --strict`.
