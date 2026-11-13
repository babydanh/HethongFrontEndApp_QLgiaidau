## 1. Gộp màn

- [x] 1.1 Mục "Phát trực tiếp" mở tab Camera; màn livestream bỏ khối camera, điện thoại phát chỉ hiện khi có cộng đồng, thêm `showLivestreamToolsSheet`. Tiêu chí: `flutter test --no-pub test/features/tournament_management_livestream_section_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_hub_screen.dart:192-204,946-952`; sửa `lib/features/tournament/screens/tournament_management_livestream_section.dart:224-247`; xoá `lib/features/tournament/widgets/tournament_camera_panel.dart`, `test/features/tournament_camera_panel_test.dart`; test `test/features/tournament_management_livestream_section_test.dart`
  - Giao: `Future<void> showLivestreamToolsSheet(BuildContext context, {required String tournamentId, String? communityId})` cho 1.2 · Nhận: (không)
  - Chủ file chung: 1.1 giữ `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`
  - Phụ thuộc: (không)
- [x] 1.2 Tab Camera: menu ⋮ "Điện thoại & phiên phát", khối "Trận chưa có sân" ẩn khi rỗng. Tiêu chí: `flutter test --no-pub test/features/tournament/camera_tab_redesign_test.dart test/features/tournament/camera_tab_header_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_camera_section.dart:41-51,292-402,447-518`; sửa `lib/features/tournament/widgets/camera_tab_header.dart:11,122-141`; test `test/features/tournament/camera_tab_redesign_test.dart`
  - Giao: `CameraTabHeader.onOpenStreaming: VoidCallback?`; `TournamentManagementCameraSection.communityId: String?` · Nhận: `showLivestreamToolsSheet` của 1.1
  - Phụ thuộc: sau 1.1
- [x] 1.3 Popup sân gọn: dòng camera (Đổi/Gán, QR, xoá trong bộ chọn), ⏻ ở tiêu đề, URL thu gọn. Tiêu chí: `flutter test --no-pub test/features/tournament/camera_court_sheet_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/camera_court_card.dart:139-267`; viết lại `lib/features/tournament/widgets/camera_court_info.dart`; sửa `lib/features/tournament/widgets/court_camera_row.dart:24-48,160-195`; test `test/features/tournament/camera_court_sheet_test.dart`
  - Giao: `CameraCourtInfo({tournamentId, court, camera, cameras, readOnly})` · Nhận: (không)
  - Phụ thuộc: sau 1.1
- [x] 1.4 Kiểm cuối. Tiêu chí: `flutter analyze --no-pub lib/features/tournament test/features` → exit 0 và test của 1.1–1.3 → exit 0; integration test `integration_test/xem_tai_tro_livestream_ketqua_test.dart` sửa theo, chạy trên CI
  - Files: sửa `integration_test/xem_tai_tro_livestream_ketqua_test.dart`
  - Phụ thuộc: sau 1.2, 1.3
