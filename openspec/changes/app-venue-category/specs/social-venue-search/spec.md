## ADDED Requirements

### Requirement: Tìm sân theo môn đang chọn
Khi tạo/sửa buổi giao lưu, App SHALL gửi `categoryId` của môn đang chọn tới `GET /social-locations/search`, và SHALL không gửi tham số này khi chưa có môn; App SHALL vẫn chạy khi phản hồi thiếu `isVerified`.

#### Scenario: Có môn
- **WHEN** người dùng gõ từ 3 ký tự tìm sân với môn có `id`
- **THEN** request chứa `categoryId=<id>`

#### Scenario: Không có môn hoặc server cũ
- **WHEN** không có `categoryId`, hoặc phản hồi không có `isVerified`
- **THEN** request không có `categoryId`, kết quả hiển thị như trước và `isVerified = false`

#### Scenario: Đổi môn giữa chừng
- **WHEN** người dùng đổi môn khi đang tìm
- **THEN** kết quả của lần tìm cũ bị bỏ và tìm lại với môn mới
