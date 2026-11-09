## 1. Nút đổi giao giữa thanh dưới

- [x] 1.1 Thêm `onLoseServe` cho view/scoreboard/panel và nút giữa thanh dưới. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_scoreboard_test.dart test/match/pickleball_court_undo_panel_test.dart` xanh (TC-SERVE-APP-06, TC-SERVE-APP-07)
  - Files: `lib/features/match/widgets/pickleball_court_view.dart`, `pickleball_court_scoreboard.dart`, `pickleball_court_panel.dart`, test tương ứng

- [x] 1.2 Tên nút theo bước kế tiếp ("Đổi tay" / "Đổi giao"). Tiêu chí: `flutter test --no-pub test/match/pickleball_court_scoreboard_test.dart test/match/pickleball_court_undo_panel_test.dart test/match/pickleball_court_panel_actions_test.dart` xanh (TC-SERVE-APP-08)
  - Files: `lib/features/match/widgets/pickleball_court_{view,scoreboard,panel}.dart`, `lib/l10n/app_{vi,en}.arb` (+ file sinh), test tương ứng
