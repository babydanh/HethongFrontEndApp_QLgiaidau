# Proposal

## Why

Trong màn chi tiết giải, hạng mục có thể thức vòng bảng + playoff hiện chỉ mở sơ đồ loại trực tiếp; người xem không có đường chuyển sang bảng xếp hạng vòng bảng. Tách thành hai tab giúp xem được cả thứ hạng vòng bảng và nhánh playoff ngay trong cùng hạng mục.

## What Changes

- Thêm hai tab con **Bảng** và **Playoff** trong nội dung hạng mục có thể thức vòng bảng + playoff.
- Tab **Bảng** hiển thị thứ hạng vòng bảng; tab **Playoff** giữ sơ đồ loại trực tiếp hiện có.
- Mặc định chọn **Bảng** khi mở hạng mục.
- Các thể thức chỉ có vòng bảng hoặc chỉ có loại trực tiếp giữ nguyên giao diện hiện tại.
- Phạm vi không bao gồm thay đổi cách tạo/lưu trận, API Backend, lịch thi đấu, hoặc giao diện Web.

## Capabilities

### New Capabilities
- `tournament-group-playoff-view`: Xem bảng xếp hạng vòng bảng và sơ đồ playoff qua hai tab trong hạng mục giải.

### Modified Capabilities

## Impact

- App: widget sơ đồ công khai, widget bảng xếp hạng, chuỗi hiển thị trong ARB và test tương ứng.
- Backend API / Web: không ảnh hưởng; không đổi endpoint hay trường dữ liệu.
