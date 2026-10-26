## ADDED Requirements

### Requirement: Ghép cặp thủ công trong màn quản lý
Màn quản lý SHALL có sheet ghép cặp thủ công: danh sách VĐV đang chờ cặp của hạng mục được chọn (tìm kiếm không dấu), chọn 2 người để ghép hoặc kéo một người thả lên người khác để thành cặp, giới hạn 24 VĐV mỗi lần, nút xáo trộn ngẫu nhiên thứ tự, đặt tên từng cặp; xác nhận gửi một lần `POST /tournaments/:id/pairing/batch` với payload giống Web.

#### Scenario: Ghép thủ công 2 người
- WHEN BTC chọn "Nguyễn A" rồi "Trần B" và đặt tên cặp "Chim Én"
- THEN nút xác nhận hiện "Ghép 1 cặp" và App gửi pairing/batch đúng payload; sau thành công cả hai rời danh sách chờ

#### Scenario: Kéo-thả trên mobile
- WHEN BTC long-press "Nguyễn A" và thả lên "Trần B"
- THEN hai người được đánh dấu thành một cặp trong sheet, có thể hoàn tác trước khi gửi

#### Scenario: Vượt giới hạn chọn
- WHEN BTC chọn VĐV thứ 25
- THEN sheet từ chối chọn và thông báo giới hạn 24

### Requirement: Ghép cặp tự động 3 chiến lược
Sheet ghép cặp SHALL có lựa chọn tự động gồm 3 chiến lược RANDOM / ELO_BALANCED / SAME_LEVEL kèm mô tả ngắn như Web; xác nhận gọi `POST /tournaments/:id/pairing/generate`.

#### Scenario: Ghép tự động theo ELO
- WHEN hạng mục đôi có 10 VĐV chờ và BTC chọn "Cân bằng ELO"
- THEN App gửi pairing/generate với strategy tương ứng và danh sách cập nhật thành 5 cặp
