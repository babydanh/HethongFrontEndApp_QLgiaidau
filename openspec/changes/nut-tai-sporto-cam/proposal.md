## Why

BTC dùng điện thoại làm camera phải tự tìm app SportO Cam trên store, vì sheet "Thêm camera" của App chỉ có hướng dẫn mà không có đường dẫn tải app. Thêm nút tải ngay trong sheet, giống bản Web đã làm.

## What Changes

- Tab `Camera / điện thoại` của sheet "Thêm camera" hiện thêm một dòng gợi ý và nút tải SportO Cam, ngay dưới phần hướng dẫn `CameraAddHelp`.
- Android chỉ hiện nút Google Play; iPhone chỉ hiện nút App Store; nền tảng khác hiện cả hai.
- Nhận biết nền tảng bằng `defaultTargetPlatform` (App chạy ngay trên điện thoại nên biết chắc).
- Bấm nút mở trang store ở ứng dụng ngoài bằng `url_launcher` (đã là dependency).
- Chữ mới có đủ vi và en.

## Out of scope

- Không đụng tab `Live YouTube / Facebook`, Backend, Web.
- Không sửa link store của app SportO chính (`app_update_service.dart` đang dùng id Android khác `applicationId` thật; việc riêng).
- Không format lại phần code cũ của `camera_editor_sheet.dart`.

## Capabilities

### New Capabilities
- `sporto-cam-download-app`: nút tải app SportO Cam theo nền tảng trong sheet Thêm camera.

### Modified Capabilities

## Impact

App: `lib/features/tournament/widgets/sporto_cam_download.dart` (mới), `camera_editor_sheet.dart` (gắn widget), `lib/l10n/app_vi.arb`, `app_en.arb` và 3 file `app_localizations*.dart` sinh lại, `test/features/sporto_cam_download_test.dart`.
