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
