# tournament-view-access Specification

## Purpose
Luật App dùng ở màn giới thiệu giải để quyết định người dùng có được xem giải hay không, khớp với luật `visibility` của Backend: công tắc công khai/nội bộ của giải là nguồn sự thật duy nhất cho việc xem.

## Requirements

### Requirement: Chỉ giải riêng tư mới chặn người ngoài
Màn giới thiệu giải SHALL cho mọi người xem giải có `visibility` khác `PRIVATE`, kể cả giải thuộc CLB (có `communityId`) và giải CLB lite. Với giải `PRIVATE`, App SHALL chỉ cho xem khi người dùng là người tạo giải, admin, hoặc thành viên CLB của giải ở trạng thái hợp lệ như hiện nay; người khác thấy màn chặn hiện có. App MUST NOT dùng `communityId` hay loại giải CLB làm điều kiện chặn xem.

#### Scenario: Khách xem giải CLB công khai
- **WHEN** người không phải thành viên CLB mở màn giới thiệu của một giải có `communityId` và `visibility = PUBLIC`
- **THEN** App hiện nội dung giải, không hiện màn chặn

#### Scenario: Khách xem giải CLB nội bộ
- **WHEN** người không phải thành viên CLB, không phải người tạo, không phải admin mở màn giới thiệu của giải có `communityId` và `visibility = PRIVATE`
- **THEN** App hiện màn chặn hiện có

#### Scenario: Thành viên CLB xem giải nội bộ
- **WHEN** thành viên CLB ở trạng thái `JOINED` mở giải `PRIVATE` của CLB đó
- **THEN** App hiện nội dung giải

#### Scenario: Backend từ chối dù App không chặn
- **WHEN** App không chặn nhưng Backend trả 403 hoặc 404 khi tải giải
- **THEN** App hiện trạng thái lỗi hoặc không tìm thấy hiện có, không hiện nội dung giải
