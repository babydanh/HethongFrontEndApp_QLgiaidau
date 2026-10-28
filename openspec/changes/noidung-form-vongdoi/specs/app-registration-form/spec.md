## ADDED Requirements

### Requirement: Soạn form đăng ký tuỳ biến
Màn Form đăng ký SHALL cho BTC thêm, đổi thứ tự, sửa và xoá câu hỏi tuỳ biến, và lưu toàn bộ vào `tournamentConfig.registrationForm` bằng `updateTournament` mà không làm mất các khoá khác của `tournamentConfig`.

#### Scenario: Đổi thứ tự rồi lưu
- **WHEN** BTC kéo câu hỏi thứ hai lên đầu rồi bấm Lưu
- **THEN** payload gửi đi có `fields` theo thứ tự mới và giữ nguyên các khoá khác của `tournamentConfig`

### Requirement: Họ tên và Số điện thoại cố định
Màn SHALL luôn hiện Họ và tên và Số điện thoại là bắt buộc và MUST NOT cho xoá hay lưu chúng thành câu hỏi tuỳ biến.

#### Scenario: Không xoá được câu hỏi hệ thống
- **WHEN** BTC xem danh sách câu hỏi
- **THEN** hai dòng Họ và tên, Số điện thoại không có thao tác xoá và không nằm trong `fields` khi lưu

### Requirement: Xoá câu hỏi có xác nhận
Xoá câu hỏi SHALL luôn có xác nhận; câu hỏi đã có người trả lời MUST cảnh báo rằng câu trả lời sẽ mất.

#### Scenario: Xoá câu hỏi đã có trả lời
- **WHEN** BTC vuốt xoá một câu hỏi đã có VĐV trả lời
- **THEN** hộp xác nhận nêu rõ câu trả lời sẽ mất, và câu hỏi chỉ bị xoá sau khi xác nhận

### Requirement: Loại câu hỏi
Mỗi câu hỏi SHALL thuộc một trong Văn bản, Số, Chọn một, Chọn nhiều; câu hỏi Chọn một/Chọn nhiều MUST có ít nhất 2 lựa chọn mới lưu được.

#### Scenario: Chọn một thiếu lựa chọn
- **WHEN** BTC bấm Lưu với câu hỏi Chọn một chỉ có 1 lựa chọn
- **THEN** không gửi yêu cầu lưu và hiện lỗi nêu tên câu hỏi
