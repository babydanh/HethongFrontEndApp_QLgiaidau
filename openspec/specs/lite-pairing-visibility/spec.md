# lite-pairing-visibility Specification

## Purpose
Màn ghép cặp Lite trên App: danh sách chờ ghép, số thành viên của đội/khách, ghép ngẫu nhiên báo tên người lẻ và tạo sơ đồ Lite.

## Requirements

### Requirement: Khách do BTC thêm hiện trong danh sách ghép cặp
Màn ghép cặp Lite MUST đưa vào danh sách chờ ghép mỗi participant có `teamStatus` = `PENDING_PARTNER`, không có `teamInviteToken` và có `memberCount` = 1.

#### Scenario: Khách BTC thêm trực tiếp
- **WHEN** participant có `PENDING_PARTNER`, `rosters` rỗng và `customResponses.importedFrom` = `ORGANIZER_DIRECT`
- **THEN** participant nằm trong danh sách chờ ghép với một thành viên

#### Scenario: VĐV tự đăng ký chưa có đồng đội
- **WHEN** `PENDING_PARTNER`, không có `importedFrom`, `rosters` có một dòng
- **THEN** participant nằm trong danh sách chờ như trước

#### Scenario: Danh sách rỗng
- **WHEN** không có participant nào thoả điều kiện
- **THEN** màn hiện trạng thái rỗng và không hiện nút ghép ngẫu nhiên

### Requirement: memberCount khớp backend
`memberCount` MUST được tính như `countParticipantMembers` của backend. Với nguồn BTC (`ORGANIZER_DIRECT` và `IMPORT_SOURCES`), `memberCount` = max(số dòng `rosters`, 2 nếu có `player2Name` hoặc `player2Email`, ngược lại 1). Với nguồn khác, `memberCount` = số dòng `rosters`.

#### Scenario: Khách có tên VĐV thứ hai
- **WHEN** `importedFrom` = `EXCEL`, `player2Name` có giá trị và `rosters` rỗng
- **THEN** `memberCount` = 2 và participant không nằm trong danh sách chờ đơn

### Requirement: Khách chờ phê duyệt không được ghép
Backend chỉ ghép được participant `PENDING_PARTNER` (`isDoublesParticipantPairable`). App MUST NOT tự đổi trạng thái khách; khách `PENDING_APPROVAL` không nằm trong danh sách chờ ghép.

#### Scenario: Khách chưa chuyển sang chờ ghép
- **WHEN** khách có `PENDING_APPROVAL` và `memberCount` = 1
- **THEN** khách không nằm trong danh sách chờ ghép và không được tính là đã ghép

### Requirement: Ghép ngẫu nhiên báo tên người lẻ
App MUST gửi `divisionId` khi giải có đúng một nội dung và MUST hiện nguyên văn `message` 400 của Backend khi giải nhiều nội dung mà màn không có nội dung đang chọn. Sau khi ghép, App MUST hiện cặp và tên người lẻ từ response.

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

#### Scenario: Thiếu trường trong response
- **WHEN** response thiếu `paired` hoặc `unpairedNames`
- **THEN** App không báo lỗi và không làm hỏng màn ghép cặp

### Requirement: Tạo sơ đồ Lite gửi nội dung và báo người không ghép được
App MUST gọi `POST /tournaments/lite/:id/bracket` với `{divisionId}` khi giải có đúng một nội dung; khi có nhiều nội dung App MUST NOT gửi `divisionId`. App MUST NOT gọi `pairs/generate` trước khi tạo sơ đồ. Lỗi 400 của Backend MUST được hiện nguyên văn và MUST NOT bị nuốt.

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
