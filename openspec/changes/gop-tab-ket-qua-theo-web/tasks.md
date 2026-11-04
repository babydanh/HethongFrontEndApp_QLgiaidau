## 1. Final match picker

- [x] 1.1 Thêm `pickFinalMatches` port của Web. Tiêu chí: `flutter test --no-pub test/features/tournament/final_matches_test.dart` → exit 0
  - Files: tạo `lib/features/tournament/utils/final_matches.dart`, `test/features/tournament/final_matches_test.dart`
  - Giao: `List<MatchModel>? pickFinalMatches(List<MatchModel> matches)` cho 1.2 · Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: không

## 2. Merged tab

- [x] 2.1 `ResultsMatchBoard` nhận `finalOnly`. Tiêu chí: `flutter test --no-pub test/features/tournament/results_match_board_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/results_match_board.dart`
  - Giao: tham số `bool finalOnly = false` · Nhận: `pickFinalMatches` từ 1.1
  - Chủ file chung: 2.1 giữ `results_match_board.dart`
  - Phụ thuộc: sau 1.1
- [x] 2.2 Tab gộp `ResultsMergedTab` và `ResultsTab(embedded)`. Tiêu chí: `flutter test --no-pub test/features/tournament/results_merged_tab_test.dart test/features/tournament/results_tab_test.dart` → exit 0
  - Files: tạo `lib/features/tournament/widgets/results_merged_tab.dart`; sửa `lib/features/tournament/widgets/results_tab.dart`; test `test/features/tournament/results_merged_tab_test.dart`
  - Giao: `ResultsMergedTab({tournamentId, divisionId, isLite, canManage, onShare})` · Nhận: `finalOnly` từ 2.1
  - Chủ file chung: 2.2 giữ `results_tab.dart`
  - Phụ thuộc: sau 2.1
- [x] 2.3 Màn giải công khai: bỏ tab Đang diễn ra, Kết quả ở cuối, chấm đỏ và số trận. Tiêu chí: `flutter test --no-pub test/features/tournament_tabs_density_smoke_test.dart test/features/tournament_intro_division_strip_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_intro_screen.dart`; xóa `lib/features/tournament/widgets/live_tab.dart`, `test/features/tournament/widgets/live_tab_test.dart`; sửa test liên quan
  - Chủ file chung: 2.3 giữ `tournament_intro_screen.dart`
  - Phụ thuộc: sau 2.2

## 3. Kết thúc

- [x] 3.1 Rà toàn bộ. Tiêu chí: `flutter test --no-pub test/features/tournament test/match` → exit 0 và `flutter analyze --no-pub lib/features/tournament` → exit 0
  - Files: (không sửa file mới)
  - Phụ thuộc: sau 2.3
