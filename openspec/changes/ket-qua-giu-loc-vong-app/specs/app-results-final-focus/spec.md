## ADDED Requirements

### Requirement: Nội dung đã xong giữ mọi vòng, mở sẵn chung kết (App)
Tab "Kết quả" của App ở nội dung đã có bục trao giải SHALL liệt kê mọi trận của nội dung (chip và menu "Tới vòng" đủ các vòng) và SHALL mở sẵn hộp vòng chứa trận chung kết loại trực tiếp, các vòng khác gập.

#### Scenario: Nội dung loại trực tiếp đã xong
- **WHEN** người xem mở tab Kết quả của nội dung đã có bục, có vòng 1 và chung kết
- **THEN** bảng có đủ hai hộp vòng, có menu "Tới vòng", chỉ hộp Chung kết mở; chạm hộp vòng 1 thì thấy trận vòng 1

#### Scenario: Không xác định được chung kết
- **WHEN** nội dung đã có bục nhưng không có vòng loại trực tiếp (vd chỉ vòng tròn)
- **THEN** bảng giữ hành vi cũ: hộp mặc định theo `defaultResultsRoundKey`, mọi trận vẫn có
