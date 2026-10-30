# Spec Delta

## Purpose

BTC pickleball đặt mốc DUPR cho nội dung ngay trong App; VĐV thấy mốc, biết mình có hợp hay không, và khai điểm DUPR tại màn đăng ký của App.

## ADDED Requirements

### Requirement: Editor nội dung chọn mốc DUPR

`DivisionEditorSheet` MUST hiện mục "Trình DUPR" với hai ô chọn Từ và Đến (2.0 đến 6.0 bước 0.5 và "Không giới hạn") khi nội dung là pickleball, và MUST gửi `minDupr`, `maxDupr` (số hoặc `null`) cùng yêu cầu tạo hoặc sửa. Nội dung không phải pickleball MUST NOT hiện mục này và MUST NOT gửi hai trường. Editor MUST NOT gửi khoảng có Từ lớn hơn Đến.

#### Scenario: Chọn khoảng hợp lệ

- **WHEN** BTC chọn Từ 3.0, Đến 3.5 và lưu nội dung pickleball
- **THEN** payload có `minDupr: 3.0` và `maxDupr: 3.5`

#### Scenario: Chọn Từ lớn hơn Đến

- **WHEN** BTC đã chọn Đến 3.0 rồi chọn Từ 4.0
- **THEN** ô Đến về "Không giới hạn", không có khoảng ngược

#### Scenario: Môn khác

- **WHEN** BTC mở editor của nội dung cầu lông
- **THEN** không thấy mục trình DUPR và payload không có `minDupr`, `maxDupr`

#### Scenario: Sửa nội dung đã có mốc rồi xoá mốc

- **WHEN** BTC mở nội dung có `minDupr: 3`, `maxDupr: 3.5`, đổi cả hai về "Không giới hạn" và lưu
- **THEN** hai ô ban đầu hiện đúng 3.0 và 3.5, payload lưu có `minDupr: null`, `maxDupr: null`

### Requirement: Màn đăng ký hiện và kiểm mốc DUPR

Màn đăng ký đơn và màn đăng ký đôi MUST hiện mốc DUPR của nội dung khi có. Khi người dùng chọn nội dung có mốc, App MUST lấy điểm DUPR của họ cho đúng `categoryId` và thể thức, MUST báo hợp lệ, thấp hơn, cao hơn hoặc chưa khai, và MUST khoá nút đăng ký khi điểm đã biết là chưa hợp lệ (trừ khi không tải được điểm, xem scenario). Khi chưa khai, App MUST có ô nhập điểm và nút lưu gọi `PUT /users/me/external-ratings`.

#### Scenario: Hợp lệ

- **WHEN** nội dung có mốc 3.0–3.5 và điểm DUPR của người dùng là 3.2
- **THEN** hiện trạng thái hợp lệ và nút đăng ký bật

#### Scenario: Vượt mốc trên

- **WHEN** điểm là 3.62 và mốc đến 3.5
- **THEN** hiện thông báo vượt mốc nêu khoảng 3.0–3.5 và nút đăng ký khoá

#### Scenario: Chưa khai điểm

- **WHEN** người dùng không có điểm DUPR cho thể thức của nội dung
- **THEN** hiện ô nhập điểm; lưu thành công thì kiểm lại và mở nút nếu hợp lệ

#### Scenario: Lưu điểm lỗi mạng

- **WHEN** `PUT` thất bại
- **THEN** hiện thông báo lỗi, giữ số đã nhập, nút lưu bật lại

#### Scenario: Không tải được điểm

- **WHEN** `GET /users/me/external-ratings` thất bại
- **THEN** hiện thông báo lỗi và nút Thử lại; nút đăng ký không bị khoá

#### Scenario: Nội dung không có mốc

- **WHEN** nội dung không có `minDupr` và `maxDupr`
- **THEN** không hiện khối DUPR và không gọi `GET /users/me/external-ratings`

### Requirement: Lỗi DUPR từ Backend hiện đúng thông báo

Khi `POST /tournaments/:id/register` hoặc `POST /tournaments/:id/join-team` trả 400 `DUPR_LIMIT_VIOLATION`, App MUST hiện thông báo tiếng Việt do Backend gửi (có nêu khoảng) và MUST NOT báo đăng ký thành công.

#### Scenario: Backend từ chối dù client cho qua

- **WHEN** điểm đổi giữa lúc kiểm và lúc gửi, Backend trả 400 `DUPR_LIMIT_VIOLATION`
- **THEN** App hiện thông báo của Backend và ở lại màn đăng ký

#### Scenario: Vào đội bằng mã mời bị chặn

- **WHEN** `POST /tournaments/:id/join-team` trả `DUPR_LIMIT_VIOLATION`
- **THEN** màn vào đội hiện thông báo của Backend, không báo đã vào đội
