## Why
Chữ "Miễn đấu" trên thẻ trận là chữ xám nhỏ, lẫn với ô "N/A", khó nhận ra bên nào được miễn đấu.

## What Changes
- Ô BYE của thẻ trận (tab Bảng đấu và sơ đồ toàn màn hình) hiện "Miễn đấu" dạng nhãn màu cam, chữ đậm. Ô trống thường vẫn là "N/A" xám.

## Impact
- `lib/features/bracket/widgets/bracket_card_parts.dart`
- Test: `bracket_match_card_test.dart` (TC-BMC-05)
