## 1. Bảng giữ mọi vòng, mở sẵn chung kết

- [x] 1.1 `focusResultsRoundKey(rounds, matchIds)`; `ResultsMatchBoard` prop `focusFinal` giữ đủ trận, mở hộp chứa chung kết; `ResultsMergedTab` truyền `focusFinal: hasPodium`. Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_match_board_test.dart test/features/tournament/utils/results_rounds_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/utils/results_rounds.dart`, `lib/features/tournament/widgets/results_match_board.dart`, `lib/features/tournament/widgets/results_merged_tab.dart`; test `test/features/tournament/widgets/results_match_board_test.dart`
  - Giao: `String? focusResultsRoundKey(List<ResultsRound> rounds, Set<String>? matchIds)` · Nhận: `pickFinalMatches` có sẵn
  - Chủ file chung: 1.1
  - Phụ thuộc: không

## 2. Kiểm tra

- [x] 2.1 Analyze file đã sửa và test liên quan. Tiêu chí: `flutter analyze --no-pub` trên 4 file đã sửa → exit 0; `flutter test --no-pub` các file test dùng `ResultsMergedTab`/`ResultsMatchBoard` → exit 0
  - Files: (không)
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.1
