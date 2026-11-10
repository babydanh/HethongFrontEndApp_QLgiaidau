## ADDED Requirements

### Requirement: Hộp thoại địa điểm theo kiểu Web
Hộp thoại thêm/sửa địa điểm SHALL giữ header và nút hành động cố định, chỉ phần ô nhập cuộn, và SHALL chỉ cho bấm Thêm/Lưu khi Tên và Địa chỉ đều không rỗng sau khi cắt khoảng trắng.

#### Scenario: Thiếu tên hoặc địa chỉ
- **WHEN** Tên hoặc Địa chỉ còn trống
- **THEN** nút Thêm/Lưu bị khóa và không tạo địa điểm

#### Scenario: Bàn phím mở
- **WHEN** bàn phím chiếm phần dưới màn hình
- **THEN** nút Thêm/Lưu vẫn nằm phía trên bàn phím

#### Scenario: Đóng không lưu
- **WHEN** người dùng bấm nút đóng hoặc Hủy
- **THEN** không tạo địa điểm
