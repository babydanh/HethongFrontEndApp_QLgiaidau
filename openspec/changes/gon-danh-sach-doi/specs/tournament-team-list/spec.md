# Spec Delta

## Purpose

Cách App hiển thị danh sách đội và VĐV theo nội dung trong trang chi tiết giải: gọn, đọc được ngay trên điện thoại, mỗi lần mở một nội dung.

## ADDED Requirements

### Requirement: Cột số người của hàng nội dung thẳng hàng
Hàng nội dung SHALL hiện số người ở một cột bề rộng cố định căn phải, cùng vị trí cho mọi nội dung bất kể độ dài tên. Tên nội dung dài MUST cắt bằng dấu "…" trên một dòng, không đẩy cột số.

#### Scenario: Tên ngắn và tên dài
- **WHEN** một giải có nội dung "Đơn" và nội dung "Đôi Nam Nữ Linh Hoạt Trên 50 Tuổi"
- **THEN** số người của hai hàng có cùng mép phải và cùng vị trí ngang, tên dài bị cắt "…"

#### Scenario: Nội dung không giới hạn số người
- **WHEN** nội dung không có số tối đa
- **THEN** cột số chỉ hiện số hiện có, vẫn nằm đúng cột

### Requirement: Mỗi lần chỉ mở một nội dung ở tab Danh sách đội
Khi giải có nhiều nội dung, tab "Danh sách đội" SHALL hiện danh sách đội ngay dưới hàng nội dung đang mở và MUST chỉ mở tối đa 1 nội dung. Bấm nội dung khác SHALL mở nội dung đó và thu nội dung cũ; bấm lại nội dung đang mở SHALL thu nó.

#### Scenario: Chuyển nội dung
- **WHEN** nội dung A đang mở và người xem bấm nội dung B
- **THEN** đội của B hiện ngay dưới hàng B, đội của A không còn hiện

#### Scenario: Thu nội dung đang mở
- **WHEN** người xem bấm lại nội dung đang mở
- **THEN** danh sách đội của nội dung đó thu lại, không nội dung nào mở

### Requirement: Đội đôi hiện sẵn hai thành viên dạng gọn
Hàng đội đôi SHALL hiện tên đội, icon trạng thái phí và các thành viên dạng chip nhỏ ngay bên dưới, không bấm để xổ và không cuộn màn hình. Bấm chip thành viên MUST mở hồ sơ VĐV đó; thành viên chưa có hồ sơ hiện thông báo hiện có. Hàng đội đôi MUST NOT hiện dòng "Thành viên: …" và badge Elo.

#### Scenario: Đội đủ hai người
- **WHEN** đội đôi có 2 thành viên
- **THEN** hai chip hiện cạnh nhau dưới tên đội, mỗi chip có avatar và tên, tên dài bị cắt "…"

#### Scenario: Bấm thành viên
- **WHEN** người xem bấm chip của thành viên có tài khoản
- **THEN** App mở hồ sơ VĐV của thành viên đó

#### Scenario: Thành viên chưa có hồ sơ
- **WHEN** người xem bấm chip của thành viên không có tài khoản
- **THEN** App hiện thông báo hồ sơ đang được cập nhật, không điều hướng

### Requirement: Chip thành viên chỉ từ roster thật
Chip thành viên SHALL chỉ dựng từ roster API trả về. Khi roster rỗng, App MUST NOT dựng thành viên từ tên đội; hàng chỉ hiện tên đội.

#### Scenario: API trả roster rỗng
- **WHEN** đội có `members: []` trong phản hồi `/tournaments/:id/participants`
- **THEN** hàng hiện tên đội một lần, không có chip thành viên và không có ô chờ đồng đội

### Requirement: VĐV chưa có tài khoản hiện từ guestNames
Tab "Danh sách đội" SHALL hiện mỗi tên trong `guestNames` của Backend thành chip sau thành viên roster. Bấm chip khách MUST NOT mở hồ sơ của ai; App hiện thông báo hồ sơ đang cập nhật.

#### Scenario: Đội nhập Excel hai khách
- **WHEN** đội "Hà Nội Pickleball Team" có `members: []`, `guestNames: ["Lê Hoàng Nam", "Phạm Đức Huy"]`
- **THEN** hàng hiện tên đội và 2 chip "Lê Hoàng Nam", "Phạm Đức Huy", không có ô chờ đồng đội

#### Scenario: Bấm chip khách
- **WHEN** người xem bấm chip "Phạm Đức Huy"
- **THEN** App không điều hướng tới hồ sơ nào và hiện thông báo hồ sơ đang cập nhật

#### Scenario: Server chưa trả guestNames
- **WHEN** phản hồi không có `guestNames`
- **THEN** đội chỉ hiện tên đội, không chip

### Requirement: Đội đôi đang chờ đồng đội
Đội đôi có trạng thái `PENDING_PARTNER`, hoặc thuộc nội dung đôi và có đúng 1 thành viên thật, SHALL hiện thêm ô tròn viền đứt màu hổ phách chỉ có icon thêm người, không chữ. Chữ "Chờ đồng đội" MUST chỉ nằm ở tooltip và nhãn trợ năng. Ô này MUST NOT bấm được.

#### Scenario: Đăng ký một mình
- **WHEN** đội trong nội dung đôi chỉ có 1 thành viên
- **THEN** hàng hiện 1 chip thành viên và 1 ô icon viền đứt, không có chữ "Chờ đồng đội" trên màn hình

#### Scenario: Đội đã đủ người
- **WHEN** đội đôi có 2 thành viên và trạng thái khác `PENDING_PARTNER`
- **THEN** không hiện ô chờ đồng đội
