## ADDED Requirements
### Requirement: Playoff nhánh thắng/thua vẽ bracket
Tab Playoff công khai SHALL vẽ mỗi nhánh thành các cột thẻ trận nối bằng đường kẻ, hiển thị tối đa 3 vòng liền nhau.

#### Scenario: Cửa sổ trượt theo vòng
- **WHEN** nhánh thắng (kèm chung kết tổng) có 5 vòng và vòng đang diễn ra là vòng 1
- **THEN** hiện vòng 1–3, bấm "Vòng sau" 3 lần thì hiện vòng 3–5 và không còn vòng 1

#### Scenario: Bên chưa có đội
- **WHEN** một bên của trận chưa có đội và trận nguồn mã W1 đưa đội thắng sang
- **THEN** bên đó ghi "Thắng W1"

### Requirement: BTC và admin chấm điểm từ tab công khai
Bấm trận ở tab Bảng đấu công khai SHALL mở popup nhập điểm khi người xem là admin hoặc người quản lý giải và trận có đủ hai bên, không phải BYE.

#### Scenario: Người quản lý bấm trận
- **WHEN** người quản lý giải bấm thẻ trận có hai đội
- **THEN** hiện `MatchScoreEntryChooser`, không hiện popup "Xem trận"
