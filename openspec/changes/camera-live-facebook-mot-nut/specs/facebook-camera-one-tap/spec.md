## ADDED Requirements

### Requirement: Một nút tạo camera live Facebook
Hệ thống SHALL, khi người dùng bấm "Tạo camera live Facebook" trong sheet Thêm camera, tạo live trên fanpage chung, tạo camera PULL với `watchUrl` nhận được, đóng sheet và mở sheet "Camera đã sẵn sàng" chứa máy chủ RTMP, khoá phát (che sẵn), nút Mở trong Larix và mã QR.

#### Scenario: Tạo thành công với tên để trống
- **WHEN** người dùng chọn sân, để trống tên rồi bấm "Tạo camera live Facebook"
- **THEN** đúng một lần gọi tạo live và đúng một lần gọi `createCamera` với `mode` = `PULL`, `playbackUrl` = `watchUrl`, tên dạng `Live Facebook HH:mm`, kèm `courtId` đã chọn
- **AND** sheet Thêm camera đóng và sheet "Camera đã sẵn sàng" hiện máy chủ RTMP cùng khoá phát che sẵn

#### Scenario: Bấm đúp
- **WHEN** người dùng bấm nút hai lần liên tiếp
- **THEN** chỉ một camera được tạo

#### Scenario: Tạo camera thất bại sau khi đã có live
- **WHEN** `createCamera` ném lỗi
- **THEN** sheet vẫn mở, có thông báo lỗi, và bấm lại tái dùng live đang chờ của Backend

### Requirement: Báo rõ khi fanpage chưa đủ người theo dõi
Hệ thống SHALL hiển thị thông báo nêu fanpage cần ít nhất 100 người theo dõi và hướng dẫn liên hệ quản trị viên khi Backend trả mã `FACEBOOK_PAGE_NOT_ELIGIBLE`.

#### Scenario: Mã lỗi fanpage chưa đủ điều kiện
- **WHEN** Backend trả HTTP 400 với `code` = `FACEBOOK_PAGE_NOT_ELIGIBLE`
- **THEN** `facebookLiveError` trả `FacebookLiveError.pageNotEligible` và người dùng thấy thông báo "100 người theo dõi"
- **AND** không có camera nào được tạo
