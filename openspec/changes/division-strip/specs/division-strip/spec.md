## ADDED Requirements

### Requirement: Dải chọn nội dung dùng chung
Ứng dụng SHALL chọn nội dung thi đấu bằng một dải chip nằm ngang, mỗi chip một dòng gồm tên nội dung và số VĐV (kèm "/tối đa" khi có), không icon và không chấm màu, vùng bấm tối thiểu 44dp.

#### Scenario: Chọn nội dung
- **WHEN** người dùng bấm chip "Đôi Nam"
- **THEN** chip đó được đánh dấu đang chọn và màn lọc theo nội dung đó

#### Scenario: Chip đang chọn nằm ngoài khung
- **WHEN** có nhiều nội dung và nội dung đang chọn nằm ngoài màn hình
- **THEN** dải tự cuộn để chip đang chọn nằm trong khung nhìn

### Requirement: Ẩn khi chỉ có một nội dung
Dải SHALL không hiện khi chỉ có một nội dung và không có chip "Quản lý".

#### Scenario: Giải một nội dung
- **WHEN** giải chỉ có 1 nội dung và người xem không phải BTC
- **THEN** không hiện dải chọn

### Requirement: Chip "Tất cả" và chip "Quản lý"
Dải SHALL hỗ trợ chip "Tất cả" đứng đầu khi được bật, và chip chữ "Quản lý" đứng cuối chỉ khi nơi dùng cung cấp hành động quản lý.

#### Scenario: Màn Trực tiếp
- **WHEN** chọn "Tất cả"
- **THEN** bộ lọc nội dung được bỏ (không có nội dung nào được chọn)

#### Scenario: BTC mở quản lý
- **WHEN** BTC bấm chip "Quản lý" ở tab Bảng đấu
- **THEN** mở màn quản lý nội dung có sẵn
