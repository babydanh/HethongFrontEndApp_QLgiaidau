## 1. Chuỗi hiển thị

- [x] 1.1 Thêm key vi/en: nút "Xem camera", tiêu đề "Tường camera", nhãn lưới (`{n}×{n}`), "Trang {page}/{total}", trang trước/sau, công tắc "Xem thử", "Chưa có trận", "Không có hình", rồi `flutter gen-l10n`. Tiêu chí: `flutter gen-l10n` → exit 0 và key có ở cả `app_vi.arb` lẫn `app_en.arb`
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; sinh lại `lib/l10n/app_localizations*.dart` (không sửa tay)
  - Giao: các getter `AppLocalizations` mới (tiền tố `tournamentManagementCameraWall…`) cho 2.2, 2.3 · Nhận: (không)
  - Chủ file chung: 1.1 giữ hai file `.arb`
  - Phụ thuộc: không

## 2. Tường camera

- [x] 2.1 Hàm thuần trong `camera_wall.dart` giống `src/features/tournaments/camera-wall.ts` của Web (TDD, test đỏ trước). Tiêu chí: `flutter test --no-pub test/features/tournament/camera_wall_test.dart` → exit 0 (TC-APP-CAMWALL-01..06)
  - Files: tạo `lib/features/tournament/utils/camera_wall.dart`; test `test/features/tournament/camera_wall_test.dart`
  - Giao: `const List<int> cameraWallLayouts = [1, 2, 3, 4];` · `({List<TournamentCameraModel> items, int pageCount, int page}) cameraWallPage(List<TournamentCameraModel> cameras, int layout, int page)` (page 1-based, kẹp vào khoảng hợp lệ, `pageCount >= 1`) · `bool shouldMountCameraPlayer(TournamentCameraModel camera, bool previewOn)` (`previewOn && status == 'LIVE' && playbackUrl` không rỗng) · `int cameraWallPageOf(List<TournamentCameraModel> cameras, String cameraId, int layout)` · `CameraWallMatchLabel? cameraWallMatchLabel(TournamentCameraModel camera, Map<String, MatchLivestreamSummary> streams, List<MatchModel> matches)` với `class CameraWallMatchLabel { final String kind; /* live|ongoing|next */ final String code; final String team1; final String team2; }` (không chứa tỉ số; bỏ trận BYE; `code` lấy `matchCode`, rỗng thì `matchNumber`)
  - Nhận: (không)
  - Chủ file chung: không
  - Phụ thuộc: không
- [x] 2.2 `CameraWallScreen`: thanh chọn lưới (mặc định 2×2), lưới ô, chia trang, ô camera (tên, `CameraStatusBadge`, dòng trận, công tắc xem thử, `LiveVideoPlayer(url: playbackUrl, label: name, showStreamStats: true, fill: true)` chỉ khi `shouldMountCameraPlayer`), chạm đúp → 1×1 đúng camera; không tràn ở 360×640 và 1024×768. Tiêu chí: `flutter test --no-pub test/features/tournament/camera_wall_screen_test.dart` → exit 0 (TC-APP-CAMWALL-10..16)
  - Files: tạo `lib/features/tournament/widgets/camera_wall_screen.dart`; test `test/features/tournament/camera_wall_screen_test.dart` (override `tournamentCamerasProvider`, `tournamentMatchLivestreamsProvider`, `managedMatchesWithDivisionProvider`; kiểm 20 camera → 16 + 4 ở 4×4; OFFLINE không có `LiveVideoPlayer`; tắt công tắc gỡ `LiveVideoPlayer` và adapter Dio không nhận request mới)
  - Giao: `CameraWallScreen({super.key, required String tournamentId})` (`ConsumerStatefulWidget`) · Nhận: hàm của 2.1, getter l10n của 1.1
  - Chủ file chung: 2.2 giữ `camera_wall_screen.dart`
  - Phụ thuộc: sau 1.1 và 2.1
- [ ] 2.3 Nút "Xem camera" ở tab Camera (cạnh nút tải lại, ẩn khi chưa có camera), mở `CameraWallScreen` bằng `Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, ...))` (không thêm route vào `app_router.dart`). Tiêu chí: `flutter test --no-pub test/features/tournament/management_camera_tab_test.dart` → exit 0 (TC-APP-CAMWALL-20..21, giữ test cũ)
  - Files: sửa `lib/features/tournament/screens/tournament_management_camera_section.dart` (khối tiêu đề quanh dòng 240–280); sửa `test/features/tournament/management_camera_tab_test.dart`
  - Giao: (không) · Nhận: `CameraWallScreen` (2.2)
  - Chủ file chung: 2.3 giữ `tournament_management_camera_section.dart`
  - Phụ thuộc: sau 2.2

## 3. Kiểm cuối

- [ ] 3.1 Phân tích và test liên quan. Tiêu chí: `flutter analyze --no-pub lib/features/tournament lib/l10n` → 0 error/warning mới; `flutter test --no-pub test/features/tournament/camera_wall_test.dart test/features/tournament/camera_wall_screen_test.dart test/features/tournament/management_camera_tab_test.dart test/features/tournament_camera_panel_test.dart test/features/tournament_management_camera_catalog_test.dart` → exit 0
  - Files: (không sửa thêm)
  - Giao: (không) · Nhận: 1.1, 2.1, 2.2, 2.3
  - Chủ file chung: không
  - Phụ thuộc: sau 2.3
