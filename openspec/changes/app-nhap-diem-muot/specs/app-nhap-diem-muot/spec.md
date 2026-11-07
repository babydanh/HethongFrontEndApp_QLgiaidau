## ADDED Requirements

### Requirement: Điểm vừa bấm không bị bản chụp cũ của server đè lên
Hệ thống SHALL giữ điểm cục bộ khi còn lần bấm chưa gửi, và bỏ mọi bản chụp server có điểm khác cho tới khi lần ghi đó được gửi.

#### Scenario: Bản chụp thiếu lần bấm mới nhất
- **WHEN** người chấm bấm "+" hai lần nhanh và một bản chụp server chỉ có 1 điểm đến trước khi lần ghi thứ hai được gửi
- **THEN** điểm hiển thị vẫn là 2 và không nhảy về 1

#### Scenario: Trận đã kết thúc ở server
- **WHEN** bản chụp server báo trận đã kết thúc
- **THEN** bản chụp được áp dụng như trước

### Requirement: Không có thông báo thành công che nút điểm
Hệ thống SHALL không hiện SnackBar thành công hoặc thông tin trên màn chấm điểm; thông báo lỗi và cảnh báo từ chối thao tác vẫn hiện.

#### Scenario: Đội nhận bấm "+" khi side-out
- **WHEN** đội đang đỡ giao bấm "+" ở pickleball side-out
- **THEN** quyền giao đổi bước, điểm giữ nguyên và không có SnackBar nào hiện

#### Scenario: Ghi phạt
- **WHEN** người chấm gửi một thẻ phạt
- **THEN** phạt được ghi và không có SnackBar thành công
