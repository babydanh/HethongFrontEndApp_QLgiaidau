## 1. Bracket playoff
- [x] 1.1 Layout thuần (cửa sổ, vị trí thẻ, đường nối, trận nguồn). Tiêu chí: `flutter test --no-pub test/features/playoff_bracket_layout_test.dart` → exit 0
  - Files: tạo `lib/features/bracket/widgets/playoff_bracket_layout.dart`, `test/features/playoff_bracket_layout_test.dart`
  - Giao: `bracketWindowStart(int, int)`, `computeBracketTops(List<List<MatchModel>>, double)`, `computeBracketLinks(...)`, `buildFeeders(List<MatchModel>)` · Nhận: (không)
  - Chủ file chung: 1.1 giữ file layout
  - Phụ thuộc: (không)
- [x] 1.2 Widget bracket thay danh sách. Tiêu chí: `flutter test --no-pub test/features/playoff_double_elim_view_test.dart test/features/public_bracket_view_test.dart` → exit 0
  - Files: tạo `lib/features/bracket/widgets/playoff_bracket_board.dart`; sửa `playoff_double_elim_view.dart`, `app_vi.arb`, `app_en.arb`, `test/features/playoff_double_elim_view_test.dart`, `test/features/public_bracket_view_test.dart`
  - Giao: `PlayoffBracketBoard` · Nhận: layout của 1.1
  - Chủ file chung: 1.2 giữ ARB
  - Phụ thuộc: sau 1.1

## 2. Chấm điểm từ tab công khai
- [x] 2.1 Truyền `canScoreMatch` từ màn giới thiệu giải tới popup. Tiêu chí: `flutter test --no-pub test/features/playoff_double_elim_view_test.dart test/features/group_stage_view_test.dart` → exit 0
  - Files: sửa `group_match_sheet.dart`, `group_stage_view.dart`, `playoff_double_elim_view.dart`, `public_bracket_view.dart`, `lib/features/tournament/screens/tournament_intro_screen.dart`
  - Giao: `showGroupMatchSheet(..., {bool canScore = false})` · Nhận: (không)
  - Phụ thuộc: sau 1.2

## 3. Kiểm tra cuối
- [x] 3.1 Analyze + test liên quan. Tiêu chí: `flutter analyze --no-pub lib/features/bracket lib/features/tournament/screens/tournament_intro_screen.dart` → exit 0
