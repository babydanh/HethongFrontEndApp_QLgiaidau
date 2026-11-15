## 1. Hàm dựng link và nút mở Larix
- [x] 1.1 `buildLarixSetupUrl(rtmpUrl, streamKey, name): String?` và nút trong `FacebookLivePanel`. Tiêu chí: `flutter test --no-pub test/features/camera_facebook_live_larix_test.dart` → exit 0; `flutter analyze --no-pub lib/features/tournament/widgets/facebook_live_panel.dart lib/features/tournament/utils/larix_link.dart` → exit 0
  - Files: tạo `lib/features/tournament/utils/larix_link.dart`; sửa `lib/features/tournament/widgets/facebook_live_panel.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ `app_localizations*.dart` sinh bằng `flutter gen-l10n`); test `test/features/camera_facebook_live_larix_test.dart` (TC-LARIX-APP-01..06)
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: task này giữ `app_vi.arb`, `app_en.arb`
  - Phụ thuộc: (không)
