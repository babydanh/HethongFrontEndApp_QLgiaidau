## ADDED Requirements

### Requirement: Integration test bấm điểm pickleball side-out trên emulator
Bộ test SHALL bấm qua panel thật và kiểm tra lời hô, điểm và thông báo đúng luật side-out cho đôi và đơn.

#### Scenario: Đôi đi hết Giao 1, Giao 2, đổi giao
- **WHEN** đội A giao, ghi điểm rồi đội nhận bấm "+" hai lần liên tiếp
- **THEN** lời hô đi Giao 1, Giao 2 rồi sang đội B, điểm không đổi ở hai lần thua pha

#### Scenario: Đơn mất giao đổi ngay
- **WHEN** trận đơn và đội nhận bấm "+"
- **THEN** đổi giao ngay, không có Giao 2

### Requirement: Integration test cầu lông và bóng bàn
Bộ test SHALL kiểm tra "● GIAO", ô phải/trái, đổi giao mỗi 2 điểm, 10-10 và deuce.

#### Scenario: Bóng bàn đổi giao mỗi 2 điểm
- **WHEN** hai đội ghi tổng 2 điểm từ đầu game
- **THEN** "● GIAO" chuyển sang đội kia; từ 10-10 chuyển sau mỗi điểm

#### Scenario: Cầu lông 20-20 chưa chốt được set
- **WHEN** tỉ số 20-20 rồi một đội ghi 1 điểm
- **THEN** set chưa kết thúc cho tới khi hơn 2 điểm

### Requirement: Integration test tennis
Bộ test SHALL kiểm tra điểm game, Deuce/Advantage, No-Ad, tie-break 6-6 và match tie-break 10 điểm.

#### Scenario: No-Ad tới 40-40
- **WHEN** cấu hình No-Ad và tỉ số 40-40, một bên ghi điểm
- **THEN** bên đó thắng game, không hiện lợi thế

#### Scenario: Dữ liệu cấu hình rỗng
- **WHEN** trận không có cấu hình luật
- **THEN** panel dùng luật chuẩn, không lỗi

### Requirement: Integration test bóng đá
Bộ test SHALL kiểm tra ghi bàn, thẻ vàng thứ hai thành đỏ, dưới 7 người dừng trận và chặn ghi bàn ngoài hiệp.

#### Scenario: Hai thẻ vàng thành đỏ
- **WHEN** cùng một cầu thủ nhận 2 thẻ vàng
- **THEN** thẻ đỏ được ghi và cầu thủ rời sân

#### Scenario: Ghi bàn ngoài hiệp bị chặn
- **WHEN** trận ở nghỉ giữa hiệp và bấm ghi bàn
- **THEN** bàn thắng không được ghi, hiện cảnh báo
