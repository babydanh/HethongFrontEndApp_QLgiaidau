## Why

Tab "Kết quả" chọn hạng mục bằng hàng nút ngang, còn tab "Danh sách đội" và "Bảng đấu" dùng danh sách hạng mục mở/thu. Người dùng muốn tab Kết quả giống tab Danh sách đội (2026-11-10).

## What Changes

- Tab Kết quả (giải nhiều hạng mục) dùng `DivisionAccordion`: bấm hàng để mở/thu, bục vinh danh và bảng trận hiện ngay dưới hàng đang chọn.
- `ResultsMergedTab` có chế độ `inline` (cột thường, không tự cuộn) để đặt trong hàng accordion.
- Bỏ `_buildResultsDivisionStrip` ở màn giới thiệu giải. Màn quản lý giải vẫn dùng `DivisionStrip`.

## Out of scope

- Giải một hạng mục: không đổi. Không đổi nội dung bục vinh danh hay bảng trận.

## Capabilities

### Modified Capabilities
- `tournament-results-tab`: cách chọn hạng mục.
