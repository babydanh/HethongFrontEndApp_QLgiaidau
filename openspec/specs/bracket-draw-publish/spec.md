# bracket-draw-publish Specification

## Purpose
Luồng lưu sơ đồ bốc thăm tự động trên App: gọi API generate-bracket, tải lại sơ đồ từ server và hiện lỗi thật từ Backend.

## Requirements

### Requirement: Lưu sơ đồ bốc thăm qua Backend
Luồng "Lưu sơ đồ" của bốc thăm tự động MUST gọi `POST /tournaments/:id/generate-bracket` với body `{divisionId?, seedingType: "RANDOM", allowReset: false}`. `divisionId` MUST được gửi khi giải có đúng một nội dung hoặc BTC đã chọn rõ một nội dung; khi giải có nhiều nội dung mà chưa chọn, App MUST yêu cầu chọn và MUST NOT đoán hoặc gửi yêu cầu.

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

### Requirement: Sơ đồ chỉ do Backend sinh
`IMatchRepository.createBatch` và các đường gọi tới nó MUST bị xoá; App MUST NOT giữ shim hay nhánh dự phòng tạo trận phía client. Sau khi Backend trả thành công, App MUST tải lại sơ đồ từ server và MUST NOT hiển thị bản xem trước cục bộ.

#### Scenario: Không còn tạo trận từ client
- **WHEN** BTC lưu sơ đồ bốc thăm thành công
- **THEN** không có lời gọi tạo trận hàng loạt nào từ App và sơ đồ hiển thị được tải lại từ server

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
