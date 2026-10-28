## ADDED Requirements

### Requirement: Accordion cấu hình nội dung thi đấu
Sheet nội dung thi đấu SHALL chia thành các mục Cơ bản, Luật vòng, Ràng buộc ELO và Vòng bảng/thể thức; mỗi mục MUST hiện tóm tắt một dòng ở tiêu đề và chỉ một mục được mở tại một thời điểm.

#### Scenario: Mở một mục đóng mục đang mở
- **WHEN** BTC bấm tiêu đề mục "Ràng buộc ELO" khi mục "Cơ bản" đang mở
- **THEN** thân mục ELO hiện ra và thân mục Cơ bản ẩn đi

#### Scenario: Thể thức hiển thị tiếng Việt
- **WHEN** nội dung có `bracketType` là `SINGLE_ELIMINATION`
- **THEN** tóm tắt mục Cơ bản hiện "Loại trực tiếp" và không chứa chuỗi `SINGLE_ELIMINATION`

### Requirement: Xem minh hoạ thể thức
Sheet SHALL có mục "Xem minh hoạ thể thức" mở hộp thoại mô tả thể thức đang chọn bằng tiếng Việt (mô tả ngắn và diễn giải ví dụ).

#### Scenario: Mở minh hoạ
- **WHEN** BTC bấm "Xem minh hoạ thể thức" với thể thức Thụy Sĩ
- **THEN** hộp thoại hiện mô tả thể thức Thụy Sĩ

### Requirement: Nói rõ vì sao bị khoá
Khi nội dung đã có sơ đồ thi đấu, sheet SHALL hiện thông báo giải thích thể thức và luật vòng không đổi được, và Lưu vẫn chỉ gửi một lần khi bấm đúp.

#### Scenario: Đã có sơ đồ
- **WHEN** sheet mở với `lockContent` là true
- **THEN** thông báo khoá hiện ở đầu sheet và các lựa chọn thể thức bị vô hiệu
