## MODIFIED Requirements

### Requirement: Ghép ngẫu nhiên báo tên người lẻ
Ghép ngẫu nhiên trên màn quản lý MUST gửi `divisionId` của nội dung đang chọn hoặc nội dung duy nhất, và MUST hỏi BTC chọn nội dung khi giải có nhiều nội dung chưa chọn. Màn ghép cặp MUST NOT gửi `divisionId` khi giải có nhiều nội dung và MUST hiện nguyên văn `message` 400 của Backend. Sau khi ghép, App MUST hiện cặp và tên người lẻ từ response.

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
- **WHEN** giải có nhiều nội dung và BTC bấm ghép ngẫu nhiên trên màn ghép cặp
- **THEN** body không có `divisionId` và snackbar hiện đúng "Vui lòng chọn nội dung để ghép đôi."

#### Scenario: Lỗi không có message từ Backend
- **WHEN** yêu cầu ghép thất bại vì mạng hoặc phản hồi không có `message`
- **THEN** snackbar hiện thông điệp dự phòng kèm nội dung lỗi thật, không hiện tham chiếu hàm hay "Closure"

#### Scenario: Thiếu trường trong response
- **WHEN** response thiếu `paired` hoặc `unpairedNames`
- **THEN** App không báo lỗi và không làm hỏng màn ghép cặp

### Requirement: Tạo sơ đồ Lite gửi nội dung và báo người không ghép được
App MUST gọi `POST /tournaments/lite/:id/bracket` với `divisionId` của nội dung đang chọn hoặc nội dung duy nhất. Màn quản lý MUST hỏi BTC chọn trước khi giải có nhiều nội dung chưa chọn. Màn ghép cặp MUST NOT gửi `divisionId` khi giải có nhiều nội dung. App MUST NOT gọi `pairs/generate` trước khi tạo sơ đồ. Lỗi 400 của Backend MUST được hiện nguyên văn và MUST NOT bị nuốt.

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
- **WHEN** giải có nhiều nội dung, màn ghép cặp không gửi `divisionId` và Backend trả 400 "Vui lòng chọn nội dung để tạo sơ đồ."
- **THEN** snackbar hiện đúng thông điệp đó và không báo thành công

#### Scenario: Tạo sơ đồ không ghép trước
- **WHEN** BTC bấm tạo sơ đồ khi còn người chờ ghép
- **THEN** App chỉ gọi `POST /tournaments/lite/:id/bracket`, không gọi `pairs/generate`

## ADDED Requirements

### Requirement: Màn quản lý ghi sơ đồ và VĐV ảo theo nội dung đang chọn
Màn quản lý Lite MUST hỏi BTC chọn nội dung khi giải có từ hai nội dung dùng được và chưa có nội dung đang chọn, trước khi tạo sơ đồ, ghép ngẫu nhiên, reset, thêm hoặc xoá VĐV ảo. App MUST NOT lấy nội dung đầu tiên làm nội dung ghi.

#### Scenario: Giải nhiều nội dung chưa chọn
- **WHEN** BTC bấm tạo sơ đồ, reset, ghép ngẫu nhiên, thêm hoặc xoá VĐV ảo khi chưa chọn nội dung
- **THEN** màn hiện hộp chọn nội dung và chưa gọi API nào

#### Scenario: BTC chọn nội dung
- **WHEN** BTC chọn một nội dung và xác nhận
- **THEN** màn tải lại sơ đồ và trận của nội dung đó, và thao tác tiếp tục với nội dung đó

#### Scenario: BTC huỷ chọn
- **WHEN** BTC huỷ hộp chọn nội dung
- **THEN** thao tác dừng, không gọi API và không hiện thông báo lỗi

#### Scenario: Đã chọn nội dung trước đó
- **WHEN** màn đã có nội dung đang chọn
- **THEN** không hỏi lại và thao tác ghi dùng nội dung đó

#### Scenario: Giải một nội dung
- **WHEN** giải có đúng một nội dung dùng được
- **THEN** không hỏi và dùng nội dung đó như trước

#### Scenario: Chưa chọn thì hiển thị nội dung đầu tiên
- **WHEN** giải có nhiều nội dung và màn chưa có nội dung đang chọn
- **THEN** sơ đồ và trận hiển thị nội dung đầu tiên, chỉ để đọc, không dùng để ghi

#### Scenario: Notifier nhận thao tác ghi khi chưa chọn
- **WHEN** notifier nhận thao tác ghi khi giải có nhiều nội dung và chưa chọn nội dung
- **THEN** ném lỗi trước khi gửi request, không gửi `divisionId` và không để cờ đang xử lý bị kẹt
