## 1. Dữ liệu dùng chung
- [x] 1.1 Tách helper nhóm bảng/lượt từ `CrossTableView` sang `group_stage_data.dart`. Tiêu chí: `flutter test --no-pub test/features/group_stage_data_test.dart` → exit 0
  - Files: tạo `lib/features/bracket/widgets/group_stage_data.dart`, `test/features/group_stage_data_test.dart`; sửa `cross_table_view.dart`
## 2. Giao diện
- [x] 2.1 `GroupStageView` + `showGroupMatchSheet` + l10n. Tiêu chí: `flutter test --no-pub test/features/group_stage_view_test.dart` → exit 0
  - Files: tạo `group_stage_view.dart`, `group_match_sheet.dart`, `test/features/group_stage_view_test.dart`; sửa `participant_display.dart`, `app_vi.arb`, `app_en.arb`, `public_bracket_view.dart`
- [x] 2.2 Test cũ còn xanh và analyze sạch. Tiêu chí: `flutter test --no-pub test/features/public_bracket_view_test.dart` + `flutter analyze --no-pub lib/features/bracket` → exit 0
