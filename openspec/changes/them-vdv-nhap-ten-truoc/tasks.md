## 1. Popup

- [x] 1.1 Mở ở tab Nhập tên, đặt chip lên trước, ô nhập đồng đều. Tiêu chí: `flutter test --no-pub test/organizer_ops/add_athlete_entry_test.dart test/features/tournament_management_hub_screen_test.dart` → exit 0
  - Files: sửa `lib/features/organizer_ops/screens/add_athlete_sheet.dart`; test `test/organizer_ops/add_athlete_entry_test.dart`
  - Chủ file chung: 1.1 giữ `add_athlete_sheet.dart`
  - Phụ thuộc: (không)

## 2. Kiểm tra cuối

- [x] 2.1 Analyze và xem popup trên máy thật (chỉ xem). Tiêu chí: `flutter analyze --no-pub lib/features/organizer_ops/screens/add_athlete_sheet.dart` → exit 0
  - Phụ thuộc: 1.1
  - Ghi chú: analyze exit 0 và 29+57 test xanh; chưa xem trên máy thật vì app-run chưa gom nhánh này, người dùng yêu cầu gộp lên main trước.
