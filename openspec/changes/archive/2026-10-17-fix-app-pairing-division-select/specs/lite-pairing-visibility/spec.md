## MODIFIED Requirements

### Requirement: Ghép ngẫu nhiên báo tên người lẻ
Ghép ngẫu nhiên trên màn quản lý MUST gửi `divisionId` của nội dung đang chọn hoặc nội dung duy nhất, và MUST hỏi BTC chọn nội dung khi giải có nhiều nội dung chưa chọn. Màn ghép cặp MUST gửi `divisionId` của nội dung đang chọn theo cùng quy tắc; ghép tay MUST NOT gửi `divisionId`. Sau khi ghép, App MUST hiện cặp và tên người lẻ từ response.

#### Scenario: Số chẵn, ghép hết
- **WHEN** `unpairedParticipantIds` rỗng
- **THEN** hiện thông báo ghép cặp thành công và danh sách cặp đã ghép

#### Scenario: Số lẻ, người lẻ có tên
- **WHEN** `unpairedNames` = ["Nguyễn A"]
- **THEN** thông báo ghi rõ "Nguyễn A" là người lẻ chưa ghép

#### Scenario: Id không có trong danh sách đã tải
- **WHEN** `unpairedParticipantIds` chứa id không có trong danh sách hiện tại và response không có `unpairedNames`
- **THEN** thông báo vẫn hiện id đó dưới dạng `#<id>`, không im lặng

#### Scenario: Giải một nội dung gửi divisionId
- **WHEN** giải có đúng một nội dung có `id` và BTC bấm ghép ngẫu nhiên
- **THEN** body gửi `{strategy, divisionId}` với `divisionId` là id của nội dung đó

#### Scenario: Giải nhiều nội dung không đoán nội dung
- **WHEN** giải có nhiều nội dung chưa chọn và BTC bấm ghép ngẫu nhiên trên màn ghép cặp
- **THEN** màn hỏi BTC chọn nội dung và chưa gọi API nào

#### Scenario: Giải nhiều nội dung đã chọn gửi divisionId
- **WHEN** giải có nhiều nội dung, BTC đã chọn một nội dung và bấm ghép ngẫu nhiên trên màn ghép cặp
- **THEN** body gửi `{strategy, divisionId}` với `divisionId` là id nội dung đã chọn

#### Scenario: Lỗi không có message từ Backend
- **WHEN** yêu cầu ghép thất bại vì mạng hoặc phản hồi không có `message`
- **THEN** snackbar hiện thông điệp dự phòng kèm nội dung lỗi thật, không hiện tham chiếu hàm hay "Closure"

#### Scenario: Thiếu trường trong response
- **WHEN** response thiếu `paired` hoặc `unpairedNames`
- **THEN** App không báo lỗi và không làm hỏng màn ghép cặp

### Requirement: Tạo sơ đồ Lite gửi nội dung và báo người không ghép được
App MUST gọi `POST /tournaments/lite/:id/bracket` với `divisionId` của nội dung đang chọn hoặc nội dung duy nhất. Màn ghép cặp MUST hỏi BTC chọn trước khi giải có nhiều nội dung chưa chọn, và MUST gửi `divisionId` của nội dung đã chọn. App MUST NOT gọi `pairs/generate` trước khi tạo sơ đồ. Lỗi 400 của Backend MUST được hiện nguyên văn và MUST NOT bị nuốt.

#### Scenario: Thành công có người không ghép được
- **WHEN** phản hồi có `unpairedNames: ["Nguyễn A"]`
- **THEN** thông báo thành công kèm tên "Nguyễn A"

#### Scenario: Phản hồi thiếu trường tuỳ chọn
- **WHEN** phản hồi không có `autoPaired` và `unpairedNames`
- **THEN** chỉ hiện thông báo tạo sơ đồ thành công

#### Scenario: Backend từ chối
- **WHEN** backend trả 400 (ví dụ chưa đủ cặp)
- **THEN** snackbar hiện thông điệp lỗi của backend, không hiện thông báo thành công

#### Scenario: Giải nhiều nội dung chưa chọn nội dung
- **WHEN** giải có nhiều nội dung và BTC bấm tạo sơ đồ khi chưa chọn nội dung
- **THEN** màn hỏi BTC chọn nội dung và chưa gọi API nào; sau khi chọn, body gửi `divisionId` của nội dung đã chọn

#### Scenario: Tạo sơ đồ không ghép trước
- **WHEN** BTC bấm tạo sơ đồ khi còn người chờ ghép
- **THEN** App chỉ gọi `POST /tournaments/lite/:id/bracket`, không gọi `pairs/generate`

## ADDED Requirements

### Requirement: Màn ghép cặp chọn nội dung bằng bộ chọn dùng chung
Màn ghép cặp Lite MUST dùng hộp chọn nội dung chung với màn quản lý khi giải có từ hai nội dung dùng được. Khi đã chọn nội dung, danh sách chờ ghép và danh sách đơn MUST chỉ hiện VĐV của nội dung đó. Giải một nội dung MUST NOT hiện bộ chọn.

#### Scenario: Giải nhiều nội dung chưa chọn
- **WHEN** BTC mở màn ghép cặp của giải có nhiều nội dung
- **THEN** danh sách chờ trống, màn hiện nút chọn nội dung và không có nút ghép ngẫu nhiên

#### Scenario: Chọn nội dung lọc danh sách chờ
- **WHEN** BTC chọn một nội dung
- **THEN** chỉ VĐV thuộc nội dung đó nằm trong danh sách chờ và danh sách đơn

#### Scenario: BTC huỷ hộp chọn
- **WHEN** BTC huỷ hộp chọn khi bấm ghép ngẫu nhiên hoặc tạo sơ đồ
- **THEN** thao tác dừng và không gọi API nào

#### Scenario: Giải một nội dung
- **WHEN** giải có đúng một nội dung dùng được
- **THEN** không hiện bộ chọn và danh sách không lọc theo nội dung
