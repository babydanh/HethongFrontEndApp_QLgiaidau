## ADDED Requirements

### Requirement: Khuôn Lavish cho các màn Hồ sơ
Các màn Hồ sơ, Cài đặt, Sửa hồ sơ, Đổi mật khẩu, Báo cáo của tôi, Lịch sử ELO, Thông báo và Dashboard SHALL dựng bằng `LavishScaffold` và các widget Lavish, và SHALL có trạng thái loading (skeleton), rỗng, lỗi kèm nút thử lại.

#### Scenario: Màn tải dữ liệu thất bại
- **WHEN** API của màn trả lỗi mạng hoặc 5xx
- **THEN** màn hiện `LavishErrorState` có nút thử lại và không hiện trạng thái rỗng

#### Scenario: Màn không có dữ liệu
- **WHEN** API trả danh sách rỗng
- **THEN** màn hiện `LavishEmptyState` với icon, tiêu đề ngắn và không hiện lỗi

### Requirement: Đổi mật khẩu đúng hợp đồng Backend
Màn Đổi mật khẩu SHALL gửi `PATCH /users/change-password` với `{oldPassword, newPassword}`.

#### Scenario: Đổi thành công
- **WHEN** người dùng nhập mật khẩu hợp lệ và bấm đổi
- **THEN** App gọi `PATCH /users/change-password` với trường `oldPassword` và `newPassword`, rồi hiện thông báo thành công

### Requirement: Gửi báo cáo đúng route
`ReportSheet` SHALL gửi `POST /users/reports` và SHALL ánh xạ `targetType` về một trong USER, TOURNAMENT, MATCH, COMMUNITY.

#### Scenario: Báo cáo bài viết cộng đồng
- **WHEN** người dùng báo cáo một bài viết cộng đồng
- **THEN** App gửi `POST /users/reports` với `targetType` là COMMUNITY và `targetId` hợp lệ

### Requirement: Lời mời kết bạn đúng route
Màn Hồ sơ SHALL chấp nhận lời mời bằng `PATCH /social/friend-requests/:id` `{action:'ACCEPTED'}`, từ chối bằng `{action:'REJECTED'}`, và hủy kết bạn hoặc hủy lời mời bằng `DELETE /social/friendships/:id`; lỗi SHALL được hiện cho người dùng.

#### Scenario: Từ chối lời mời
- **WHEN** người dùng bấm Từ chối
- **THEN** App gọi `PATCH /social/friend-requests/:id` với `action` là `REJECTED`

#### Scenario: Gọi API thất bại
- **WHEN** API trả lỗi khi chấp nhận, từ chối hoặc hủy
- **THEN** App hiện thông báo lỗi và không đổi danh sách

### Requirement: Thông báo gồm cả phạm vi quản lý
Màn Thông báo SHALL tải cả scope `player` và `management`, số chưa đọc SHALL gồm cả hai, và "đọc tất cả" SHALL áp dụng cho cả hai.

#### Scenario: Có thông báo quản lý
- **WHEN** Backend có thông báo scope `management` chưa đọc
- **THEN** thông báo hiện trong danh sách và được tính vào số chưa đọc

### Requirement: Lịch sử ELO dùng dữ liệu thật
Route `/profile/elo` SHALL truyền ELO hiện tại thật của người dùng, và lỗi tải lịch sử SHALL hiện trạng thái lỗi thay vì danh sách rỗng.

#### Scenario: Lỗi mạng khi tải lịch sử
- **WHEN** `GET /rankings/user/:id/history` lỗi
- **THEN** màn hiện `LavishErrorState` có thử lại

### Requirement: Sửa hồ sơ gửi dữ liệu hợp lệ
Màn Sửa hồ sơ SHALL chỉ gửi số điện thoại khi không rỗng và hợp lệ theo mẫu của Backend (`+84` hoặc `0[35789]` cộng 8 số), và SHALL cho phép xóa giới thiệu và địa chỉ.

#### Scenario: Chưa có số điện thoại
- **WHEN** người dùng chỉ đổi tên và ô số điện thoại trống
- **THEN** payload `PATCH /users/profile` không chứa `phone`

#### Scenario: Xóa giới thiệu
- **WHEN** người dùng xóa hết giới thiệu và lưu
- **THEN** payload chứa `bio` rỗng

### Requirement: Đăng xuất thu hồi phiên
Đăng xuất SHALL gọi `POST /auth/logout` trước khi xóa phiên cục bộ, và vẫn xóa phiên cục bộ nếu cuộc gọi thất bại.

#### Scenario: Đăng xuất khi mất mạng
- **WHEN** `POST /auth/logout` lỗi
- **THEN** phiên cục bộ vẫn bị xóa và App về màn đăng nhập
