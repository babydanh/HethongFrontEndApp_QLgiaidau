## ADDED Requirements

### Requirement: Tab Camera trong Quản lý giải
Màn Quản lý giải của App SHALL có tab "Camera" ngay trước tab "Cài đặt"; mở tab này SHALL hiện bảng camera của giải với nút Bắt đầu/Dừng phát cho từng trận. Nhãn tab MUST dùng key i18n `opsCamera` có ở cả `app_vi.arb` và `app_en.arb`.

#### Scenario: Chủ giải đang diễn ra mở tab Camera
- **WHEN** giải ở trạng thái đang diễn ra và người quản lý chạm tab "Camera"
- **THEN** App hiện bảng camera của giải không ở chế độ chỉ-đọc, có nút "Bắt đầu" cho trận

#### Scenario: Giải đã kết thúc mở tab Camera
- **WHEN** giải ở trạng thái COMPLETED và người quản lý chạm tab "Camera"
- **THEN** bảng camera ở chế độ chỉ-đọc và không có nút "Bắt đầu"/"Dừng"

#### Scenario: Chưa mở tab Camera
- **WHEN** người quản lý mở tab khác (vd "Cài đặt") mà chưa chạm tab "Camera"
- **THEN** bảng camera không được dựng và không gọi API sân/camera
