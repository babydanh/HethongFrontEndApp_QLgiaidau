## ADDED Requirements

### Requirement: Hiển thị mã trận kèm dấu `#`
App MUST hiển thị mã dạng `#<matchCode>`, với `matchCode` do Backend trả (không có `#`). Tên VĐV MUST NOT được ghép vào mã. Kết quả MUST trùng với Web cho cùng đầu vào.

#### Scenario: Có mã
- **WHEN** `matchCode` là `DDNTB-K1-T3` do Backend sinh từ nội dung "Đôi nam trung bình", dù hai bên đã hay chưa xác định
- **THEN** hiển thị `#DDNTB-K1-T3`

#### Scenario: Đơn nam trung bình
- **WHEN** `matchCode` là `DNTB-K1-T3` do Backend sinh từ nội dung "Đơn nam trung bình"
- **THEN** hiển thị `#DNTB-K1-T3`

### Requirement: Dự phòng khi thiếu mã
Khi `matchCode` thiếu hoặc `null`, App MUST giữ nhãn "Trận N" hiện tại và không lỗi parse.

#### Scenario: Backend cũ
- **WHEN** JSON trận không có `matchCode`
- **THEN** màn hình hiện "Trận N" như trước

### Requirement: Phạm vi hiển thị
App MUST hiện mã ở các màn nêu trong `proposal.md` và MUST NOT hiện ở overlay livestream và trận câu lạc bộ.

#### Scenario: Trận câu lạc bộ
- **WHEN** App hiển thị trận câu lạc bộ
- **THEN** không hiện mã trận
