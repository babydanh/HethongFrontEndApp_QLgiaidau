## ADDED Requirements

### Requirement: Thẻ trận hiển thị avatar và tỉ số
Thẻ trận trong tab Trận đấu của buổi giao lưu SHALL hiển thị mỗi người chơi với avatar tròn (ảnh, hoặc chữ viết tắt trên nền màu theo tên) và tỉ số của từng bên; bên thắng của trận đã xong SHALL được in đậm.

#### Scenario: Người chơi không có ảnh
- **WHEN** một người chơi không có `avatarUrl`
- **THEN** avatar hiện chữ viết tắt từ `avatarInitials(tên)`

### Requirement: Hai nút vào nhập điểm cho trận chưa xong
Thẻ của trận chưa xong SHALL có nút "Nhập nhanh" mở hộp nhập kết quả và nút "Bấm điểm" mở bảng điểm trực tiếp; thẻ của trận đã xong MUST NOT có hai nút này.

#### Scenario: Trận chưa xong
- **WHEN** trận có trạng thái khác `COMPLETED` và người xem đã đăng nhập
- **THEN** thẻ hiện cả hai nút

#### Scenario: Trận đã xong
- **WHEN** trận có trạng thái `COMPLETED`
- **THEN** thẻ không có nút nào; chạm thẻ vẫn mở hộp xem kết quả
