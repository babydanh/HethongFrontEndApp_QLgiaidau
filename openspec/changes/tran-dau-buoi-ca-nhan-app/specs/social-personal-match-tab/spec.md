## ADDED Requirements

### Requirement: Tab Trận đấu cho buổi Social cá nhân
Màn chi tiết buổi Social trên App MUST hiện tab "Trận đấu" cho mọi buổi, kể cả buổi không gắn CLB. Với buổi không gắn CLB, danh sách trận MUST lấy theo `socialSessionId` của buổi.

#### Scenario: Buổi cá nhân có tab Trận đấu
- **WHEN** người dùng mở một buổi Social không có `communityId`
- **THEN** màn chi tiết hiện tab "Trận đấu" và danh sách chỉ gồm các trận của buổi đó

#### Scenario: Buổi gắn CLB không đổi
- **WHEN** người dùng mở một buổi Social có `communityId`
- **THEN** tab "Trận đấu" hoạt động như trước (danh sách theo `communityId`, quyền tạo theo vai trò CLB)

### Requirement: Chỉ host tạo trận cho buổi cá nhân
Với buổi không gắn CLB, nút "Tạo trận" MUST chỉ bật cho host của buổi, và người chơi chọn được MUST là người tham gia đã duyệt của buổi.

#### Scenario: Host tạo trận
- **WHEN** host buổi cá nhân có từ 4 người tham gia đã duyệt bấm "Tạo trận" và chọn hai đội 2v2
- **THEN** App gửi `socialSessionId` (không gửi `communityId`), trận được tạo không tính ELO và mở hộp nhập kết quả

#### Scenario: Người không phải host
- **WHEN** người dùng không phải host xem tab Trận đấu của buổi cá nhân
- **THEN** nút "Tạo trận" bị tắt, vẫn xem được danh sách trận
