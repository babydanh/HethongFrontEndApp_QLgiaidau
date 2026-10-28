## ADDED Requirements

### Requirement: Thanh bước vòng đời
Thẻ vòng đời SHALL hiện thanh 5 bước Nháp, Xuất bản, Mở ĐK, Đang đấu, Kết thúc với bước hiện tại được đánh dấu và đúng một nút hành động cho bước kế tiếp.

#### Scenario: Giải đang mở đăng ký
- **WHEN** giải ở trạng thái mở đăng ký
- **THEN** bước "Mở ĐK" được đánh dấu và nút hành động là "Đóng đăng ký"

### Requirement: Cảnh báo đủ đội
Khi giải đang mở đăng ký và số đội đã duyệt bằng tổng sức chứa, thẻ SHALL hiện cảnh báo "Đã đủ N/N đội" kèm nút Đóng đăng ký.

#### Scenario: Đủ đội
- **WHEN** giải mở đăng ký có 16/16 đội
- **THEN** cảnh báo "Đã đủ 16/16 đội" hiện và bấm Đóng đăng ký chạy đúng hành động đóng đăng ký

### Requirement: Khoá nút Xuất bản khi còn phí
Khi giải ở Nháp và phí công bố lớn hơn 0, nút Xuất bản SHALL bị khoá và hiện lý do; App MUST NOT tự tính hay thay đổi số phí do Backend trả về.

#### Scenario: Còn phí công bố
- **WHEN** giải Nháp có phí công bố 200000
- **THEN** nút Xuất bản vô hiệu và lý do nêu số phí

### Requirement: Xoá giải phải gõ lại tên
Xoá giải SHALL yêu cầu gõ đúng tên giải trước khi nút xác nhận bật.

#### Scenario: Gõ sai tên
- **WHEN** BTC gõ tên khác tên giải
- **THEN** nút Xoá giải vẫn bị vô hiệu
