## 1. Nền: hàng kéo thả và hàm mở trận
- [ ] 1.1 Tạo `BracketSlotRow` (chuyển nguyên logic kéo/thả/chạm/khóa từ `BracketMatchCard._buildSlotRow`), viết test trước. Tiêu chí: `flutter test --no-pub test/features/bracket_slot_row_test.dart` → exit 0 (TC-BRK-ROW-01 SWAP, 02 MOVE, 03 khay chờ ASSIGN, 04 ô khóa, 05 BYE, 06 chạm-chạm, 07 `onSlotDrop` ném lỗi không kẹt)
  - Files: tạo `lib/features/bracket/widgets/bracket_slot_row.dart`; test `test/features/bracket_slot_row_test.dart` (tham khảo `test/features/bracket_holding_tray_test.dart`)
  - Giao: `BracketSlotRow({match, slot, label, child, selectedSlot, onSlotTap, onSlotDrop})` cho 3.1 · Nhận: (không)
  - Chủ file chung: 1.1 giữ `bracket_slot_row.dart`
  - Phụ thuộc: (không)
- [ ] 1.2 Tách `openBracketMatch` từ `BracketMatchCard._onTap`. Tiêu chí: `flutter test --no-pub test/features/bracket_match_tap_test.dart` → exit 0 (TC-BRK-TAP-01 có quyền chấm → bộ chọn; 02 live/scheduled → route live; 03 còn lại → popup chi tiết)
  - Files: tạo `lib/features/bracket/widgets/bracket_match_tap.dart`; test `test/features/bracket_match_tap_test.dart`
  - Giao: `void openBracketMatch(BuildContext, {match, tournamentId, canScoreMatch, isReferee, isReadOnly})` cho 4.1 · Nhận: (không)
  - Phụ thuộc: (không)

## 2. Lật trang theo mép
- [ ] 2.1 Tạo `BracketEdgePager`. Tiêu chí: `flutter test --no-pub test/features/bracket_edge_pager_test.dart` → exit 0 (TC-BRK-EDGE-01 giữ 450ms ở mép phải gọi `onNext`; 02 rời sớm không gọi; 03 `onNext == null` không gọi; 04 giảm chuyển động vẫn lật)
  - Files: tạo `lib/features/bracket/widgets/bracket_edge_pager.dart`; test `test/features/bracket_edge_pager_test.dart`
  - Giao: `BracketEdgePager({required Widget child, required bool enabled, VoidCallback? onPrev, VoidCallback? onNext})` cho 4.1 · Nhận: (không)
  - Phụ thuộc: (không)

## 3. Thẻ mới ở chế độ sửa
- [ ] 3.1 Mở rộng `_BracketCard`/`PlayoffBracketBoard`: `BracketEditing`, `selectedSlot`, `onSlotTap`, hàng BYE, viền vàng chung kết, ELO, chip "Chấm điểm", bọc hàng bằng `BracketSlotRow` khi có `editing`. Tiêu chí: `flutter test --no-pub test/features/playoff_match_card_edit_test.dart test/features/playoff_match_card_test.dart` → exit 0 (TC-BRK-CARD-01 BYE; 02 chung kết viền vàng; 03 ELO; 04 chip chấm điểm chỉ khi có quyền; 05 không `editing` thì không có `DragTarget`)
  - Files: sửa `lib/features/bracket/widgets/playoff_bracket_board.dart`; test `test/features/playoff_match_card_edit_test.dart`
  - Giao: `BracketEditing({onSlotDrop, isUpdating})`; `PlayoffBracketBoard` thêm `editing`, `selectedSlot`, `onSlotTap`, `canScoreMatch`, `isReferee`, `isReadOnly`, `onDoubleTapMatch` cho 4.1 · Nhận: `BracketSlotRow` từ 1.1
  - Chủ file chung: 3.1 giữ `playoff_bracket_board.dart` (5.1 cũng sửa nên phải sau 3.1)
  - Phụ thuộc: sau 1.1

## 4. View và hai màn quản lý
- [ ] 4.1 `PlayoffDoubleElimView` nhận `editing`, `onMatchTap`, `onDoubleTapMatch`; giữ `_selectedSlot`/`_isUpdating`/xử lý chạm-chạm (chuyển từ `SingleElimDiagram`), bọc cửa sổ bằng `BracketEdgePager` nối với `select()`. Tiêu chí: `flutter test --no-pub test/features/playoff_double_elim_view_test.dart test/features/playoff_double_elim_view_edit_test.dart` → exit 0 (TC-BRK-VIEW-01 kéo tới mép lật vòng; 02 chạm-chạm gọi `onSlotDrop` một lần; 03 đang cập nhật không nhận thao tác; 04 không `editing` → chỉ xem)
  - Files: sửa `lib/features/bracket/widgets/playoff_double_elim_view.dart`; test `test/features/playoff_double_elim_view_edit_test.dart`
  - Giao: `PlayoffDoubleElimView({..., BracketEditing? editing, ValueChanged<MatchModel>? onMatchTap, ValueChanged<MatchModel>? onDoubleTapMatch})` cho 4.2 · Nhận: `BracketEdgePager` từ 2.1, `BracketEditing` từ 3.1, `openBracketMatch` từ 1.2
  - Chủ file chung: 4.1 giữ `playoff_double_elim_view.dart` (5.1 cũng sửa nên phải sau 4.1)
  - Phụ thuộc: sau 1.2, 2.1, 3.1
- [ ] 4.2 Đổi hai màn quản lý sang `PlayoffDoubleElimView`. Tiêu chí: `flutter test --no-pub test/features/bracket_view_embedded_test.dart test/features/organizer_bracket_inline_test.dart test/features/bracket_holding_tray_test.dart` → exit 0 (đã sửa cho khớp view mới)
  - Files: sửa `lib/features/bracket/screens/bracket_view_screen.dart:1455-1477` và import, `lib/features/bracket/screens/bracket_diagram_screen.dart:241-261` và import; test `test/features/bracket_view_embedded_test.dart`, `test/features/organizer_bracket_inline_test.dart`
  - Giao: (không) · Nhận: `PlayoffDoubleElimView` có `editing` từ 4.1
  - Chủ file chung: 4.2 giữ hai màn hình; KHÔNG chạm dòng ~13 và 461–468 của `bracket_view_screen.dart` (nhánh khác đang sửa)
  - Phụ thuộc: sau 4.1

## 5. Chuyển động
- [ ] 5.1 Thêm chuyển động theo bảng trong `design.md`: nhấc/thả, ô nhận thả, `AnimatedSwitcher` đổi tên, vệt mép, đường nối chạy, tick nảy, chấm live nhấp nháy, thẻ hiện lần lượt, nhấn thu nhẹ, chỉ báo vòng. Tiêu chí: `flutter test --no-pub test/features/bracket_motion_test.dart` → exit 0 (TC-BRK-MOT-01 đổi tên trượt trong 200ms rồi ổn định; 02 giảm chuyển động đổi ngay, không có `SlideTransition`/`FadeTransition` đang chạy; 03 chấm live chỉ khi live và đứng yên khi giảm chuyển động; 04 hủy giữa chừng không để ô bị khóa)
  - Files: sửa `lib/features/bracket/widgets/playoff_bracket_board.dart`, `lib/features/bracket/widgets/bracket_slot_row.dart`, `lib/features/bracket/widgets/playoff_double_elim_view.dart`; test `test/features/bracket_motion_test.dart`
  - Giao: (không) · Nhận: bản đã xong của 1.1, 3.1, 4.1
  - Chủ file chung: không (làm tuần tự sau các task giữ file)
  - Phụ thuộc: sau 3.1, 4.1, 1.1

## 6. Dọn bản cũ
- [ ] 6.1 Xóa `single_elim_diagram.dart`, `double_elim_diagram.dart`, `bracket_match_card.dart`; giữ `team_row.dart` (còn `match_card_detail.dart`, `club_activity_tab.dart` dùng); sửa `public_bracket_view_test.dart` bỏ import cũ. Tiêu chí: `grep -rE "SingleElimDiagram|DoubleElimDiagram|BracketMatchCard" lib test` → không có kết quả; `flutter analyze --no-pub lib/features/bracket` → exit 0
  - Files: xóa ba file trên; sửa `test/features/public_bracket_view_test.dart`, `test/features/tournament_bracket_inline_layout_test.dart` nếu còn import
  - Phụ thuộc: sau 4.2

## 7. Kiểm
- [ ] 7.1 `flutter analyze --no-pub lib/features/bracket` + `flutter test --no-pub` các file: `bracket_slot_row_test`, `bracket_match_tap_test`, `bracket_edge_pager_test`, `playoff_match_card_edit_test`, `playoff_match_card_test`, `playoff_double_elim_view_test`, `playoff_double_elim_view_edit_test`, `bracket_motion_test`, `public_bracket_view_test`, `tournament_bracket_inline_layout_test`, `bracket_view_embedded_test`, `organizer_bracket_inline_test`, `bracket_holding_tray_test` → exit 0
  - Phụ thuộc: sau 6.1
- [ ] 7.2 Xem trên điện thoại: kéo thả đổi chỗ, kéo tới mép lật trang, chuyển động mượt, giảm chuyển động. Tiêu chí: người dùng xác nhận trên máy thật (cần máy kết nối lại; không báo xong nếu chưa xem)
  - Phụ thuộc: sau 7.1
