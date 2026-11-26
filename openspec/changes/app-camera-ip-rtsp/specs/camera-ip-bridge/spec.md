## ADDED Requirements

### Requirement: Dựng URL RTSP theo hãng camera
The app SHALL build the RTSP URL from the IP, brand, username, password, port and stream choice, percent-encoding username and password, and SHALL never write the full URL to logs or exceptions.

#### Scenario: Dahua luồng chính
- **WHEN** hãng là Dahua, IP `192.168.1.50`, cổng 554, luồng chính
- **THEN** URL là `rtsp://<user>:<pass>@192.168.1.50:554/cam/realmonitor?channel=1&subtype=0` với user/pass đã mã hoá phần trăm

#### Scenario: Mật khẩu có ký tự đặc biệt
- **WHEN** mật khẩu chứa `@` hoặc `:`
- **THEN** URL vẫn tách đúng userinfo và host

### Requirement: Đẩy luồng lên stream key AQP
The app SHALL push the pulled stream by remuxing (no re-encode) to the `rtmpServer` and `rtmpStreamKey` of the selected PUSH camera, and SHALL refuse to start when the camera has no key (`hasKey` false).

#### Scenario: Bắt đầu phát
- **WHEN** người dùng nhập đủ thông tin và bấm Bắt đầu, camera đã có key
- **THEN** trạng thái chuyển Đang kết nối rồi Đang phát khi FFmpeg ghi được khung hình đầu

#### Scenario: Sai mật khẩu hoặc không tới được camera
- **WHEN** FFmpeg thoát với lỗi xác thực hoặc hết thời gian chờ
- **THEN** app hiện lỗi dễ hiểu (sai tài khoản / không cùng mạng với camera), không in URL hay mật khẩu

#### Scenario: Camera phát H.265
- **WHEN** codec video của luồng không phải H.264
- **THEN** app dừng và hướng dẫn đổi luồng phụ H.264 trong menu camera

### Requirement: Giữ phát và tự nối lại
The app SHALL keep streaming while the screen is off (Android foreground service) and SHALL retry with backoff when the connection drops, without double-starting when Start is tapped twice.

#### Scenario: Rớt mạng rồi có lại
- **WHEN** mạng mất 20 giây rồi có lại
- **THEN** app tự nối lại, trạng thái về Đang phát, chỉ có một tiến trình FFmpeg

#### Scenario: Bấm Bắt đầu hai lần
- **WHEN** người dùng bấm Bắt đầu hai lần liên tiếp
- **THEN** chỉ một tiến trình FFmpeg chạy
