## ADDED Requirements

### Requirement: Popup tạo bracket xếp đội vào bảng ngay
Khi BTC xác nhận popup tạo bracket Vòng bảng / Round Robin, App SHALL chia các đội đã duyệt của nội dung vào bảng theo lựa chọn xếp (ELO hoặc ngẫu nhiên) và lưu việc chia đó trước khi tạo bracket.

#### Scenario: Xếp theo ELO
- **WHEN** nội dung có 8 đội đã duyệt, 2 bảng, chọn xếp theo ELO
- **THEN** cấu hình gửi đi có 2 bảng chia rắn theo ELO giảm dần (bảng A nhận đội mạnh nhất), và `generateBracket` được gọi với `SEEDED`

#### Scenario: Xếp ngẫu nhiên
- **WHEN** chọn xếp ngẫu nhiên
- **THEN** mọi đội đã duyệt có mặt đúng một lần trong các bảng, số đội các bảng chênh nhau tối đa 1

#### Scenario: Backend từ chối danh sách đã xếp
- **WHEN** `generateBracket` trả 400 sau khi đã lưu bảng
- **THEN** App lưu lại cấu hình không có bảng rồi gọi `generateBracket` lần nữa

#### Scenario: Không có danh sách đội
- **WHEN** danh sách đội không tải được
- **THEN** App tạo bracket không kèm bảng như trước
