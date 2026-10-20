# Spec Delta

## MODIFIED Requirements

### Requirement: Lưu sơ đồ bốc thăm qua Backend
Luồng "Lưu sơ đồ" của bốc thăm tự động MUST gọi `POST /tournaments/:id/generate-bracket` với body `{divisionId?, seedingType: "RANDOM", allowReset: false}`. `divisionId` MUST được gửi khi giải có đúng một nội dung hoặc BTC đã chọn rõ một nội dung; khi giải có nhiều nội dung mà chưa chọn, App MUST yêu cầu chọn và MUST NOT đoán hoặc gửi yêu cầu. `IMatchRepository.createBatch` và các đường gọi tới nó MUST bị xoá; App MUST NOT giữ shim hay nhánh dự phòng.
Sau khi Backend trả thành công, App MUST tải lại sơ đồ từ server và MUST NOT hiển thị bản xem trước cục bộ.

#### Scenario: Lưu thành công
- **WHEN** BTC bấm lưu sơ đồ và Backend trả thành công
- **THEN** màn quay lại, hiện thông báo đã lưu, sơ đồ hiển thị là bản server trả về, và không có trận nào được gửi từ client

#### Scenario: Giải nhiều nội dung đã chọn nội dung
- **WHEN** BTC chọn một division trong giải có nhiều nội dung rồi lưu sơ đồ
- **THEN** App gửi đúng `divisionId` đã chọn cùng `seedingType: "RANDOM"` và `allowReset: false`

#### Scenario: Giải nhiều nội dung chưa chọn
- **WHEN** BTC mở bốc thăm cho giải nhiều nội dung nhưng chưa chọn division
- **THEN** App yêu cầu chọn nội dung và không gửi yêu cầu sinh sơ đồ

#### Scenario: Giải nhiều nội dung thiếu nội dung
- **WHEN** Backend trả 400 "Vui lòng chọn nội dung để tạo sơ đồ."
- **THEN** snackbar hiện đúng thông điệp đó và màn không quay lại

#### Scenario: Backend từ chối sơ đồ
- **WHEN** Backend trả lỗi khi lưu sơ đồ
- **THEN** snackbar hiện thông điệp lỗi thật và màn không quay lại

#### Scenario: Sơ đồ đã tồn tại
- **WHEN** Backend trả lỗi vì sơ đồ đã có và `allowReset` là false
- **THEN** snackbar hiện lỗi, không ghi đè sơ đồ cũ
