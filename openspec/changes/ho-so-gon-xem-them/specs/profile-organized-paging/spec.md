## ADDED Requirements

### Requirement: Giải tôi tổ chức phân trang cursor trên hồ sơ
Khối "Giải tôi tổ chức" SHALL hiện tối đa 4 giải ở lần đầu, tải thêm từng trang 4 giải bằng `nextCursor`, và ẩn nút khi hết.

#### Scenario: Bốn giải đầu
- **WHEN** mở tab Giải đấu và backend còn trang kế
- **THEN** hiện 4 giải và nút "Xem thêm"

#### Scenario: Xem thêm
- **WHEN** bấm "Xem thêm"
- **THEN** trang kế được nối vào, nút bị khoá khi đang tải (không gửi hai request), và ẩn khi `nextCursor` rỗng

#### Scenario: Lỗi mạng
- **WHEN** tải trang kế thất bại
- **THEN** giữ các giải đã tải và nút đổi thành "Thử lại"

#### Scenario: Không tổ chức giải nào
- **WHEN** danh sách rỗng
- **THEN** khối không hiện
