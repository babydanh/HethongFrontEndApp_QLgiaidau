## 1. Thẻ trận dùng chung
- [x] 1.1 Thẻ toàn màn hình dùng thiết kế mới như tab Bảng đấu. Tiêu chí: `flutter test --no-pub test/features/bracket_match_card_test.dart test/features/bracket_holding_tray_test.dart test/features/playoff_match_card_test.dart` → exit 0
  - Files: tạo `lib/features/bracket/widgets/bracket_card_parts.dart`; sửa `bracket_match_card.dart`, `playoff_bracket_board.dart`, `single_elim_diagram.dart`, `double_elim_diagram.dart`; xoá `team_row.dart`; test `test/features/bracket_match_card_test.dart`, `test/features/bracket_holding_tray_test.dart`
