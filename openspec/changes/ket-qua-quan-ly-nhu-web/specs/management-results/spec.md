## ADDED Requirements

### Requirement: Hub quản lý có tab Kết quả
Hub quản lý giải SHALL có thêm tab "Kết quả" đặt sau các tab hiện có, hiển thị bảng trận theo vòng với quyền quản lý (nhập điểm, nhập giờ) cho người đã vào được hub.

#### Scenario: Mở tab Kết quả
- **WHEN** ban tổ chức mở hub quản lý và bấm tab "Kết quả"
- **THEN** app hiện dải chọn hạng mục và bảng trận gồm hộp "Đang đấu" (nếu có) và một hộp cho mỗi vòng
- **AND** các tab cũ vẫn ở đúng vị trí và vẫn mở đúng nội dung

#### Scenario: Giải chưa có trận
- **WHEN** giải chưa có trận nào
- **THEN** tab hiện thông báo "Chưa có trận nào." và không báo lỗi

### Requirement: Bộ lọc của bảng trận đủ như Web
Bảng trận SHALL có bảy chip lọc: Tất cả, Đang diễn ra, Sắp tới, Đã kết thúc, Chưa xong, Trễ giờ, Tranh chấp; mỗi chip kèm số trận theo cùng luật đếm của Web, và bảng SHALL cho phép mở sẵn một chip từ nơi gọi.

#### Scenario: Chip Tranh chấp
- **WHEN** giải có 2 trận ở trạng thái tranh chấp và ban tổ chức bấm chip "Tranh chấp"
- **THEN** chip hiện số 2 và bảng chỉ liệt kê đúng 2 trận đó

#### Scenario: Mở sẵn một bộ lọc
- **WHEN** nơi khác yêu cầu mở tab Kết quả với bộ lọc "Trễ giờ"
- **THEN** tab mở với chip "Trễ giờ" đang chọn
