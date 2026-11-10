## ADDED Requirements

### Requirement: Hành trình dựng giải, nội dung thi đấu và VĐV
Bộ test SHALL đi từ tạo giải nhanh tới nội dung thi đấu và danh sách VĐV bằng giao diện App với Backend thật, bấm từng nút của các khu này và kiểm kết quả trên Backend.

#### Scenario: Tạo giải rồi thêm và sửa nội dung thi đấu
- **WHEN** Ban tổ chức tạo giải nhanh, mở tab Nội dung, thêm một nội dung rồi sửa thể thức qua `DivisionEditorSheet`
- **THEN** `GET /tournaments/:id/divisions` trả nội dung với `bracketType` đã sửa

#### Scenario: Thêm VĐV và xử lý đơn
- **WHEN** Ban tổ chức thêm VĐV bằng `AddAthleteSheet`, mở `ParticipantDetailSheet` và duyệt một đơn, từ chối một đơn
- **THEN** `GET /tournaments/:id/participants` có đúng số VĐV và trạng thái COMPLETE hoặc REJECTED tương ứng

### Requirement: Hành trình vận hành giải tới kết thúc
Bộ test SHALL đi theo vòng đời công bố, đăng ký, khai mạc, bốc thăm, nhập điểm, kết thúc và trang công khai.

#### Scenario: Khai mạc, bốc thăm và nhập điểm inline
- **WHEN** Ban tổ chức khai mạc giải, bốc thăm, mở tab Kết quả và nhập điểm trận đầu trong `results-score-sheet` rồi bấm Lưu
- **THEN** `PATCH /matches/:id/score` thành công và trận hiển thị đã hoàn tất

#### Scenario: Kết thúc giải và xem công khai
- **WHEN** mọi trận hoàn tất và Ban tổ chức xác nhận ở `LifecycleEndSheet`
- **THEN** `GET /tournaments/:id` trả COMPLETED và trang công khai `/tournament/:id` hiện nhà vô địch

### Requirement: Hành trình thể thức thi đấu
Bộ test SHALL kiểm vòng tròn, loại kép, vòng bảng và Swiss qua các nút có key, bao gồm hoàn tác Swiss và vận hành giai đoạn.

#### Scenario: Phân bảng và ghép cặp Swiss
- **WHEN** Ban tổ chức lưu phân bảng (`save-assignment`) hoặc ghép cặp Swiss vòng 1 (`swiss-next-round`) rồi hoàn tác (`swiss-undo-round`)
- **THEN** sơ đồ do Backend trả về có các trận của bảng hoặc vòng đó, và sau hoàn tác vòng bị bỏ

### Requirement: Hành trình lịch thi đấu và cài đặt
Bộ test SHALL kiểm sân, khung giờ, xếp lịch, nhà tài trợ, trọng tài, tài chính, chia sẻ, xuất dữ liệu và xóa giải.

#### Scenario: Tạo sân và xếp lịch một trận
- **WHEN** Ban tổ chức thêm sân qua `venue-dialog-submit` rồi xếp lịch một trận
- **THEN** `GET /tournaments/:id/venues` có sân mới và trận có sân, giờ đã chọn

#### Scenario: Xóa giải cần gõ lại tên
- **WHEN** Ban tổ chức bấm `lifecycle-delete`, gõ tên giải vào `delete-tournament-name` và xác nhận
- **THEN** giải không còn truy cập được qua `GET /tournaments/:id`

### Requirement: Test không được xanh giả
Mỗi test trong bốn file SHALL dùng `expect` hoặc chờ có hạn mà thất bại khi thiếu dữ liệu, và KHÔNG bọc kiểm tra trong `if (finder.evaluate().isNotEmpty)`.

#### Scenario: Thiếu dữ liệu thì đỏ
- **WHEN** một widget cần thiết không xuất hiện trong thời gian chờ
- **THEN** test thất bại với thông báo nêu widget và bước đang làm

#### Scenario: Nút không thao tác được trên emulator
- **WHEN** một nút phụ thuộc file picker hoặc thanh toán ngoài App
- **THEN** test kiểm nút tồn tại và mở được, ghi rõ lý do không đi tiếp, không im lặng bỏ qua
