## ADDED Requirements

### Requirement: Ô điểm chữ tự do được đọc kèm cờ cần xem

Màn nhập Excel SHALL bỏ qua số dính chữ (`4P`, `6xx`) và số đứng sau `Top`, `Giải`, `Hạng`, `Vòng`, `Lần`, `Bảng`, `Năm`, và SHALL ưu tiên điểm ELO 100–999 trước điểm DUPR. Ô có khoảng điểm SHALL mang cờ `RANGE`, ô có nhiều điểm khác nhau SHALL mang cờ `MULTIPLE`, ô có chữ số mà không đọc ra điểm SHALL mang cờ `UNREADABLE`. Cột có số ô ELO nhiều hơn số ô DUPR SHALL đổi các ô DUPR thành ELO nhân 100, cờ `CONVERTED`.

#### Scenario: Số hạng không bị đọc thành điểm

- **WHEN** ô điểm là `Top 8 CCTV 610`
- **THEN** điểm là 610 thang ELO, không có cờ

#### Scenario: Ô không đọc được điểm

- **WHEN** ô điểm là `tầm 6xx`
- **THEN** dòng không có điểm và mang cờ `UNREADABLE`

#### Scenario: Ô 6.2 trong cột ELO

- **WHEN** cột điểm có `620`, `6.2`, `605`
- **THEN** ô `6.2` đọc 620 thang ELO và mang cờ `CONVERTED`

### Requirement: Đôi gộp từ hai dòng gửi điểm từng VĐV

Khi hai dòng gộp thành một đôi, dòng đôi SHALL giữ `player1Elo` và `player2Elo` và item gửi `POST /api/v1/tournaments/:id/roster-import` SHALL mang hai trường này thay cho `elo`. Dòng không có điểm từng VĐV SHALL gửi `elo` như cũ. Bỏ VĐV 2 SHALL bỏ `player2Elo`.

#### Scenario: Đôi có điểm cả hai VĐV

- **WHEN** hai dòng STT 1 có điểm `620` và `605`
- **THEN** item có `player1Elo: 620`, `player2Elo: 605`, `eloSource: 'ELO'` và không có `elo`

#### Scenario: Dòng không có điểm từng VĐV

- **WHEN** một dòng đơn có `elo: 620`
- **THEN** item có `elo: 620` và không có `player1Elo`

### Requirement: Thẻ xem trước hiện điểm từng VĐV và tổng đôi

Thẻ đôi SHALL hiện `Điểm trình: 620 + 605 · tổng 1225` (key `rosterScoreLine`, `rosterScoreTotal`) khi dòng có điểm; điểm có cờ SHALL tô vàng kèm lý do (key `rosterScoreFlagRange`, `rosterScoreFlagMultiple`, `rosterScoreFlagConverted`, `rosterScoreFlagUnreadable`) ở cả `app_vi.arb` và `app_en.arb`. Chi tiết participant SHALL NOT liệt kê `memberElos` thành câu trả lời.

#### Scenario: Đôi có hai điểm

- **WHEN** dòng đôi có `player1Elo` 620 và `player2Elo` 605
- **THEN** thẻ hiện `620 + 605 · tổng 1225`

#### Scenario: Dòng không có điểm

- **WHEN** dòng không có điểm và không có cờ điểm
- **THEN** thẻ không có dòng điểm trình
