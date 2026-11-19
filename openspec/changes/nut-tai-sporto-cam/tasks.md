## 1. Widget tải app và chữ

- [x] 1.1 Viết `sportoCamStoresFor`, `sportoCamStoreUrls` và widget `SportoCamDownload`, thêm 3 chuỗi vi/en và sinh lại l10n. Tiêu chí: `flutter test --no-pub test/features/sporto_cam_download_test.dart` → exit 0
  - Files: tạo `lib/features/tournament/widgets/sporto_cam_download.dart`; sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, 3 file `lib/l10n/app_localizations*.dart` (sinh bằng `flutter gen-l10n`); test `test/features/sporto_cam_download_test.dart`
  - Giao: `List<SportoCamStore> sportoCamStoresFor(TargetPlatform)`; `const SportoCamDownload({Key? key, TargetPlatform? platform, Future<void> Function(Uri) openUrl})` cho 1.2
  - Chủ file chung: 1.1 giữ hai file `.arb`
  - Phụ thuộc: không

## 2. Gắn vào sheet

- [x] 2.1 Chèn `SportoCamDownload` dưới `CameraAddHelp` ở tab push. Tiêu chí: `flutter test --no-pub test/features/sporto_cam_download_test.dart test/features/camera_editor_sheet_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/camera_editor_sheet.dart` (import và nhánh `!_liveSource`)
  - Nhận: `SportoCamDownload` từ 1.1
  - Chủ file chung: 2.1 giữ `camera_editor_sheet.dart`
  - Phụ thuộc: sau 1.1

## 3. Kiểm tra cuối

- [x] 3.1 Phân tích tĩnh các file đã đổi. Tiêu chí: `dart analyze` trên 3 file Dart đã đổi → exit 0; `flutter analyze` toàn bộ chạy trên cloud khi gộp
  - Phụ thuộc: sau 2.1
