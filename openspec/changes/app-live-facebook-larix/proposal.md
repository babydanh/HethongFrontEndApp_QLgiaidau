## Why
Sau "Tạo live", người phát bằng chính điện thoại phải chép địa chỉ RTMP và khoá phát rất dài sang app livestream; chép sai là hỏng. Cần cách mở Larix Broadcaster với cấu hình đã điền sẵn bằng một chạm.

## What Changes
- Thêm hàm dựng link cấu hình Larix (`larix://set/v1?...`) ở `lib/features/tournament/utils/larix_link.dart`.
- `FacebookLivePanel` thêm nút "Mở trong Larix" sau khi tạo live; Larix chưa cài thì báo bằng SnackBar.
- Thêm 3 khoá l10n `tournamentCameraFbLarix*` (vi, en) và sinh lại `app_localizations*.dart`.
- Không có mã QR trong App: quét QR ngay trên màn hình điện thoại đang cầm là vô nghĩa; mã QR dành cho Web.

## Out of scope
- Đổi Backend/API; app phát khác ngoài Larix; sửa `AndroidManifest`/`Info.plist` (chỉ gọi `launchUrl`, không dùng `canLaunchUrl`).

## Capabilities

### New Capabilities
- `app-facebook-live-larix`: mở Larix với cấu hình RTMP của live Facebook bằng một chạm.

### Modified Capabilities
(none)

## Impact
- `lib/features/tournament/widgets/facebook_live_panel.dart`, `lib/features/tournament/utils/larix_link.dart`, `lib/l10n/*`, `test/features/camera_facebook_live_larix_test.dart`.
- Link chứa khoá phát: không ghi log, không lưu; chỉ truyền thẳng cho `launchUrl`.
