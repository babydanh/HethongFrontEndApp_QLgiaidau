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
Sau khi ghép ngẫu nhiên thành công, App MUST hiện tên (`displayName`) của mọi participant có id trong `unpairedParticipantIds`, không chỉ số lượng. Tên lấy từ danh sách participant đã tải; id không tìm thấy MUST hiện dạng rút gọn `#<id>` thay vì bỏ qua. App MUST hiện danh sách đã ghép (`paired`) nếu backend trả, và MUST NOT lỗi khi trường thiếu.

#### Scenario: Số chẵn, ghép hết
- **WHEN** `unpairedParticipantIds` rỗng
- **THEN** hiện thông báo ghép cặp thành công như trước

#### Scenario: Số lẻ, người lẻ có tên
- **WHEN** `unpairedParticipantIds` = [id của "Nguyễn A"]
- **THEN** thông báo ghi rõ "Nguyễn A" là người lẻ chưa ghép

#### Scenario: Id không có trong danh sách đã tải
- **WHEN** `unpairedParticipantIds` chứa id không có trong danh sách hiện tại
- **THEN** thông báo vẫn hiện id đó dưới dạng `#<id>`, không im lặng

### Requirement: Tạo sơ đồ Lite gửi nội dung và báo người không ghép được
App MUST gọi `POST /tournaments/lite/:id/bracket` với body `{divisionId}` khi giải có đúng một nội dung có `id`; khi có nhiều nội dung, App MUST NOT gửi `divisionId` và để backend trả lỗi. Nếu phản hồi có `unpairedNames` không rỗng, App MUST hiện danh sách tên đó. Nếu phản hồi có `autoPaired`, App MAY hiện danh sách cặp đã ghép. Thiếu trường MUST NOT gây lỗi.

#### Scenario: Thành công có người không ghép được
- **WHEN** phản hồi có `unpairedNames: ["Nguyễn A"]`
- **THEN** thông báo thành công kèm tên "Nguyễn A"

#### Scenario: Phản hồi thiếu trường tuỳ chọn
- **WHEN** phản hồi không có `autoPaired` và `unpairedNames`
- **THEN** chỉ hiện thông báo tạo sơ đồ thành công

#### Scenario: Backend từ chối
- **WHEN** backend trả 400 (ví dụ chưa đủ cặp)
- **THEN** snackbar hiện thông điệp lỗi của backend, không hiện thông báo thành công
