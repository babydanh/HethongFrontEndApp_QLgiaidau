## ADDED Requirements

### Requirement: Sân hiển thị người giao và người nhận

The badminton and tennis scoring screen of a strict (non-Lite) match SHALL show the court as two halves, team 1 and team 2, each cell holding one player at the position the player stands in; the server MUST carry a serve chip and the receiver on the diagonal opposite cell MUST carry a dashed receive outline. Each team SHALL be drawn facing the net, so a team's right court is the bottom cell of team 1 and the top cell of team 2 in landscape.

#### Scenario: Cầu lông đôi, đội 2 giao điểm chẵn
- **WHEN** đội 2 có điểm giao 10 (chẵn) và VĐV `danh` giao
- **THEN** chip GIAO nằm ở ô phải của đội 2 (ô trên), viền NHẬN nằm ở ô phải của đội 1 (ô dưới), số điểm của đội 2 có khung vàng

#### Scenario: Cầu lông đơn điểm lẻ
- **WHEN** đội 1 giao với điểm 7 (lẻ) ở trận đơn
- **THEN** người giao đứng ô trái, ô còn lại của đội đó để trống mờ, và viền NHẬN ở ô trái chéo của đội 2

#### Scenario: Không có tên VĐV
- **WHEN** trận không có danh sách VĐV của một đội
- **THEN** ô hiện tên đội thay cho tên VĐV, không hiện ô trống nhầm là VĐV, và chip GIAO vẫn ở đúng ô

#### Scenario: Trận Lite hoặc bóng bàn
- **WHEN** trận là Lite/Super Lite hoặc môn bóng bàn
- **THEN** màn chấm điểm giữ panel hiện tại, không hiện sân mới

### Requirement: Người giao theo luật cầu lông

For badminton the server SHALL be derived from the rally-point rule: the team that won the last rally serves; the server stands in the right court when its team score is even and in the left court when odd; in doubles the pair swaps cells after each rally the serving team wins and the receiving team MUST NOT swap; a new game SHALL start with the previous game's winner serving, and game 1 with the picked first server.

#### Scenario: Đôi thắng pha khi đang giao
- **WHEN** đội 1 đang giao và thắng pha, từ 19-17 lên 20-17
- **THEN** hai VĐV đội 1 đổi ô và VĐV giao là người vừa chuyển sang ô phải (điểm 20 chẵn)

#### Scenario: Đội nhận thắng pha
- **WHEN** đội nhận thắng pha
- **THEN** đội đó cầm giao, không ai trong hai đội đổi ô, người giao đứng ô theo điểm chẵn lẻ mới của đội đó

#### Scenario: Chưa biết ai thắng pha trước
- **WHEN** màn vừa tải lại giữa set hoặc trọng tài vừa bấm `−`
- **THEN** chip GIAO và NHẬN ẩn tới khi có điểm kế, màn không đoán người giao

### Requirement: Người giao theo luật tennis

For tennis the serving team SHALL alternate each game starting from the picked first server, and the server SHALL stand in the right (deuce) court when the points of the game are even and in the left (ad) court when odd. A tie-break counts as one game: its first point is served by the game server and the serve changes every 2 points.

In doubles the server player SHALL be the team player at index (own service game count) mod 2, counted from that team's picked first server.

#### Scenario: Game thường 15-0
- **WHEN** đội 1 giao và đang 15-0 (tổng điểm 1)
- **THEN** người giao đứng ô trái (Ad) và người nhận ở ô trái chéo của đội 2

#### Scenario: Tie-break
- **WHEN** tie-break đang 3-2 và đã chơi 5 điểm
- **THEN** đội giao đổi sau mỗi 2 điểm đúng theo `tennisServer`, và ô giao theo chẵn lẻ của điểm tie-break

#### Scenario: Đôi luân phiên người giao
- **WHEN** đội 1 giao game 1 bằng VĐV A và tới lượt giao kế tiếp của đội 1 (game 3)
- **THEN** người giao là VĐV B

#### Scenario: Tennis đơn
- **WHEN** trận đơn
- **THEN** không có bước chọn người trong đội, chỉ chọn đội giao đầu

### Requirement: Chọn người giao đầu thay cho nút Đổi giao

The scoring screen MUST NOT show a "Đổi giao" button for badminton and tennis. The referee SHALL pick the first server by tapping a player cell while the game is at 0-0 with no point scored, and the `⋯` menu SHALL offer "Chọn người giao" to correct it later.

#### Scenario: Bấm ô lúc 0-0
- **WHEN** trọng tài bấm ô VĐV của đội 2 khi tỷ số 0-0
- **THEN** VĐV đó là người giao đầu, chip GIAO chuyển tới ô đó và ô nhận cập nhật theo

#### Scenario: Bấm ô khi đã có điểm
- **WHEN** trọng tài bấm một ô VĐV khi đã có điểm
- **THEN** không đổi người giao (chỉ `⋯` → "Chọn người giao" mới sửa) và không có thay đổi điểm

### Requirement: Kéo thả và bấm thao tác dùng luật của pickleball

Long-pressing a player or the GIAO chip and dropping it SHALL swap cells, switch ends or set the server by the `resolveCourtDrop` rules. Every change MUST go through the notifier so it is undoable, and each drop MUST also be available as a tap action and a semantics action.

#### Scenario: Đổi ô trong đôi cầu lông
- **WHEN** trọng tài nhấn giữ VĐV A rồi thả lên đồng đội B
- **THEN** A và B đổi ô phải/trái, người giao đổi theo ô, Hoàn tác trả lại

#### Scenario: Đổi sân bằng kéo
- **WHEN** trọng tài kéo một VĐV sang nửa sân đội kia
- **THEN** hai đội đổi nửa sân và Hoàn tác trả lại

#### Scenario: Trận đơn
- **WHEN** trận đơn và trọng tài kéo VĐV vào ô trống hoặc nửa sân của mình
- **THEN** không có viền sáng và không ghi thay đổi nào, còn kéo sang nửa sân đội kia vẫn đổi sân

#### Scenario: Tennis đôi đội đang giao
- **WHEN** trọng tài kéo VĐV của đội đang giao lên đồng đội
- **THEN** không có viền sáng và không đổi ô, còn đội nhận thì đổi ô được

#### Scenario: Kéo chip GIAO sang đội kia
- **WHEN** trọng tài nhấn giữ chip GIAO rồi thả lên VĐV đội kia
- **THEN** VĐV đó là người giao, đội đó cầm giao, và Hoàn tác trả lại người giao cũ

#### Scenario: Không kéo được
- **WHEN** người dùng TalkBack hoặc chỉ bấm một ô VĐV khi đã có điểm
- **THEN** nhận được các thao tác tương đương: "Đổi chỗ phải/trái" (chỉ đôi), "Giao tại đây", không có thao tác nào cho người đang giao ngoài đổi sân

### Requirement: Hoàn tác trả lại đúng người giao

Undo SHALL be repeatable up to 50 steps and MUST restore points, game points, the server and the receiver exactly as before the undone step; the undo button MUST be disabled when there is nothing to undo.

#### Scenario: Hoàn tác liên tiếp
- **WHEN** trọng tài bấm cộng điểm 3 lần rồi Hoàn tác 3 lần
- **THEN** tỷ số và người giao trở lại đúng như trước lần cộng đầu tiên

#### Scenario: Không có gì để hoàn tác
- **WHEN** vừa vào màn hoặc đã hoàn tác hết
- **THEN** nút Hoàn tác tắt và bấm không làm gì

#### Scenario: Sau khi chốt set
- **WHEN** set đã chốt
- **THEN** bước hoàn tác của set cũ không còn khôi phục được

### Requirement: Chip nhắc luật

The screen SHALL show a single rule chip only when relevant: for badminton "Điểm set" when a team wins the game with the next point, "Điểm vàng" at 29-29, the 60 second interval and change of ends already defined by `rallyServeBanner`; for tennis "Game point", "Deuce", the advantage holder, "Điểm quyết định" in No-Ad, the tie-break target with serve change every 2 points, and change of ends after odd-numbered games.

#### Scenario: Điểm set cầu lông
- **WHEN** tỷ số 20-17 với mốc 21 cách 2
- **THEN** chip "Điểm set · Đội 1" hiện

#### Scenario: Điểm vàng
- **WHEN** tỷ số 29-29
- **THEN** chip "Điểm vàng: ai được 30 thắng" hiện

#### Scenario: Không có việc cần nhắc
- **WHEN** tỷ số 5-3 giữa set
- **THEN** không hiện chip nào

#### Scenario: Đổi sân tennis
- **WHEN** vừa kết thúc game 1, 3 hoặc 5 của set
- **THEN** chip "Đổi sân" hiện tới điểm kế
