## ADDED Requirements

### Requirement: Popup Thêm VĐV mở ở tab Nhập tên
Popup SHALL mở ở tab "Nhập tên" và SHALL đặt chip "Nhập tên" trước chip "Bạn bè & CLB"; riêng giải bóng đá SHALL giữ tab tài khoản vì không có tab nhập tên.

#### Scenario: Mở popup
- **WHEN** mở popup Thêm VĐV của giải không phải bóng đá
- **THEN** ô "Tên vận động viên" hiện ngay, ô tìm kiếm chưa hiện và chip "Nhập tên" nằm bên trái chip "Bạn bè & CLB"

### Requirement: Ô nhập tay đồng đều
Các ô Tên, Email, SĐT, Điểm và Loại điểm SHALL có cùng chiều cao; ô Điểm và ô Loại điểm SHALL rộng bằng nhau; các ô SHALL NOT hiện bộ đếm ký tự.

#### Scenario: Đo kích thước
- **WHEN** mở tab Nhập tên
- **THEN** năm ô có chiều cao bằng nhau và Điểm rộng bằng Loại điểm
