## Why

Tab "Nội dung" sau `noi-dung-gon` vẫn còn nhãn nhóm "ĐƠN · 1" / "ĐÔI · 1", nút "Thêm nội dung" nằm trên đầu, và các hàng dính liền nhau. Người dùng muốn mỗi nội dung là một thẻ tách khung, bấm mở ra có animation và đủ thông tin, nút thêm là dấu "+" nổi ở cuối trang.

## What Changes

- Bỏ nhãn nhóm ĐƠN/ĐÔI; mỗi nội dung là một thẻ viền riêng, cách nhau 8dp.
- Bấm thẻ để mở (AnimatedSize 220ms), một thẻ mở tại một thời điểm. Thẻ mở hiện: Thể loại, Thể thức, Đã đăng ký, Đăng ký (mở/đóng/hạn), ELO (nếu có), Phí riêng (nếu có).
- Nút sửa (icon bút) và menu ⋮ nằm ngay trên hàng của thẻ, không cần mở thẻ. Menu gồm cấu hình vòng, khoá/mở khoá, mở lại có hạn, đăng ký hàng loạt, xoá.
- Bỏ menu ⋮ phía trên danh sách (mục đăng ký hàng loạt chuyển vào menu ⋮ của thẻ). Nút thêm: xem change `noi-dung-them-cuoi`.
- Thêm 5 khoá l10n cho nhãn thông tin trong thẻ.

## Out of scope

Phần "Hạt giống" bên dưới; luồng API; màn công khai.

## Capabilities

### New Capabilities
- `division-card-list`: danh sách nội dung dạng thẻ tách khung, mở ra xem đủ thông tin.

### Modified Capabilities

## Impact

`lib/features/tournament/screens/tournament_management_divisions_section.dart`, `lib/l10n/app_vi.arb`, `app_en.arb` (+ code sinh `app_localizations*.dart`), test `tournament_management_divisions_section_test.dart` và `stage_round_config_sheet_test.dart` (menu cấu hình vòng nay nằm trong thẻ, cần mở thẻ trước).
