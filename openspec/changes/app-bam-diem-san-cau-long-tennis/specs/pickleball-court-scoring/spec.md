## ADDED Requirements

### Requirement: Sân pickleball hiện người nhận

The pickleball court view SHALL mark the receiver with a dashed outline and the label NHẬN on the cell diagonal to the server, in doubles and in singles, and MUST NOT show a receiver when there is no serving team.

#### Scenario: Đôi, người giao ở ô phải
- **WHEN** đội 1 giao và người giao đứng ô phải
- **THEN** viền NHẬN nằm ở ô phải của đội 2 (chéo), không phải ô trái

#### Scenario: Chưa biết đội giao
- **WHEN** chưa có đội giao
- **THEN** không hiện NHẬN

### Requirement: Trận đơn pickleball đặt người nhận chéo người giao

In singles the receiving player SHALL stand in the cell diagonal to the server, whatever the receiving player's own score is, and the other cell of that team MUST be empty. Scoring, serve changes and saved data MUST stay as they are.

#### Scenario: Đơn, đội giao 4 điểm và đội nhận 3 điểm
- **WHEN** đội 1 giao với 4 điểm (người giao ở ô phải) và đội 2 đang 3 điểm
- **THEN** người đội 2 đứng ô phải (chéo người giao) và có viền NHẬN, dù 3 điểm là lẻ

#### Scenario: Điểm đổi, ô đổi theo
- **WHEN** đội giao ghi thêm một điểm (5 điểm, người giao sang ô trái)
- **THEN** người nhận cũng sang ô trái của đội mình
