## 1. Tên camera mặc định "Cam N"
- [x] 1.1 `CameraEditorSheet.initialName` chỉ prefill khi tạo mới; `runCreateCameraFlow` truyền "Cam ${cameras.length + 1}". Tiêu chí: `flutter test --no-pub test/features/camera_editor_sheet_test.dart` → exit 0
  - Files: `lib/features/tournament/widgets/camera_editor_sheet.dart`, `lib/features/tournament/utils/camera_create_flow.dart`, l10n
  - Phụ thuộc: (không)

## 2. Stepper số sân
- [x] 2.1 Widget `CourtCountStepper` dùng cho "Số sân ban đầu". Tiêu chí: `flutter test --no-pub test/features/tournament_management_venues_section_test.dart` → exit 0
  - Files: `lib/features/tournament/widgets/court_count_stepper.dart` (mới), `lib/features/tournament/screens/tournament_management_venues_section.dart`, l10n
  - Phụ thuộc: (không)

## 3. Tab Camera
- [x] 3.1 Nút "+" luôn hiện, báo thêm sân trước, bố cục camera trên sân dưới, nhãn "Sân N". Tiêu chí: các test camera tab trong `test/features/tournament/` → exit 0
  - Files: `tournament_management_camera_section.dart`, `camera_tab_header.dart`, `camera_court_card.dart`, `camera_list_section.dart`, `schedule_court_label.dart`, l10n
  - Chủ file chung: lane này sở hữu `lib/l10n/app_vi.arb`, `app_en.arb`
  - Phụ thuộc: (không)
