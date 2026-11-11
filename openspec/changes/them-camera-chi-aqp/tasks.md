## 1. Hộp Thêm camera chỉ AQP

- [x] 1.1 Tạo `CameraAddHelp` (nút "?" và khung hướng dẫn có hoạt hình). Tiêu chí: `flutter test --no-pub test/features/camera_editor_sheet_test.dart` → exit 0 (TC-CAM-AQP-APP-02, 02b, 03)
  - Files: tạo `lib/features/tournament/widgets/camera_add_help.dart`
  - Giao: `CameraAddHelp()` widget không tham số · Nhận: không
  - Chủ file chung: không
  - Phụ thuộc: không

- [x] 1.2 Bỏ PUSH/PULL và URL khỏi hộp, luôn gửi `PUSH`, gắn "?" ở đầu hộp, cập nhật chuỗi vi/en. Tiêu chí: `flutter test --no-pub test/features/camera_editor_sheet_test.dart test/features/tournament_camera_panel_test.dart` → exit 0 (TC-CAM-AQP-APP-01)
  - Files: sửa `lib/features/tournament/widgets/camera_editor_sheet.dart`, `lib/features/tournament/widgets/tournament_camera_panel.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/camera_editor_sheet_test.dart`
  - Giao: không · Nhận: `CameraAddHelp()` từ 1.1
  - Chủ file chung: 1.2 giữ `lib/l10n/*.arb` và file sinh `app_localizations*.dart`
  - Phụ thuộc: sau 1.1

## 2. Kiểm tra cuối

- [x] 2.1 Phân tích tĩnh thư mục đã sửa. Tiêu chí: `flutter analyze --no-pub lib/features/tournament/widgets lib/l10n` → exit 0
  - Files: không sửa file
  - Giao: không · Nhận: không
  - Chủ file chung: không
  - Phụ thuộc: sau 1.2
