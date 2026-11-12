## ADDED Requirements

### Requirement: Bảng Kết quả không có chip Trễ giờ và Tranh chấp
Bảng Kết quả của App SHALL chỉ có các chip Tất cả, Đang diễn ra, Sắp tới, Đã kết thúc và, cho BTC, Chưa xong.

#### Scenario: Bấm dòng trễ giờ ở checklist
- **WHEN** BTC bấm "Đi tới" ở việc "trễ giờ" trong popup tiến trình
- **THEN** tab Kết quả mở với chip "Chưa xong" được chọn

#### Scenario: Bấm dòng tranh chấp ở checklist
- **WHEN** BTC bấm "Đi tới" ở việc "tranh chấp"
- **THEN** tab Kết quả mở ở "Tất cả", không có chip nào được chọn thêm
