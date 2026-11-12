## ADDED Requirements

### Requirement: E2E tạo buổi giao lưu và Khám phá
Bộ test SHALL tạo buổi qua form của app trên emulator với Backend thật và kiểm Backend lưu đúng, kể cả lỗi bắt buộc và mốc thời gian ở Khám phá.

#### Scenario: Tạo buổi đôi có phí
- **WHEN** host chọn Đánh đôi, "Quyết định sau", 4 người, phí 50.000 và bấm Tạo kèo
- **THEN** chi tiết buổi mở và Backend có đúng playFormat, maxSlots, feePerSlot, status OPEN

#### Scenario: Thiếu địa điểm
- **WHEN** host bấm Tạo kèo khi chưa chọn địa điểm
- **THEN** app báo "Vui lòng chọn địa điểm" và Backend không tạo buổi

#### Scenario: Một mốc ở Khám phá
- **WHEN** duyệt các ngày từ hôm nay
- **THEN** mỗi buổi và mỗi giải đang mở đăng ký chỉ xuất hiện đúng một lần

### Requirement: E2E chi tiết buổi, người tham gia và quyền
Bộ test SHALL kiểm tab Chi tiết, xin tham gia/rút/duyệt, thêm/xoá người, FULL, avatar host và quyền người ngoài.

#### Scenario: Xin tham gia rồi host duyệt
- **WHEN** người chơi gửi yêu cầu, rút, gửi lại và host duyệt
- **THEN** người chơi thành JOINED và thấy "Đã tham gia"

#### Scenario: Người ngoài
- **WHEN** người không phải host mở buổi
- **THEN** không có nút của host và "Quyết định sau" không gạch chân

### Requirement: E2E trận đấu, trò chuyện, thanh toán, sửa và huỷ
Bộ test SHALL kiểm tạo trận Đôi và Bracket, nhập điểm, gửi tin, thu phí, sửa và huỷ buổi.

#### Scenario: Nhập điểm tới người thắng
- **WHEN** host nhập 11-5 ở bảng Nhập kết quả
- **THEN** thẻ trận Đã hoàn thành và hiện tỉ số

#### Scenario: Buổi đã huỷ
- **WHEN** host huỷ buổi
- **THEN** tab Trò chuyện chỉ đọc và menu ⋮ không còn Sửa/Huỷ
