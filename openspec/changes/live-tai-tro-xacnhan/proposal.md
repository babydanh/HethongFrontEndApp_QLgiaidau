## Why

Ba màn quản lý giải của BTC (Nhà tài trợ, Livestream, Kết quả giải) được thiết kế lại trên Lavish. Người dùng đã ra lệnh làm; không chờ duyệt.

## What Changes

- Màn 12 Nhà tài trợ: hàng gọn (tay kéo, avatar chữ cái, tên, hạng, nhãn lưu trữ, công tắc hiển thị), kéo để sắp xếp thay ô nhập số thứ tự, nút Thêm ở thanh trên, xem trước trang công khai, vuốt trái để lưu trữ.
- Màn 11 Livestream: khối Camera (số lượng, loại, sân, trạng thái, nút QR có hộp xác nhận trước khi hiện khoá phát), khối Sân (gán/đổi camera bằng chip chọn).
- Màn 7 Kết quả giải: sheet hoàn tất giải thành "xác nhận kết quả" có bục podium, khối giải thưởng, điều kiện xác nhận, hộp xác nhận nêu hậu quả; chốt lại kết quả (`POST /tournaments/:id/results/confirm`) khi Backend báo `needsReconfirm`.

## Out of scope (API/dữ liệu không có)

- Huy hiệu MVP của nhà tài trợ: Backend và entity không có trường này.
- Lưu thứ tự hàng loạt: Backend chỉ có `PATCH /tournaments/:id/sponsors/:sponsorId` (`displayOrder`), như Web: gọi từng nhà tài trợ đổi vị trí.
- "Bắt đầu phát": `POST /livestream/matches/:matchId/start` chạy theo trận, màn Livestream không có ngữ cảnh trận; không nối.
- Giải thưởng theo hạng (Nhất/Nhì/Ba): entity chỉ có một `prizeDescription` (văn bản giàu định dạng); không có số tiền theo hạng.
- Điều kiện "không còn trận tranh chấp": Backend không có khái niệm tranh chấp trận.

## Capabilities

### New Capabilities

- `app-sponsors-order`: sắp xếp và hiển thị công khai nhà tài trợ.
- `app-livestream-cameras`: gán camera cho sân và mở QR khoá phát có xác nhận.
- `app-results-confirm`: xác nhận kết quả giải.
