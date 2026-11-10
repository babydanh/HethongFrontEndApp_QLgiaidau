## 1. Đổi đội giao là một bước hoàn tác

- [x] 1.1 Thêm `setServerAfterTeamChange` (không ghi history) và dùng trong `PickleballCourtPanel._applyDrop` khi `SetServer.changesServingTeam`. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_undo_panel_test.dart test/match/pickleball_serve_pick_test.dart test/match/pickleball_serve_number_test.dart` xanh (TC-SERVE-APP-03, TC-SERVE-APP-04)
  - Files: `lib/features/match/utils/pickleball_court.dart`, `lib/features/match/widgets/pickleball_court_panel.dart`, test tương ứng
