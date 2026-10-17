## MODIFIED Requirements

### Requirement: Ghép ngẫu nhiên báo tên người lẻ
App MUST gửi `divisionId` trong body `POST /tournaments/lite/:id/pairs/generate` khi giải có đúng một nội dung có `id`. Khi giải có nhiều nội dung mà màn không có nội dung đang chọn, App MUST NOT gửi `divisionId` và MUST hiện nguyên văn `message` 400 của Backend. Sau khi ghép thành công, App MUST hiện cặp từ `paired[].memberNames` khi có. App MUST hiện tên (`displayName`) của mọi người có id trong `unpairedParticipantIds`, ưu tiên `unpairedNames` của server; id không tra được tên MUST hiện dạng `#<id>`. Thiếu trường MUST NOT gây lỗi.

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
- **WHEN** giải có nhiều nội dung và màn không có nội dung đang chọn
- **THEN** body không có `divisionId` và snackbar hiện đúng "Vui lòng chọn nội dung để ghép đôi."

#### Scenario: Lỗi không có message từ Backend
- **WHEN** yêu cầu ghép thất bại vì mạng hoặc phản hồi không có `message`
- **THEN** snackbar hiện thông điệp dự phòng kèm nội dung lỗi thật, không hiện tham chiếu hàm hay "Closure"

### Requirement: Tạo sơ đồ Lite gửi nội dung và báo người không ghép được
App MUST gọi `POST /tournaments/lite/:id/bracket` với body `{divisionId}` khi giải có đúng một nội dung có `id`; khi có nhiều nội dung, App MUST NOT gửi `divisionId` và để backend trả lỗi. App MUST NOT gọi `pairs/generate` trước khi tạo sơ đồ; Backend tự ghép trong nội dung khi tạo sơ đồ. Nếu phản hồi có `unpairedNames` không rỗng, App MUST hiện danh sách tên đó. Nếu phản hồi có `autoPaired`, App MAY hiện danh sách cặp đã ghép. Lỗi từ Backend MUST được hiện nguyên văn `message` và MUST NOT bị nuốt. Thiếu trường MUST NOT gây lỗi.

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
- **WHEN** giải có nhiều nội dung và Backend trả 400 "Vui lòng chọn nội dung để tạo sơ đồ."
- **THEN** snackbar hiện đúng thông điệp đó và không báo thành công

#### Scenario: Tạo sơ đồ không ghép trước
- **WHEN** BTC bấm tạo sơ đồ khi còn người chờ ghép
- **THEN** App chỉ gọi `POST /tournaments/lite/:id/bracket`, không gọi `pairs/generate`
