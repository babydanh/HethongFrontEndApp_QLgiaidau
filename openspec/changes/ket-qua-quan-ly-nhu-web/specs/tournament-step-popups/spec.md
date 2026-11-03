## ADDED Requirements

### Requirement: Bấm bước tiến trình mở popup chi tiết
Mỗi bước của thanh tiến trình (Đăng ký, Lịch, Đang thi đấu, Kết thúc) SHALL bấm được và mở popup (khung popup chung của quản lý giải) gồm tên bước, trạng thái, vòng phần trăm, hộp "việc cần làm" và phần "Theo từng nội dung".

#### Scenario: Bấm một bước
- **WHEN** ban tổ chức bấm bước "Đăng ký"
- **THEN** popup mở với tiêu đề của bước, số việc cần làm và danh sách việc, mỗi việc có nút "Đi tới"

#### Scenario: Bước đã đủ
- **WHEN** bước không còn việc cần làm
- **THEN** popup hiện "Đã đủ, không còn việc cần làm"

#### Scenario: Chưa tới bước
- **WHEN** ban tổ chức bấm một bước chưa tới
- **THEN** popup hiện "Chưa tới bước này, chưa có việc cần làm" và không có nút xác nhận hay ghi dữ liệu

### Requirement: Số liệu từng bước tính theo luật của Web
Số việc cần làm, trạng thái và phần trăm của từng bước SHALL được tính từ dữ liệu giải, nội dung, VĐV và trận bằng cùng luật với Web, và SHALL không gọi endpoint ghi nào.

#### Scenario: Nội dung chưa có VĐV
- **WHEN** giải có 3 nội dung, trong đó 1 nội dung đã đóng đăng ký nhưng chưa có VĐV
- **THEN** bước "Đăng ký" liệt kê việc "nội dung chưa có VĐV" với số 1 và trạng thái "Thiếu"

#### Scenario: Số liệu đang tải hoặc lỗi
- **WHEN** danh sách VĐV hoặc trận chưa tải xong hoặc tải lỗi
- **THEN** popup hiện "Đang tải số liệu" hoặc nút "Tải lại" thay vì số sai

### Requirement: Đi tới từ popup
Nút "Đi tới" và nút "Mở" của một nội dung SHALL đóng popup rồi đưa ban tổ chức tới đúng tab của hub, kèm bộ lọc hoặc nội dung đã chọn nếu có.

#### Scenario: Đi tới trận trễ giờ
- **WHEN** ở bước "Đang thi đấu" ban tổ chức bấm "Đi tới" ở dòng "trễ giờ"
- **THEN** popup đóng, hub chuyển sang tab "Kết quả" với chip "Trễ giờ" đang chọn
