## Why
Hộp thoại "Thêm địa điểm" ở App là `AlertDialog` thô: bàn phím che nút Lưu, nút Lưu bấm được khi còn trống. Web đã có modal gọn, đẹp (tiêu đề + icon, nhãn trên ô nhập, dấu * bắt buộc, khối sân, nút Thêm nổi bật). App cần theo Web.

## What Changes
- Thay `AlertDialog` của `_VenueDialog` bằng `Dialog` bo 20: header (ô icon + tiêu đề + nút đóng), phần nhập cuộn được, footer cố định (Hủy / Thêm hoặc Lưu).
- Nhãn đặt trên ô nhập, dấu * đỏ cho Tên và Địa chỉ; số sân + tiền tố + "đặt làm mặc định" gom trong một thẻ nền nhạt (chỉ khi thêm mới).
- Nút Thêm/Lưu bị khóa cho tới khi Tên và Địa chỉ đều có chữ.
- Không thêm khóa l10n, không đổi dữ liệu gửi lên API.

## Impact
- `lib/features/tournament/screens/tournament_management_venues_section.dart` (`_VenueDialogState`)
- `test/features/tournament_management_venues_section_test.dart` (TC-VENUE-DLG-01..03)
