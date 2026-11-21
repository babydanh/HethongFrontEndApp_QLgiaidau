# Spec Delta

## Purpose

Cho phép người dùng App tạo và xem trận đấu bắt cặp ngay trong một buổi Social đã gắn CLB, tái dùng đúng logic ghép đội thủ công và API đang phục vụ tính năng tương đương trong CLB.

## ADDED Requirements

### Requirement: Tab "Trận đấu" chỉ hiện khi buổi gắn CLB
Màn chi tiết buổi Social (`social_detail_screen.dart`) SHALL hiển thị thêm tab "Trận đấu" chỉ khi `session.communityId` khác rỗng, đặt sau tab Người tham gia.

#### Scenario: Buổi gắn CLB có tab Trận đấu
- **WHEN** người dùng mở chi tiết một buổi Social có `communityId`
- **THEN** TabController hiển thị thêm tab "Trận đấu" bên cạnh Chi tiết/Người tham gia/[Thanh toán]/Trò chuyện

#### Scenario: Buổi cá nhân không có tab Trận đấu
- **WHEN** người dùng mở chi tiết một buổi Social không có `communityId`
- **THEN** TabController không hiển thị tab "Trận đấu"

### Requirement: Xem danh sách trận đã tạo cho buổi
Tab "Trận đấu" SHALL hiển thị các trận `club_standalone_matches` cùng `communityId` với buổi, kèm trạng thái (đã lên lịch/đã hoàn thành).

#### Scenario: Buổi đã có trận
- **WHEN** đã có ít nhất 1 trận được tạo cho `communityId` của buổi
- **THEN** tab hiển thị danh sách trận kèm trạng thái và kết quả nếu đã hoàn thành

#### Scenario: Buổi chưa có trận nào
- **WHEN** chưa có trận nào được tạo cho `communityId` của buổi
- **THEN** tab hiển thị trạng thái rỗng rõ ràng kèm nút "Tạo trận đấu"

### Requirement: Tạo trận mới ghép đội thủ công từ người tham gia đã duyệt
Nút "Tạo trận đấu" SHALL mở lại đúng luồng `ClubStandaloneMatchDialog` (chạm avatar gán Đội A/Đội B), nhưng danh sách người để chọn mặc định là người tham gia đã duyệt của buổi Social thay vì toàn bộ thành viên CLB; gọi `POST /club-match-sessions/standalone-matches` với `communityId` lấy từ buổi.

#### Scenario: Tạo trận đôi thành công từ người tham gia buổi
- **WHEN** người dùng chọn đủ 2 người Đội A, 2 người Đội B từ danh sách người tham gia buổi và xác nhận
- **THEN** hệ thống gọi đúng `POST /club-match-sessions/standalone-matches`, trận mới xuất hiện trong danh sách của tab

#### Scenario: Buổi chưa đủ người tham gia đã duyệt để ghép đội
- **WHEN** buổi có ít hơn 2 người tham gia đã duyệt
- **THEN** hệ thống vẫn cho mở dialog nhưng hiển thị rõ không đủ người, không cho bấm "Tạo trận đấu"

### Requirement: Nhập kết quả trận
Hệ thống SHALL cho nhập điểm set và xác định bên thắng qua `POST /club-match-sessions/matches/:matchId/complete`, dùng lại `ClubStandaloneMatchResultDialog`.

#### Scenario: Nhập kết quả hợp lệ
- **WHEN** người dùng nhập số set thắng khác nhau cho hai bên và xác nhận
- **THEN** hệ thống gọi đúng endpoint complete, trận trong danh sách chuyển trạng thái đã hoàn thành

#### Scenario: Nhập điểm hòa không hợp lệ
- **WHEN** người dùng nhập số set thắng bằng nhau cho hai bên
- **THEN** hệ thống chặn gửi và báo lỗi "phải có người thắng", không gọi API complete
