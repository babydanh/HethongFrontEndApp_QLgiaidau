## Why

Tab "Nội dung" của hub quản lý giải bị rối: tiêu đề lặp tên tab, khung lồng khung, nhiều nút, mỗi hàng ghi cả câu ("Đôi · Loại trực tiếp · Số người tham gia tối đa: 16", "Đã đóng đăng ký") trong khi tên nội dung đã nói rõ thể loại.

## What Changes

- Bỏ tiêu đề/phụ đề và khung bọc ngoài; header chỉ còn một nút chính "Thêm nội dung" và menu ⋮ chứa "Đăng ký" hàng loạt.
- Hàng nội dung phẳng: tên + dải icon (loại sơ đồ, số người tối đa kèm số, khoá khi đã đóng đăng ký, mở khoá khi mở không hạn). Tên từng icon nằm ở tooltip và nhãn Semantics.
- Nhóm hàng theo thể loại (Đơn / Đôi / Đôi hỗn hợp) bằng nhãn nhỏ kèm số lượng, chỉ khi có từ 2 nhóm; số người hiển thị dạng đã đăng ký/tối đa; từ 9 nội dung trở lên có ô tìm theo tên.
- Bấm cả hàng để sửa; menu ⋮ giữ các thao tác còn lại.

## Out of scope

Phần "Hạt giống" bên dưới; luồng API; màn công khai.

## Capabilities

### New Capabilities
- `division-list-flat`: danh sách nội dung phẳng, meta bằng icon.

### Modified Capabilities

## Impact

`lib/features/tournament/screens/tournament_management_divisions_section.dart`, `lib/l10n/app_vi.arb`, `app_en.arb` (2 khoá tìm kiếm), test `tournament_management_divisions_section_test.dart`.
