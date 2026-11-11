## ADDED Requirements

### Requirement: App thêm và gỡ trọng tài trực tiếp
Mục Nhân sự SHALL coi việc thêm trọng tài là "Thêm", SHALL cho gỡ trọng tài `ACCEPTED`, và thông báo `REFEREE_ADDED`/`REFEREE_REMOVED` SHALL không có nút Nhận/Từ chối.

#### Scenario: Gỡ trọng tài đã thêm
- **WHEN** quản lý mở sheet của dòng trọng tài `ACCEPTED` và xác nhận Xóa
- **THEN** App gọi `removeReferee(tournamentId, refereeId)` đúng một lần

#### Scenario: Thông báo được thêm làm trọng tài
- **WHEN** App nhận thông báo `REFEREE_ADDED` có `redirectUrl` `/tournaments/<id>`
- **THEN** `isInvite` là false và `routeTarget` là `/intro/<id>`
