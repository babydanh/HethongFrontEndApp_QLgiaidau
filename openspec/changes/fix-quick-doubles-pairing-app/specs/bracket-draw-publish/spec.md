## ADDED Requirements

### Requirement: Lưu sơ đồ bốc thăm qua Backend
Luồng "Lưu sơ đồ" của bốc thăm tự động MUST gọi `POST /tournaments/:id/generate-bracket` với body `{divisionId?, seedingType: "RANDOM", allowReset: false}`. `divisionId` MUST chỉ được gửi khi giải có đúng một nội dung; giải nhiều nội dung MUST NOT đoán nội dung. `IMatchRepository.createBatch` và các đường gọi tới nó MUST bị xoá; App MUST NOT giữ shim hay nhánh dự phòng.

Sau khi Backend trả thành công, App MUST tải lại sơ đồ từ server và MUST NOT hiển thị bản xem trước cục bộ.

#### Scenario: Lưu thành công
- **WHEN** BTC bấm lưu sơ đồ và Backend trả thành công
- **THEN** màn quay lại, hiện thông báo đã lưu, sơ đồ hiển thị là bản server trả về, và không có trận nào được gửi từ client

#### Scenario: Giải nhiều nội dung thiếu nội dung
- **WHEN** Backend trả 400 "Vui lòng chọn nội dung để tạo sơ đồ."
- **THEN** snackbar hiện đúng thông điệp đó và màn không quay lại

#### Scenario: Sơ đồ đã tồn tại
- **WHEN** Backend trả lỗi vì sơ đồ đã có và `allowReset` là false
- **THEN** snackbar hiện lỗi, không ghi đè sơ đồ cũ

### Requirement: Hiện lỗi bốc thăm đúng nội dung
Khi lưu sơ đồ thất bại, App MUST hiện thông điệp lỗi thật: ưu tiên `message` trong body Backend, không có thì dùng thông điệp Dio đã dịch, và MUST NOT hiện tham chiếu hàm hay chuỗi "Closure".

#### Scenario: Lỗi mạng
- **WHEN** yêu cầu lưu thất bại vì mạng
- **THEN** thông báo chứa nội dung lỗi thật, không chứa chuỗi "Closure"

### Requirement: Kết quả ghép tự động là tuỳ chọn
Response tạo sơ đồ MAY kèm `autoPaired` và `unpairedNames`. Thiếu trường (server cũ) MUST được coi là rỗng, không báo lỗi.

#### Scenario: Server không trả trường ghép
- **WHEN** response không có `autoPaired` và `unpairedNames`
- **THEN** snackbar chỉ hiện thông báo đã lưu và màn không crash
