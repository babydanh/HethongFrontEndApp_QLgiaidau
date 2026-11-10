## 1. Shared save helper

- [x] 1.1 Tách logic lưu xếp bảng khỏi `GroupStageAssignmentScreen._save` thành hàm dùng chung, màn cũ gọi lại hàm đó. Tiêu chí: `flutter test --no-pub test/features/group_stage_assignment_test.dart` → exit 0
  - Files: tạo `lib/features/bracket/utils/save_group_assignment.dart`; sửa `lib/features/bracket/screens/group_stage_assignment_screen.dart:48-130`; test `test/features/group_stage_assignment_test.dart`
  - Giao: `Future<SaveGroupAssignmentResult> saveGroupAssignment(WidgetRef ref, {required String tournamentId, required String divisionId, required TournamentDivision division, required GroupStageConfig config, required List<MatchModel> matches})` với `SaveGroupAssignmentResult { saved, regenerated, regenerationError }` · Nhận: (không)
  - Chủ file chung: 1.1 giữ `group_stage_assignment_screen.dart`
  - Phụ thuộc: không

## 2. Drag-drop trong GroupStageView

- [x] 2.1 Thêm tham số chỉnh sửa tuỳ chọn và kéo thả đội giữa các `_GroupCard`; truyền qua `PublicBracketView`/`_GroupPlayoffTabs`/`PublicBracketLoader` (chỉ thêm tham số). Tiêu chí: `flutter test --no-pub test/features/group_stage_view_test.dart test/features/public_bracket_view_test.dart` → exit 0 (TC-GROUP-DND-01..03)
  - Files: sửa `lib/features/bracket/widgets/group_stage_view.dart`, `lib/features/bracket/widgets/public_bracket_view.dart`; test `test/features/group_stage_view_test.dart`, `test/features/public_bracket_view_test.dart`
  - Giao: `GroupStageView(editableConfig: GroupStageConfig?, onConfigChanged: Future<void> Function(GroupStageConfig)?, editLocked: bool)` (mặc định: chỉ đọc) · Nhận: `GroupStageConfig.moveParticipant` có sẵn
  - Chủ file chung: 2.1 giữ cả hai widget file
  - Phụ thuộc: không (độc lập với 1.1, nhưng cùng chuỗi tuần tự để an toàn)

## 3. Nối vào màn quản lý

- [x] 3.1 Thay nhánh `hasGroupStage` của `BracketViewScreen` bằng view chung ở chế độ chỉnh sửa khi `canManageGroupAssignment`; gọi `saveGroupAssignment`; bỏ tab bar cũ và nút "Quản lý bảng". Tiêu chí: `flutter test --no-pub test/features/organizer_bracket_inline_test.dart test/features/bracket_view_embedded_test.dart` → exit 0 (TC-GROUP-DND-04)
  - Files: sửa `lib/features/bracket/screens/bracket_view_screen.dart:488-519, 617-780, 910+`; test `test/features/organizer_bracket_inline_test.dart`, `test/features/bracket_view_embedded_test.dart`
  - Giao: (không) · Nhận: `saveGroupAssignment` từ 1.1, tham số `GroupStageView` từ 2.1
  - Chủ file chung: 3.1 giữ `bracket_view_screen.dart`; không đụng `CrossTableView`/`StandingsView`
  - Phụ thuộc: sau 1.1 và 2.1

## 4. Kiểm tra cuối

- [x] 4.1 `flutter analyze --no-pub` trên thư mục đã sửa và chạy toàn bộ test liên quan. Tiêu chí: `flutter analyze --no-pub lib/features/bracket` → exit 0; các test trên → exit 0
  - Files: (không sửa file)
  - Phụ thuộc: sau 3.1
