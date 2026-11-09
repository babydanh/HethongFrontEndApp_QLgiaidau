## ADDED Requirements

### Requirement: Nút đổi giao giữa thanh dưới

The court scoreboard SHALL show one serve button on the middle of the bottom bar, between the two teams' +/- buttons, for a user who can change the score and when a serving team is known. Pressing it MUST take one lose-serve step (doubles: serve 1 -> serve 2 -> other team serve 1; singles: other team) without changing the score, and that step MUST be one undo step.

#### Scenario: Nút ở giữa thanh dưới
- **WHEN** trọng tài có quyền chấm điểm và đã có đội giao
- **THEN** có đúng một nút "Đổi giao" cùng hàng với −/+, nằm giữa hai cụm và đúng giữa chiều ngang màn hình (ngang và dọc)

#### Scenario: Bấm nút đi từng bước
- **WHEN** đội 1 đang giao Giao 1 và trọng tài bấm nút một lần
- **THEN** đội 1 giao Giao 2, điểm giữ nguyên
- **AND** bấm lần nữa thì đội 2 giao Giao 1, điểm giữ nguyên
- **AND** mỗi lần hoàn tác trả lại một bước

#### Scenario: Tên nút theo bước kế tiếp
- **WHEN** đánh đôi, đã qua lượt giao mở đầu và đang Giao 1
- **THEN** nút ghi "Đổi tay" (bấm sang Giao 2)
- **AND** khi đang Giao 2, đang lượt giao mở đầu hoặc đánh đơn, nút ghi "Đổi giao" (bấm sang đội kia Giao 1)
- **AND** Lite và side-out nghiêm ngặt dùng chung quy tắc này; điểm không đổi

#### Scenario: Người xem hoặc chưa có đội giao
- **WHEN** người dùng chỉ xem, hoặc chưa chọn đội giao
- **THEN** không có nút "Đổi giao"

#### Scenario: Cả Lite có lượt giao
- **WHEN** trận Lite mà sân vẫn theo lượt giao side-out (có nhãn Giao 1/Giao 2)
- **THEN** có nút "Đổi giao" như trận thường

#### Scenario: Sân rally không có lượt giao
- **WHEN** sân chấm theo luật rally (không có Giao 1/Giao 2)
- **THEN** không có nút "Đổi giao"
