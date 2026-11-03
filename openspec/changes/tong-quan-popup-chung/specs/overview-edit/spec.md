## ADDED Requirements

### Requirement: Lộ trình có mốc kết thúc
Tab Tổng quan SHALL hiện dòng "Kết thúc giải" trong Lộ trình, và người quản lý SHALL sửa được nó.

#### Scenario: Quản lý bấm mốc kết thúc
- **WHEN** quản lý bấm dòng "Kết thúc giải"
- **THEN** popup sửa ngày bế mạc mở ra (focus `tournamentClosing`)

### Requirement: Con mắt ẩn chữ trên banner
Banner quản lý SHALL có nút con mắt bật/tắt `hideFeaturedCardText`.

#### Scenario: Bấm con mắt banner
- **WHEN** quản lý bấm con mắt khi chữ đang hiện
- **THEN** callback nhận giá trị ẩn = true và icon đổi sang mắt gạch

### Requirement: Con mắt Ban tổ chức luôn có tác dụng
Hiện lại Ban tổ chức SHALL đặt `hidden=false` và `displayMode=PROFILE`; ẩn đi SHALL chỉ đặt `hidden=true`.

#### Scenario: Giải đang MANUAL
- **WHEN** `displayMode` là MANUAL và quản lý bấm hiện
- **THEN** payload có `hidden=false` và `displayMode=PROFILE`

### Requirement: Khung popup chung
Mọi popup sửa ở Tổng quan SHALL dùng một khung có tiêu đề, nút đóng và thân co theo nội dung (thanh Lưu dính đáy do thân cấp).

#### Scenario: Đóng bằng nút
- **WHEN** quản lý bấm nút đóng
- **THEN** popup đóng, không lưu

### Requirement: Bốn mốc ngày cùng một cách sửa
Bấm một mốc ở Lộ trình SHALL mở thẳng bộ chọn ngày giờ (không form bao quanh) và lưu ngay khi xác nhận; mốc bị khoá SHALL báo lý do bằng thông báo ngắn rồi đóng; lỗi SHALL hiện bằng thông báo và không để lại lớp chặn.

#### Scenario: Giải đã đóng đăng ký, sửa ngày bế mạc
- **WHEN** giải ở trạng thái đã đóng đăng ký và quản lý chọn ngày bế mạc mới
- **THEN** chỉ `endDate` được gửi lên và popup đóng

#### Scenario: Mốc mở đăng ký khi đã đóng
- **WHEN** giải đã đóng đăng ký và quản lý bấm "Mở đăng ký"
- **THEN** hiện thông báo lý do, không mở bộ chọn, không gửi gì
