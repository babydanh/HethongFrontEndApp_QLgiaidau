## ADDED Requirements

### Requirement: Mở live Facebook trong Larix
Sau khi tạo live thành công, panel SHALL có nút "Mở trong Larix" mở Larix Broadcaster với kết nối RTMP đã điền sẵn, MUST chặn bấm đôi khi đang mở, và MUST báo hướng xử lý nếu không mở được Larix.

#### Scenario: Bấm mở Larix
- **WHEN** live đã tạo và người dùng bấm "Mở trong Larix"
- **THEN** link `larix://set/v1?conn[][url]=...` với địa chỉ RTMP nối `/` rồi khoá phát được mở đúng một lần; nút cao ít nhất 48dp

#### Scenario: Larix chưa cài
- **WHEN** hệ thống không mở được link Larix
- **THEN** hiện SnackBar hướng dẫn cài Larix Broadcaster, không văng lỗi

#### Scenario: Thiếu địa chỉ hoặc khoá
- **WHEN** địa chỉ RTMP hoặc khoá phát rỗng
- **THEN** không hiện nút Mở trong Larix
