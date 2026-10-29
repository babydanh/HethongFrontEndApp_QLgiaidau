## Why
Anh muốn một chỗ chung để chọn và quản lý nội dung thi đấu, như Web: có tab "Nội dung" riêng và mọi màn dùng cùng một dải chip `DivisionStrip`. Lane `division-strip` mới gom 3 màn; hub chưa có tab Nội dung (Quản lý nội dung nằm trong Cài đặt) và Bốc thăm còn dùng dropdown riêng.

## What Changes
- Hub quản lý giải thêm tab "Nội dung" (thứ 2, sau Tổng quan) chứa màn quản lý nội dung có sẵn.
- Chip "Quản lý" ở tab Bảng đấu nhảy sang tab Nội dung.
- Bỏ dòng "Thi đấu" (nội dung) khỏi danh sách Cài đặt vì đã có tab.
- Màn Bốc thăm đổi dropdown chọn nội dung sang `DivisionStrip`.

## Out of scope
- Tab Lịch thi đấu (lưới chưa có lọc nội dung), hộp chọn nội dung của Lite, danh sách nội dung dạng accordion ở các tab công khai (Đội/Bảng đấu/Trực tiếp) và tab VĐV.
- Thanh icon sửa/khoá/xoá khi bấm giữ chip.

## Capabilities
### New Capabilities
- `division-tab`: tab Nội dung trong hub quản lý giải.
### Modified Capabilities
- (không)

## Impact
`tournament_management_hub_screen.dart`, `auto_draw_screen.dart`, l10n (`tournamentManagementTabDivisions`), test hub + Bốc thăm.
