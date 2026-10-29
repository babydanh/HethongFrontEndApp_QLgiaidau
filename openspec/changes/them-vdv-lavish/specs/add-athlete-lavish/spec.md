## ADDED Requirements

### Requirement: Email nhập tay trùng tài khoản Sporto dẫn sang tìm tài khoản
Khi thêm VĐV bằng tab "Nhập tên" và Backend trả 409 với mã `EMAIL_BELONGS_TO_ACCOUNT`, popup SHALL hiện dải báo "Email này là tài khoản Sporto" cùng nút "Tìm tài khoản này"; bấm nút SHALL chuyển sang tab "Bạn bè & CLB" với ô tìm điền sẵn email đó và chạy tìm theo email. Popup SHALL NOT tự thêm VĐV và SHALL NOT đánh dấu danh sách là "chưa rõ kết quả".

#### Scenario: Email thuộc tài khoản
- **WHEN** nhập tên và email, bấm "Thêm VĐV", Backend trả 409 `EMAIL_BELONGS_TO_ACCOUNT`
- **THEN** hiện dải báo có nút "Tìm tài khoản này", ô tên và email giữ nguyên giá trị đã nhập

#### Scenario: Bấm Tìm tài khoản này
- **WHEN** bấm nút "Tìm tài khoản này" trên dải báo
- **THEN** tab "Bạn bè & CLB" được chọn, ô tìm chứa đúng email, và gọi tìm theo email một lần

#### Scenario: Lỗi khác
- **WHEN** Backend trả lỗi không phải `EMAIL_BELONGS_TO_ACCOUNT`
- **THEN** hành vi cũ giữ nguyên (làm mới danh sách, hiện thông báo lỗi)

### Requirement: Giao diện Lavish giữ nguyên hành vi
Hai tab của popup SHALL dùng thành phần Lavish và SHALL giữ nguyên các key `add-athlete-*` cùng luồng chọn, ghép đôi, thêm.

#### Scenario: Chọn ứng viên
- **WHEN** bấm hàng ứng viên có key `add-athlete-candidate-select-<userId>`
- **THEN** hàng được chọn và nút `add-athlete-candidate-submit` bật
