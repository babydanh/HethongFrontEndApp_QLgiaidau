## ADDED Requirements

### Requirement: Nút bật/tắt phát của trận
Trang chấm điểm SHALL hiện hàng "Livestream" với nút Bắt đầu (xanh) khi trận không LIVE và Dừng (đỏ) khi `streamStatus=LIVE`, chỉ khi `control-state.hasCamera == true`. `ENDED` SHALL quy về `IDLE`; trạng thái lạ khi có camera SHALL ẩn nút thay vì đoán.

#### Scenario: Có camera, chưa live
- **WHEN** control-state trả `hasCamera=true`, `streamStatus=IDLE`
- **THEN** nút "Bắt đầu" hiện; bấm thì gọi `POST /livestream/matches/{id}/start`

#### Scenario: Đang live
- **WHEN** `streamStatus=LIVE`
- **THEN** nút "Dừng" hiện; bấm thì gọi `POST /livestream/matches/{id}/stop`

#### Scenario: Không camera hoặc trạng thái lạ
- **WHEN** `hasCamera=false`, hoặc `hasCamera=true` mà `streamStatus` không nhận ra
- **THEN** không hiện nút

### Requirement: Chống bấm đúp và làm mới video
Nút SHALL bị khoá và hiện vòng chờ khi đang gửi; chỉ một lệnh chạy cùng lúc. Sau start/stop thành công App SHALL làm mới `matchPlaybackProvider` của trận.

#### Scenario: Bấm hai lần liên tiếp
- **WHEN** người dùng bấm "Bắt đầu" hai lần khi lệnh đầu chưa xong
- **THEN** chỉ một `POST start` được gửi

### Requirement: Chặn quyền và lỗi
Server 403 SHALL ẩn nút và hiện thông báo `Match.permissionDenied`. Lỗi 5xx SHALL không hiện thông báo; lỗi khác hiện thông báo lỗi. `recordingStatus=PENDING` SHALL hiện cảnh báo `recordingPending`.

#### Scenario: 403
- **WHEN** start trả 403
- **THEN** nút biến mất và hiện chữ quyền điều khiển

#### Scenario: 5xx
- **WHEN** start trả 500
- **THEN** không có thông báo, nút vẫn như cũ

#### Scenario: Ghi hình chưa xác nhận
- **WHEN** start/stop trả `recordingStatus=PENDING`
- **THEN** hiện cảnh báo "Chưa xác nhận được trạng thái ghi hình…"
