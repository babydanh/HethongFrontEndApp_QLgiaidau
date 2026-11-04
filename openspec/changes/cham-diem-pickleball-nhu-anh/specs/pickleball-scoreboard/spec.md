## ADDED Requirements

### Requirement: Màn chấm điểm pickleball cầm ngang theo bố cục bảng điểm
Khi sân pickleball vẽ theo chiều ngang, App SHALL vẽ hàng trên (KẾT THÚC, ⋯), sân 3 cột có điểm hai đội ở cột giữa, và thanh dưới (đồng hồ, + và − của từng đội, ĐỔI GIAO), đồng thời SHALL giữ mọi thao tác chấm điểm hiện có và các điều kiện khoá của chúng.

#### Scenario: Chấm điểm bằng thanh dưới
- **WHEN** người có quyền chấm bấm + của đội đang giao ở side-out
- **THEN** điểm đội đó tăng đúng một lần và điểm mới hiện ở cột giữa

#### Scenario: Đội nhận bị khoá ở side-out
- **WHEN** side-out đang chạy và đội nhận chưa được phép ghi điểm
- **THEN** nút + của đội nhận bị khoá, nút − vẫn dùng được khi điểm lớn hơn 0

#### Scenario: Chỉ xem
- **WHEN** người xem không có quyền chấm điểm
- **THEN** không có nút KẾT THÚC, ⋯, +, −, ĐỔI GIAO, ↕, ⇄ và không kéo thả được; lời hô và điểm vẫn hiện

#### Scenario: Đổi giao
- **WHEN** người chấm bấm ĐỔI GIAO ở side-out
- **THEN** App gọi đúng hành động mất giao như icon "Mất giao" trước đây; ở rally và Lite nút này không có

### Requirement: KẾT THÚC mở hộp thoại chốt set hoặc chọn đội thắng
Nút KẾT THÚC SHALL mở một hộp thoại có hai lựa chọn "Chốt set" và "Chọn đội thắng"; "Chốt set" chỉ dùng được khi set đủ điều kiện chốt, và mỗi lựa chọn SHALL chạy đúng luồng xác nhận đã có.

#### Scenario: Set chưa chốt được
- **WHEN** set chưa đủ điều kiện chốt (ví dụ 0-0)
- **THEN** lựa chọn "Chốt set" bị khoá, "Chọn đội thắng" vẫn mở được

### Requirement: Màu đội theo ảnh
Đội 1 SHALL dùng màu cam và Đội 2 màu xanh ở thanh nút, hộp thoại chọn đội thắng và sân cầm dọc; màu đi theo đội, không theo bên sân.

#### Scenario: Đổi sân
- **WHEN** hai đội đổi bên sân
- **THEN** nút + / − vẫn giữ màu của đội mình
