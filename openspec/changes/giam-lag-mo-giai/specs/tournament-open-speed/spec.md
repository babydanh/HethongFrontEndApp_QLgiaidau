## ADDED Requirements

### Requirement: Tải song song dữ liệu phụ của giải
Hệ thống SHALL gửi các request `/divisions` và `/sponsors` cùng lúc với request chi tiết giải, và request `/divisions` cùng lúc với `/participants` khi tải đội, không chờ nhau.

#### Scenario: Mở một giải
- **WHEN** App tải chi tiết một giải
- **THEN** cả ba request được gửi trước khi request nào trả về

### Requirement: Một API phụ lỗi không làm mất nội dung
Hệ thống MUST NOT thay toàn bộ nội dung các tab bằng thông báo lỗi khi chỉ danh sách đội tải lỗi.

#### Scenario: Tải đội lỗi
- **WHEN** `introTeamsProvider` trả lỗi
- **THEN** các tab Tổng quan và Giới thiệu vẫn hiển thị

### Requirement: Thanh tab không nhảy khi dữ liệu trận về
Hệ thống SHALL hiển thị tab Đang diễn ra ngay khi giải đang thi đấu, trước khi danh sách trận tải xong.

#### Scenario: Giải đang thi đấu, trận chưa về
- **WHEN** giải ở trạng thái đang thi đấu và luồng trận chưa phát
- **THEN** tab Đang diễn ra đã có mặt và không kèm chấm đỏ

### Requirement: Luồng trận bỏ qua sự kiện của giải khác
Hệ thống SHALL NOT tải lại danh sách trận của một giải khi sự kiện socket mang `tournamentId` khác.

#### Scenario: Sự kiện giải khác
- **WHEN** nhận sự kiện điểm với `tournamentId` khác giải đang xem
- **THEN** không có request tải lại nào được gửi
