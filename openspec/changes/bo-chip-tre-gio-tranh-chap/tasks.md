## 1. Bỏ chip và đổi đích bấm
- [ ] 1.1 Bỏ `ResultsBoardFilter.late/disputed` và `clock`; đích "tranh chấp" thành `StepTarget(StepHubTab.results)`, "trễ giờ" thành chip `unfinished`. Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_match_board_test.dart test/features/tournament/utils/tournament_step_summary_test.dart test/features/tournament/widgets/step_detail_popup_test.dart test/features/tournament/overview_step_popup_test.dart` → exit 0 (chạy trên cloud)
  - Files: sửa `lib/features/tournament/widgets/results_match_board.dart`, `lib/features/tournament/utils/tournament_step_summary.dart`; test `test/features/tournament/widgets/results_match_board_test.dart` (TC-RESULTS-02, 04, TC-RBR-17), `test/features/tournament/utils/tournament_step_summary_test.dart` (TC-STEP-05), `test/features/tournament/overview_step_popup_test.dart` (TC-STEP-15), `test/features/tournament/widgets/step_detail_popup_test.dart`
  - Giao: `enum ResultsBoardFilter { all, live, upcoming, finished, unfinished }` · Nhận: (không)
  - Chủ file chung: task này giữ cả hai file nguồn
  - Phụ thuộc: không
