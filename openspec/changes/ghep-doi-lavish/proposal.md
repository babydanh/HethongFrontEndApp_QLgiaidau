## Why

Popup "Ghép đôi" và hộp "Tự ghép" còn kiểu Material cũ: chân popup xếp ba nút dính nhau, nhiều chữ hướng dẫn (mô tả, gợi ý từng cách ghép) mà người tổ chức không cần.

## What Changes

- `PairingSheet`: bỏ dòng mô tả; hai tab thành chip Lavish; ô tìm, hàng VĐV, ô đặt tên đôi dùng kiểu Lavish; bỏ chữ "Đang chờ ghép" lặp trên mọi hàng.
- Chân popup gọn một hàng hai nút (Xếp ngẫu nhiên · Ghép N đôi), bỏ nút "Hủy" (đã có ✕).
- Cách ghép tự động chỉ còn nhãn ngắn: Ngẫu nhiên · Cân bằng · Cùng trình; bỏ câu hướng dẫn và gợi ý từng cách. Hộp "Tự ghép" dùng chung bộ chọn này.

## Out of scope

- Logic ghép, kéo thả, Backend, số chiến lược (vẫn 3).

## Capabilities

### New Capabilities
- `pairing-sheet-lavish`: bố cục và lượng chữ của popup ghép đôi và hộp tự ghép.

### Modified Capabilities
(không)

## Impact

- `lib/features/tournament/widgets/pairing_sheet.dart`, `pairing_strategy_picker.dart` (mới), `tournament_manage_sheet.dart` (thêm tham số `footer`), `tournament_management_athletes_tab.dart` (`_AutoPairDialog`)
- `lib/l10n/app_vi.arb`, `app_en.arb` (+ file sinh)
- `test/features/pairing_sheet_test.dart`, `test/features/athletes_tab_actions_test.dart`
