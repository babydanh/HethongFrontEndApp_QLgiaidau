## ADDED Requirements

### Requirement: Mời nhân sự và trọng tài qua email trong một màn
Màn Phân quyền SHALL có một khối "Mời qua email" gồm ô email, lựa chọn vai trò (Đồng tổ chức, Trọng tài, Khán giả) và một nút gửi; vai trò Trọng tài gửi `POST /tournaments/:id/referees`, hai vai trò còn lại gửi `POST /tournaments/:id/staff`. Nút gửi SHALL bị khoá khi đang gửi để bấm đúp không tạo hai lời mời, và email sai định dạng SHALL bị chặn trước khi gọi API.

#### Scenario: Mời trọng tài bằng email hợp lệ
- **WHEN** BTC nhập email hợp lệ, chọn vai trò Trọng tài và bấm gửi
- **THEN** App gọi `POST /tournaments/:id/referees` đúng một lần, xoá ô email, tải lại danh sách và hiện thông báo đã gửi lời mời

#### Scenario: Email sai định dạng
- **WHEN** BTC bấm gửi với email không có `@` hoặc thiếu tên miền
- **THEN** App không gọi API nào và hiện lỗi nhập liệu

### Requirement: Danh sách lọc theo vai trò kèm trạng thái lời mời
Màn SHALL hiện một danh sách người đã mời, lọc được theo vai trò (Tất cả, Đồng tổ chức, Trọng tài, Khán giả). Dòng trọng tài SHALL hiện trạng thái từ `status` của Backend: Đã mời (`INVITED`), Đã nhận (`ACCEPTED`), Đã từ chối (`DECLINED`); App MUST NOT hiện trạng thái nào ngoài ba giá trị này.

#### Scenario: Lọc theo Trọng tài
- **WHEN** BTC chọn chip Trọng tài
- **THEN** danh sách chỉ còn các dòng trọng tài, mỗi dòng kèm một trong ba trạng thái trên

### Requirement: Gửi lại và Thu hồi lời mời trọng tài như Web
Dòng trọng tài `DECLINED` SHALL có nút Gửi lại (gọi `POST /referees` cùng email); dòng `INVITED` SHALL có nút Thu hồi (gọi `DELETE /referees/:refereeId`); cả hai SHALL hỏi xác nhận trước khi gọi và khoá nút khi đang chạy. Dòng `ACCEPTED` SHALL NOT có hai nút này.

#### Scenario: Gửi lại cho trọng tài đã từ chối
- **WHEN** BTC bấm Gửi lại ở dòng Đã từ chối rồi xác nhận
- **THEN** App gọi `POST /tournaments/:id/referees` với email của dòng đó đúng một lần và tải lại danh sách

#### Scenario: Thu hồi lời mời đang chờ
- **WHEN** BTC bấm Thu hồi ở dòng Đã mời rồi xác nhận
- **THEN** App gọi `DELETE /tournaments/:id/referees/:refereeId` và dòng biến mất sau khi tải lại

#### Scenario: API lỗi
- **WHEN** lời gọi mời, gửi lại hoặc thu hồi thất bại do mạng hoặc Backend
- **THEN** App giữ nguyên danh sách, hiện thông báo lỗi chung, không lộ nội dung lỗi kỹ thuật, và mở lại nút để thử lại

### Requirement: Không còn màn Mã truy cập
App SHALL NOT còn lối vào nào dẫn tới màn quản lý mã truy cập theo vai trò: không mục menu trong hub quản lý, không route `tokens` dưới `manage`/`lite-manage`.

#### Scenario: Menu quản lý
- **WHEN** BTC mở hub quản lý giải
- **THEN** danh sách mục không có "Mã truy cập" và điều hướng tới `.../tokens` không khớp route nào
