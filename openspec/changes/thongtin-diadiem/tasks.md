## 1. Sheet camera của sân

- [x] 1.1 Widget `CourtCameraSheet` che URL (Hiện/Ẩn), Lưu, Gỡ camera (xác nhận). Tiêu chí: `flutter test --no-pub test/features/court_camera_sheet_test.dart` exit 0 (đỏ trước khi có widget).
  - Files: `lib/features/tournament/widgets/court_camera_sheet.dart`, `test/features/court_camera_sheet_test.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`
  - Giao: `showCourtCameraSheet(context, tournamentId, courtId, courtName)` · Nhận: venues section
  - Chủ file chung: ARB (cùng task 3.1)
  - Phụ thuộc: không

## 2. Dòng sân gọn

- [x] 2.1 Mỗi sân một dòng (tên, trạng thái camera, nút sửa, menu ⋮ có Xoá sân + xác nhận), bỏ chip ✕ và ô URL. Tiêu chí: `flutter test --no-pub test/features/tournament_management_venues_section_test.dart` exit 0.
  - Files: `lib/features/tournament/screens/tournament_management_venues_section.dart`, `test/features/tournament_management_venues_section_test.dart`, ARB
  - Giao: không đổi API · Nhận: không
  - Chủ file chung: không
  - Phụ thuộc: 1.1

## 3. Thông tin giải

- [x] 3.1 Bốn nhóm thu gọn + một nút Lưu dính đáy + Giải thưởng/Liên hệ + hỏi khi thoát. Tiêu chí: `flutter test --no-pub test/features/tournament_management_settings_section_test.dart` exit 0.
  - Files: `lib/features/tournament/screens/tournament_management_section_screen.dart`, `lib/features/tournament/screens/tournament_management_brands_section.dart`, `lib/features/tournament/screens/tournament_management_hub_screen.dart`, `test/features/tournament_management_settings_section_test.dart`, ARB
  - Giao: tham số `unsavedChanges` (ValueNotifier) của `TournamentManagementSectionScreen` · Nhận: hub
  - Chủ file chung: section_screen, hub screen
  - Phụ thuộc: không

## 4. Kiểm tra cuối

- [x] 4.1 gen-l10n, analyze, test liên quan. Tiêu chí: `flutter analyze --no-pub lib/features/tournament` không error/warning mới, các test trên exit 0.
  - Files: không
  - Phụ thuộc: 1.1, 2.1, 3.1
