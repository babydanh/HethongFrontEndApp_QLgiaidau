## ADDED Requirements

### Requirement: Màn Thông tin giải gọn

The tournament information page SHALL show the General, Identity and Contact groups already open, with an arrow-only header toggle, and SHALL NOT show a prizes group.

#### Scenario: Mở màn
- **WHEN** người quản lý mở "Thông tin giải"
- **THEN** ba nhóm đều mở sẵn, không có nhóm "Giải thưởng"
- **AND** tiêu đề nhóm không có chữ "Thu gọn" hay "Mở"

### Requirement: Nút Ẩn tiêu đề

The page SHALL offer the hide-title option as one short chip button without a description line.

#### Scenario: Bật ẩn tiêu đề
- **WHEN** người quản lý bấm nút "Ẩn tiêu đề"
- **THEN** nút chuyển sang trạng thái chọn (tô màu chính) và giá trị `hideFeaturedCardText` được lưu như trước
