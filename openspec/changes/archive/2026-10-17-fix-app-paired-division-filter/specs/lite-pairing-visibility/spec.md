## MODIFIED Requirements

### Requirement: Màn ghép cặp chọn nội dung bằng bộ chọn dùng chung
Màn ghép cặp Lite MUST dùng hộp chọn nội dung chung với màn quản lý khi giải có từ hai nội dung dùng được. Khi đã chọn nội dung, danh sách chờ ghép, danh sách đơn và mục "Đã ghép" MUST chỉ hiện VĐV của nội dung đó. Giải một nội dung MUST NOT hiện bộ chọn.

#### Scenario: Giải nhiều nội dung chưa chọn
- **WHEN** BTC mở màn ghép cặp của giải có nhiều nội dung
- **THEN** danh sách chờ trống, màn hiện nút chọn nội dung và không có nút ghép ngẫu nhiên

#### Scenario: Chọn nội dung lọc danh sách chờ
- **WHEN** BTC chọn một nội dung
- **THEN** chỉ VĐV thuộc nội dung đó nằm trong danh sách chờ và danh sách đơn

#### Scenario: Chọn nội dung lọc mục Đã ghép
- **WHEN** BTC chọn nội dung "Đôi nữ" trong khi "Đôi nam" đã có cặp
- **THEN** mục "Đã ghép" chỉ hiện cặp của "Đôi nữ", không hiện cặp của "Đôi nam"

#### Scenario: BTC huỷ hộp chọn
- **WHEN** BTC huỷ hộp chọn khi bấm ghép ngẫu nhiên hoặc tạo sơ đồ
- **THEN** thao tác dừng và không gọi API nào

#### Scenario: Giải một nội dung
- **WHEN** giải có đúng một nội dung dùng được
- **THEN** không hiện bộ chọn và danh sách không lọc theo nội dung
