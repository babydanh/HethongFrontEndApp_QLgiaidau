# Spec Delta

## Purpose

Một ô hiển thị ngày giờ và một popup chọn ngày giờ dạng cuộn dùng chung cho các màn tạo và cấu hình giải, để mốc thời gian luôn đọc được đủ năm và lỗi thứ tự ngày chỉ đúng ô sai.

## ADDED Requirements

### Requirement: Ô ngày giờ hiển thị đầy đủ và báo lỗi tại chỗ
Ô ngày giờ SHALL hiển thị nhãn nhỏ phía trên, giá trị dạng `dd/MM/yyyy · HH:mm` trên một dòng không cắt chữ, và khi có lỗi SHALL tô viền đỏ ô đó cùng lý do ngay dưới ô.

#### Scenario: Có giá trị
- **WHEN** ô có giá trị 23/10/2026 23:59
- **THEN** ô hiện nhãn phía trên và chữ `23/10/2026 · 23:59` đầy đủ

#### Scenario: Chưa có giá trị
- **WHEN** ô chưa có giá trị
- **THEN** ô hiện chữ gợi ý chọn ngày thay cho giá trị

#### Scenario: Có lỗi
- **WHEN** ô được truyền thông báo lỗi
- **THEN** lý do hiện ngay dưới đúng ô đó và các ô khác không đổi

### Requirement: Popup cuộn nhận giới hạn ngày và chip 23:59
Popup chọn ngày giờ dạng cuộn SHALL nhận dòng phụ, `minDate`, `maxDate` và chip 23:59 tuỳ chọn; ngày ngoài khoảng SHALL bị mờ và SHALL NOT xác nhận được; chip 23:59 SHALL chọn giờ 23 phút 59 mà không tự xác nhận.

#### Scenario: Dòng phụ
- **WHEN** popup mở với dòng phụ "Ngày khai mạc"
- **THEN** dòng đó hiện ngay dưới tiêu đề

#### Scenario: Ngày ngoài khoảng
- **WHEN** ngày đang chọn sớm hơn `minDate`
- **THEN** nút Xác nhận bị khoá và popup không trả giá trị

#### Scenario: Chip 23:59
- **WHEN** người dùng bấm chip 23:59 rồi Xác nhận
- **THEN** popup trả về ngày đang chọn lúc 23:59

#### Scenario: Không bật tuỳ chọn
- **WHEN** popup mở không kèm tuỳ chọn mới
- **THEN** hành vi giống trước (không chip, không dòng phụ, không khoá Xác nhận)

### Requirement: Trang Đăng ký báo lỗi thứ tự ngày ngay tại ô sai
Trang Đăng ký quản lý giải SHALL kiểm thứ tự bốn mốc theo các luật hiện có, tô đỏ đúng ô sai kèm lý do ngay dưới ô khi giá trị thay đổi, và SHALL khoá nút Lưu khi còn lỗi thứ tự.

#### Scenario: Bế mạc trước khai mạc
- **WHEN** ngày bế mạc sớm hơn ngày khai mạc
- **THEN** ô bế mạc đỏ và hiện "Ngày bế mạc phải sau ngày khai mạc" dưới ô, các ô khác không đỏ, nút Lưu bị khoá

#### Scenario: Thứ tự hợp lệ
- **WHEN** bốn mốc đúng thứ tự
- **THEN** không ô nào đỏ và nút Lưu dùng được

#### Scenario: Chọn mốc bằng popup cuộn
- **WHEN** người dùng bấm một ô mốc
- **THEN** popup cuộn mở với giới hạn ngày suy ra từ các mốc liền kề và hạn chót đăng ký có chip 23:59
