## ADDED Requirements

### Requirement: Quản lý camera của giải trên App
Màn Livestream của quản lý giải SHALL quản lý camera như Web: thêm camera (tên bắt buộc, chọn sân, chế độ PUSH đẩy stream hoặc PULL URL phát), sửa/xoá camera (không xoá khi đang LIVE nếu Backend chặn — hiển thị nguyên lỗi), đổi sân gắn camera qua chọn hoặc kéo-thả camera vào thẻ sân; các thao tác gọi đúng route camera mà Web đang dùng.

#### Scenario: Thêm camera PUSH
- WHEN BTC nhập tên "Sân 1 - Điện thoại" chọn chế độ PUSH và sân 1
- THEN App tạo camera thành công, thẻ camera hiện badge PUSH

#### Scenario: Đổi sân bằng kéo-thả
- WHEN BTC kéo thẻ camera thả vào thẻ sân 3
- THEN camera được gắn sân 3 sau khi App ghi và lưới sân làm mới

#### Scenario: Backend từ chối vì đang LIVE
- WHEN BTC xoá camera đang phát và Backend trả lỗi
- THEN App hiển thị nguyên văn lỗi và không bỏ camera khỏi danh sách

### Requirement: Stream key dạng QR với issue/rotate/rename
Màn Livestream SHALL hiện stream key của camera PUSH dạng QR + chuỗi key có nút che/hiện; hỗ trợ cấp key (tự động khi cần hoặc thủ công), đổi tên stream, và rotate key (confirm vì cắt stream đang chạy) gọi đúng route livestream mà Web dùng. App MUST NOT ghi stream key ra log.

#### Scenario: Xem QR stream key
- WHEN BTC bấm QR trên camera PUSH chưa có key
- THEN App tự cấp key và hiển thị QR; key bị che mặc định, bấm mới hiện

#### Scenario: Rotate key
- WHEN BTC bấm "Đổi key" và xác nhận cảnh báo ngắt stream
- THEN App gọi rotate, QR mới hiển thị, key cũ không còn dùng được

#### Scenario: Camera PULL không có key
- WHEN BTC mở camera PULL
- THEN không hiện nút QR/stream key
