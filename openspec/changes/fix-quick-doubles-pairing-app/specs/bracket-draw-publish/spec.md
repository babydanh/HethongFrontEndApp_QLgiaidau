## ADDED Requirements

### Requirement: Lưu sơ đồ bốc thăm qua Backend
Luồng "Lưu sơ đồ" của bốc thăm tự động MUST gọi `POST /tournaments/:id/generate-bracket` với body `{divisionId, seedingType, allowReset: false}`. `IMatchRepository.createBatch` và các đường gọi tới nó MUST bị xoá; App MUST NOT giữ shim hay nhánh dự phòng.

#### Scenario: Lưu thành công
- **WHEN** BTC bấm lưu sơ đồ và Backend trả thành công
- **THEN** màn quay lại, hiện thông báo đã lưu, và không có trận nào được gửi từ client

#### Scenario: Giải nhiều nội dung thiếu nội dung
- **WHEN** Backend trả 400 "Vui lòng chọn nội dung để tạo sơ đồ."
- **THEN** snackbar hiện đúng thông điệp đó và màn không quay lại

#### Scenario: Sơ đồ đã tồn tại
- **WHEN** Backend trả lỗi vì sơ đồ đã có và `allowReset` là false
- **THEN** snackbar hiện lỗi, không ghi đè sơ đồ cũ

### Requirement: Hiện lỗi bốc thăm đúng nội dung
Khi lưu sơ đồ thất bại, App MUST hiện `e.toString()` đã gọi hàm, không truyền tham chiếu hàm.

#### Scenario: Lỗi mạng
- **WHEN** yêu cầu lưu thất bại vì mạng
- **THEN** thông báo chứa nội dung lỗi thật, không chứa chuỗi "Closure"
