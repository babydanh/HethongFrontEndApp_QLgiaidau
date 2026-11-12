## ADDED Requirements

### Requirement: Bắt đầu/Dừng trên thẻ trận
Thẻ trận trong bảng camera SHALL hiện "Dừng" khi trận LIVE, ngược lại "Bắt đầu" (khoá nếu trận chưa có camera, kèm gợi ý "Sân này chưa khai URL camera", và khoá khi đang bận). Phát thành công SHALL làm mới danh sách trận-livestream; start có `publish` thì sao chép liên kết; PULL (`publish=null`) thì báo `streamStartedFromExistingUrl`; PENDING thì báo `recordingPending`.

#### Scenario: Chưa camera
- **WHEN** trận không có camera
- **THEN** nút "Bắt đầu" bị khoá

#### Scenario: Đang live
- **WHEN** `streamStatus=LIVE`
- **THEN** hiện "Dừng", không hiện nút bản ghi

#### Scenario: Start kiểu PULL
- **WHEN** `POST start` trả `publish=null`
- **THEN** hiện "Đã bắt đầu phát từ URL của sân." rồi làm mới danh sách

### Requirement: Nút bản ghi đúng điều kiện
Nút "Xem bản ghi MP4" SHALL hiện khi trận không LIVE và (`hasCamera` hoặc `hasRecording == true` đúng boolean).

#### Scenario: Đã có bản ghi, camera đã gỡ
- **WHEN** `hasCamera=false`, `hasRecording=true`, không LIVE
- **THEN** nút bản ghi hiện

#### Scenario: Không camera, không bản ghi, hoặc hasRecording không phải boolean
- **THEN** nút bản ghi ẩn

### Requirement: Tải video đầy đủ
Sheet phát bản ghi SHALL có nút "Tải video đầy đủ" cho ngày đang chọn: gọi playlist trước để kiểm quyền, rồi tải `GET /livestream/matches/{id}/recordings/download?period=` có token về file tạm và mở chia sẻ. Thiếu quyền hoặc lỗi SHALL hiện `recordingsDownloadError`; đang tải SHALL khoá nút và hiện `recordingsDownloadPreparing`.

#### Scenario: Thiếu quyền
- **WHEN** playlist trả 403
- **THEN** hiện thông báo không có quyền, không gọi download

#### Scenario: Thành công
- **WHEN** playlist ổn và download trả file
- **THEN** file được lưu tạm và mở chia sẻ

### Requirement: Biên dữ liệu
Danh sách trận-livestream rỗng/null/401/403/404/5xx/timeout SHALL cho trạng thái rõ (thẻ vẫn hiện, nút theo mặc định an toàn: không LIVE, không bản ghi) và không crash.

#### Scenario: Lỗi mạng khi tải danh sách
- **WHEN** `GET /livestream/tournaments/{tid}/matches` lỗi
- **THEN** thẻ trận vẫn hiện, "Bắt đầu" theo hasCamera, nút bản ghi theo hasCamera
