## Why

Nút "+" nổi ở góc dưới (change `noi-dung-the`) không thấy được trên máy người dùng: nằm ngoài vùng nhìn, hoặc bị che bởi lớp nổi của máy. Người dùng muốn nút thêm nội dung nằm ở cuối danh sách.

## What Changes

- Bỏ nút "+" nổi và lớp mờ trắng ở đáy trang.
- Thêm một ô "+ Thêm nội dung" (viền nét liền, chữ màu chính) làm mục cuối của danh sách, ngay dưới thẻ nội dung cuối cùng, trên phần "Hạt giống".

## Out of scope

Thẻ nội dung, menu ⋮, luồng tạo nội dung, phần "Hạt giống".

## Capabilities

### New Capabilities
- `division-add-tile`: ô thêm nội dung ở cuối danh sách.

### Modified Capabilities

## Impact

`lib/features/tournament/screens/tournament_management_divisions_section.dart`, test `tournament_management_divisions_section_test.dart`. Sửa nhẹ `openspec/changes/noi-dung-the/` để không mâu thuẫn.
