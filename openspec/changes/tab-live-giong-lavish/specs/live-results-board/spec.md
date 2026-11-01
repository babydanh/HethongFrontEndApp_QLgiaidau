## ADDED Requirements

### Requirement: Bảng trận khớp mockup Lavish
Bảng trận SHALL hiển thị chip lọc có số đếm, ô tìm kèm nút "Tới vòng", đầu hộp dạng pill, hàng trận có chấm đỏ cho trận live và dòng "vs", và avatar màu theo tên như Web.

#### Scenario: Chip có số đếm
- **WHEN** hạng mục có 1 trận đang đấu, 1 sắp tới, 1 đã xong
- **THEN** các chip hiện "Đang đấu 1", "Sắp tới 1", "Đã xong 1"

#### Scenario: Trận chưa có đối thủ
- **WHEN** một bên chưa có VĐV và có đúng một trận nguồn dẫn tới trận này
- **THEN** bên đó hiện "Chờ đội thắng" kèm mã trận nguồn

#### Scenario: Avatar màu theo tên
- **WHEN** VĐV không có ảnh
- **THEN** avatar tròn dùng màu cố định theo tên và chữ cái đầu cùng chữ cái cuối của tên
