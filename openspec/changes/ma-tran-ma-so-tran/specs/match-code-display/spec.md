## ADDED Requirements

### Requirement: Ghép mã trận và tên tắt
App MUST hiển thị mã dạng `<matchCode><tên tắt bên 1><tên tắt bên 2>`, tên tắt là chữ cái đầu hai từ cuối mỗi tên (tên một từ thì một chữ), bỏ dấu, `Đ` thành `D`, chữ hoa; đánh đôi lấy VĐV thứ nhất mỗi bên. Kết quả MUST trùng với Web cho cùng đầu vào.

#### Scenario: Đủ hai bên
- **WHEN** `matchCode` là `DN1W2T3`, bên 1 "Nguyễn Văn An", bên 2 "Trần Thị Bình"
- **THEN** hiển thị `DN1W2T3VATB`

#### Scenario: Chưa biết đối thủ hoặc chờ một bên
- **WHEN** chưa có bên nào, hoặc chỉ bên 1 là "Nguyễn Văn An"
- **THEN** hiển thị `DN1W2T3`, hoặc `DN1W2T3VA`

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
