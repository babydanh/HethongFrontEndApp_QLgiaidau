## ADDED Requirements

### Requirement: Chọn nguồn liên hệ bằng một công tắc
Popup Liên hệ SHALL dùng một công tắc "Dùng hồ sơ tài khoản" thay cho hai nút chọn nguồn, và SHALL ghi `displayMode` như cũ (MANUAL khi tắt, PROFILE khi bật).

#### Scenario: Bật hồ sơ tài khoản
- **WHEN** người dùng bật công tắc
- **THEN** hiện thẻ avatar và tên tài khoản, ô điện thoại và ô email; ô tên BTC biến mất và email của nhập tay bị bỏ như cũ

#### Scenario: Tắt hồ sơ tài khoản
- **WHEN** người dùng tắt công tắc
- **THEN** hiện ô tên BTC và điện thoại, không còn ô email và thẻ hồ sơ

### Requirement: Thêm liên kết bằng icon và một ô
Popup SHALL cho chọn loại liên kết bằng một hàng icon, SHALL thêm liên kết bằng nút ✓ nằm trong ô giá trị, và SHALL ẩn dòng thông báo khi chưa có liên kết nào.

#### Scenario: Thêm Facebook
- **WHEN** người dùng nhập đường dẫn và bấm ✓
- **THEN** khoá `facebook` được ghi và liên kết hiện ở danh sách với dấu ✕ để xoá

#### Scenario: Giá trị trống
- **WHEN** người dùng bấm ✓ khi ô trống
- **THEN** hiện lỗi "Vui lòng nhập giá trị liên hệ." và không ghi gì
