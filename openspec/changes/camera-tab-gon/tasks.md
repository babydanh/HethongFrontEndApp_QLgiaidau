## 1. Camera tab compact
- [x] 1.1 Nút Bật/Tắt cam, ghi chú Chỉ xem, chip sân một hàng, bỏ chip thừa. Tiêu chí: `flutter test --no-pub test/features/tournament/camera_tab_gon_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/camera_match_row.dart`, `camera_tab_header.dart`, `camera_court_card.dart`, `lib/features/tournament/screens/tournament_management_camera_section.dart`, `lib/l10n/app_vi.arb`, `app_en.arb`; test `test/features/tournament/camera_tab_gon_test.dart`
  - Giao: `CameraTabHeader(readOnly: bool = false)` · Nhận: (không)
  - Chủ file chung: 1.1 giữ cả bốn file widget
  - Phụ thuộc: (không)
