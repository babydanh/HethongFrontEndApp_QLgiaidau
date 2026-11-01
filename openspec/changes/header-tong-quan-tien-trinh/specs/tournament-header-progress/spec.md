## ADDED Requirements

### Requirement: Thanh tiến trình 4 bước ở đầu trang quản lý giải
Đầu trang quản lý giải SHALL hiện thanh tiến trình 4 bước (Đăng ký, Lịch thi đấu, Đang thi đấu, Kết thúc) theo trạng thái giải như Web, kèm nút hành động của bước hiện tại; trạng thái nháp SHALL hiện thanh mờ không bước nào sáng.

#### Scenario: Giải đang thi đấu
- **WHEN** giải ở trạng thái đang thi đấu
- **THEN** hai bước đầu đánh dấu xong, bước "Đang thi đấu" sáng, bước "Kết thúc" xám và nút kết thúc giải nằm dưới thanh

#### Scenario: Giải nháp
- **WHEN** giải ở trạng thái nháp
- **THEN** không bước nào sáng và nút Công bố nằm dưới thanh

### Requirement: Đầu trang không còn khung 4 ô số
Đầu trang quản lý giải SHALL NOT hiện khung 4 ô số (ngày thi đấu, VĐV, lệ phí, hạn ĐK); lệ phí SHALL hiện ở danh sách tab Tổng quan và bấm vào mở mục Tài chính.

#### Scenario: Mở tab Tổng quan
- **WHEN** người dùng mở trang quản lý giải
- **THEN** không có ô số ở đầu trang và dòng "Lệ phí giải" có trong tab Tổng quan

### Requirement: Logo giải đè lên banner
Trang quản lý giải có banner SHALL hiện logo giải hình tròn đè lên mép dưới banner, dùng ảnh logo của giải hoặc ảnh thay thế khi thiếu.

#### Scenario: Giải có banner
- **WHEN** giải không phải câu lạc bộ rút gọn
- **THEN** logo tròn nằm ở góc trái phía dưới banner
