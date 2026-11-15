## 1. App (một chuỗi, một worktree, làm tuần tự)

- [x] 1.1 Mã lỗi mới và chuỗi i18n. Tiêu chí: `flutter test --no-pub test/features/camera_facebook_live_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/utils/facebook_live_error.dart` (enum thêm `pageNotEligible`, `case 'FACEBOOK_PAGE_NOT_ELIGIBLE'`, nhánh `facebookLiveErrorText`); sửa `lib/l10n/app_vi.arb` và `lib/l10n/app_en.arb` cạnh `tournamentCameraFbCreate`: thêm `tournamentCameraFbCreateCamera`, `tournamentCameraFbCreatingCamera`, `tournamentCameraFbErrorPageNotEligible`, `tournamentCameraFbReadyTitle`, `tournamentCameraFbReadyHint`, `tournamentCameraFbReadyDone`; sinh lại `lib/l10n/app_localizations.dart`, `app_localizations_vi.dart`, `app_localizations_en.dart` bằng `flutter gen-l10n`; test `test/features/camera_facebook_live_test.dart` (TC-FBONE-APP-01: map code mới)
  - Giao: `FacebookLiveError.pageNotEligible` và `String facebookLiveDefaultCameraName(DateTime now)` trả `Live Facebook HH:mm` (đặt trong `facebook_live_error.dart`) cho 1.2 · Nhận: (không)
  - Chủ file chung: 1.1 giữ `app_vi.arb`, `app_en.arb`, các file `app_localizations*.dart`, `facebook_live_error.dart`
  - Phụ thuộc: không

- [x] 1.2 Panel một nút, sheet "Camera đã sẵn sàng" và nối vào luồng tạo camera. Tiêu chí: `flutter test --no-pub test/features/camera_facebook_live_test.dart test/features/camera_facebook_live_larix_test.dart test/features/camera_facebook_one_tap_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/facebook_live_panel.dart` (bỏ khối RTMP/key/Larix sau khi tạo; `onCreated` nhận `CreatedFacebookLive`; nút dùng `tournamentCameraFbCreateCamera`/`tournamentCameraFbCreatingCamera`; giữ cờ `_busy` chặn bấm đúp); tạo `lib/features/tournament/widgets/facebook_live_ready_sheet.dart` (tái dùng `_SecretRow`-kiểu hàng bí mật, `buildLarixSetupUrl`, `qr_flutter`, `launchLink` tiêm được cho test); sửa `lib/features/tournament/widgets/camera_editor_sheet.dart:150-200` (nối `onCreated` vào đường submit với tên dự phòng, `CameraEditorValue` thêm `facebookLive`); sửa `lib/features/tournament/utils/camera_create_flow.dart:21-55` (sau khi lưu xong, nếu giá trị có `facebookLive` thì mở `FacebookLiveReadySheet.show`); cập nhật `test/features/camera_facebook_live_test.dart` và `test/features/camera_facebook_live_larix_test.dart` cho UI mới; tạo `test/features/camera_facebook_one_tap_test.dart` (TC-FBONE-APP-02 tạo thành công tên trống đúng 1 createLive + 1 createCamera PULL, TC-FBONE-APP-03 bấm đúp chỉ 1 camera, TC-FBONE-APP-04 createCamera lỗi thì sheet vẫn mở và có lỗi, TC-FBONE-APP-05 sheet sẵn sàng che khoá phát, có nút Larix gọi `launchLink` đúng link)
  - Giao: `FacebookLivePanel({ ..., required Future<void> Function(CreatedFacebookLive live) onCreated })`; `CameraEditorValue({ ..., CreatedFacebookLive? facebookLive })`; `FacebookLiveReadySheet.show(BuildContext context, { required CreatedFacebookLive live, required String cameraName, Future<bool> Function(Uri uri)? launchLink })` · Nhận: `FacebookLiveError.pageNotEligible`, `facebookLiveDefaultCameraName`, khoá i18n từ 1.1
  - Chủ file chung: 1.2 giữ `facebook_live_panel.dart`, `camera_editor_sheet.dart`, `camera_create_flow.dart`
  - Phụ thuộc: sau 1.1

- [ ] 1.3 Kiểm cuối. Tiêu chí: `dart analyze lib/features/tournament lib/l10n` không lỗi mới (so với `origin/main`); `flutter test --no-pub` trên các file test ở 1.1–1.2 → exit 0; `flutter analyze` toàn cục và full test chạy trên cloud runner, không chạy local
  - Files: không sửa file
  - Giao: (không) · Nhận: kết quả 1.1–1.2
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.2
