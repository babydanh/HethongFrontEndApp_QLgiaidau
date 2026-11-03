## Why
Bản đầu của tab Playoff nhánh thắng/thua (`playoff-theo-web`) chỉ liệt kê trận theo trang, không có sơ đồ. Web (`PagedDoubleElimView`) vẽ bracket có đường nối giữa các trận, trượt cửa sổ 3 vòng. Ngoài ra BTC/admin xem tab công khai vẫn phải mở popup chấm điểm khi bấm trận, như màn quản lý.

## What Changes
- `PlayoffDoubleElimView` vẽ bracket: thẻ trận xếp theo trận nguồn, đường nối xanh khi trận nguồn đã xong, cửa sổ 3 vòng trượt bằng Vòng trước/Vòng sau hoặc bấm nhãn vòng, nhánh/vòng mặc định là chỗ đang diễn ra. Bên chưa có đội ghi "Thắng W4" / "Thua W6".
- Thay mục phân trang "Trang x / y" của `playoff-theo-web`.
- Tab công khai nhận `canScoreMatch` (admin hoặc người quản lý giải): bấm trận mở `MatchScoreEntryChooser` thay popup chi tiết; người xem thường không đổi. Áp cho vòng bảng, playoff nhánh thắng/thua và sơ đồ loại trực tiếp.
- Màn quản lý/trọng tài (`BracketViewScreen`) không đổi.

## Impact
`lib/features/bracket/widgets/playoff_bracket_layout.dart` (mới, thuần), `playoff_bracket_board.dart` (mới), `playoff_double_elim_view.dart`, `group_match_sheet.dart`, `group_stage_view.dart`, `public_bracket_view.dart`, `lib/features/tournament/screens/tournament_intro_screen.dart`, `app_{vi,en}.arb`.
