## Why
Sơ đồ toàn màn hình (mở từ nút phóng to) vẫn dùng thẻ trận kiểu cũ: không tô bên thắng, không nhãn "Miễn đấu", không header mã trận · sân · LIVE · giờ, còn footer chữ. Khác hẳn thẻ trong tab Bảng đấu.

## What Changes
- Tách phần dùng chung của thẻ (header, hàng một bên + điểm từng set) sang `bracket_card_parts.dart`; thẻ trong tab và thẻ toàn màn hình cùng dùng.
- `BracketMatchCard` viết lại theo thiết kế mới: bên thắng nền nhạt + dấu tick + điểm màu chính; bên trống "Miễn đấu"/"N/A"; header mã · sân, LIVE, giờ; bỏ footer. Giữ kéo thả ô, chạm ô, chạm đúp, chạm header mở nhập điểm.
- Chiều cao thẻ trong sơ đồ đơn/đôi loại bỏ hằng cứng, theo `bracketCardHeight` (đôi cao hơn).
- Xoá `team_row.dart` (không còn nơi dùng). Không thêm khóa l10n.

## Impact
- `lib/features/bracket/widgets/`: `bracket_card_parts.dart` (mới), `bracket_match_card.dart`, `playoff_bracket_board.dart`, `single_elim_diagram.dart`, `double_elim_diagram.dart`, `team_row.dart` (xoá)
- Test: `bracket_match_card_test.dart` (TC-BMC-01..04), `bracket_holding_tray_test.dart` (đổi test footer → header)
