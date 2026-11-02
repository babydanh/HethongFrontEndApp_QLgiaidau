## RENAMED Requirements

- FROM: `### Requirement: Sân Pickleball luôn nằm ngang và kẻ vạch như sân thật`
- TO: `### Requirement: Sân Pickleball dựng theo hướng màn hình và kẻ vạch như sân thật`

- FROM: `### Requirement: Hoàn tác và khôi phục là icon, màn ngang xếp hàng`
- TO: `### Requirement: Hoàn tác, khôi phục và đổi sân nằm trong menu ⋯`

## MODIFIED Requirements

### Requirement: Sân Pickleball dựng theo hướng màn hình và kẻ vạch như sân thật

The court view SHALL render vertically (two teams above and below a horizontal net) when the screen is held upright and horizontally (aspect ratio 2:1, two teams left and right of a vertical net) when held sideways, in a light blue (team 1) and light orange (team 2) palette that follows the teams when the ends are switched, with boundary line, center line, kitchen line and net, and SHALL NOT show team names in the half headers. The left and right cells of each team MUST follow that team's view toward the net in both directions.

#### Scenario: Màn dọc
- **WHEN** trọng tài mở màn chấm điểm Pickleball ở màn dọc
- **THEN** sân dựng đứng vừa chiều rộng và chiều cao còn lại, đội ở nửa đầu nằm trên lưới và đội kia nằm dưới lưới, bếp sát lưới, tên VĐV rút gọn không tràn
- **AND** ô phải của nửa trên nằm bên trái màn hình, ô phải của nửa dưới nằm bên phải màn hình

#### Scenario: Màu theo đội
- **WHEN** hai đội đổi sân
- **THEN** nửa sân xanh vẫn thuộc đội 1 và nửa sân cam vẫn thuộc đội 2, nút + của mỗi đội mang màu đội đó

#### Scenario: Màn ngang
- **WHEN** trọng tài mở màn chấm điểm Pickleball ở màn ngang
- **THEN** sân nằm ngang tỉ lệ 2:1 rộng tối thiểu 240dp (khe thấp hơn thì cuộn), nửa trái có ô trái ở trên và ô phải ở dưới, nửa phải có ô phải ở trên và ô trái ở dưới

### Requirement: Chấm điểm bằng − và + trên sơ đồ

Each team SHALL have a minus, the score and a plus control inside the kitchen strip of its own half of the court, using the existing score update of the pickleball scoring; the court SHALL NOT have a separate score bar and the scoring tab SHALL NOT draw a second large score block; in side-out scoring the plus MUST be disabled for the non-serving team; users without scoring permission or a finished match MUST NOT be able to change scores from the court.

#### Scenario: Đội đỡ giao
- **WHEN** luật side-out và đội không giao
- **THEN** nút + của đội đó bị khoá

#### Scenario: Điểm nằm trong dải bếp
- **WHEN** trọng tài xem sân ở bất kỳ hướng nào
- **THEN** số điểm của mỗi đội nằm trong dải bếp của nửa sân đội đó, giữa các ô VĐV và lưới, và mỗi số điểm chỉ xuất hiện một lần trên tab

#### Scenario: Điểm về 0
- **WHEN** điểm của một đội là 0
- **THEN** nút − của đội đó bị khoá

### Requirement: Hoàn tác, khôi phục và đổi sân nằm trong menu ⋯

Undo, restore-automatic, auto-switch toggle and switch-ends SHALL be items of the ⋯ menu on the net and the court settings sheet MUST NOT exist; the menu SHALL also list the override item (strict preset only) and the quick-win item (only when the screen provides it); undo SHALL only restore court settings (at most 20 steps), never the score.

#### Scenario: Màn ngang
- **WHEN** điện thoại xoay ngang
- **THEN** sân nằm ngang dùng cả khe chấm điểm, không còn khối chấm điểm riêng xếp bên cạnh, và nút − + vẫn ≥ 44dp

#### Scenario: Xoay màn hình
- **WHEN** điện thoại xoay giữa dọc và ngang
- **THEN** sân và panel chấm điểm giữ nguyên State (không dựng lại, cú kéo hoặc lần lưu đang chạy không bị huỷ) và sân đổi hướng theo màn hình

#### Scenario: Hoàn tác
- **WHEN** trọng tài chọn Hoàn tác trong menu sau một thay đổi từ sân (đổi ô phải/trái, đổi người giao, đổi sân, tự đổi sân, khôi phục tự động)
- **THEN** ô phải/trái, người giao và trạng thái đổi sân trở về như trước thay đổi đó
- **AND** việc đổi ĐỘI giao bằng trái bóng không nằm trong lịch sử hoàn tác (đội giao thuộc logic điểm của panel chấm điểm, không thuộc trạng thái sân)

#### Scenario: Chưa có gì để hoàn tác
- **WHEN** lịch sử chỉnh sân rỗng
- **THEN** mục Hoàn tác bị khoá

#### Scenario: Đổi sân từ menu
- **WHEN** trọng tài chọn Đổi sân trong menu
- **THEN** hai đội đổi nửa sân và thiết lập được lưu như khi kéo VĐV sang đội kia

#### Scenario: Preset Lite không có Ngoại lệ
- **WHEN** preset Lite
- **THEN** menu không có mục Ngoại lệ

### Requirement: Luật side-out lấy từ luật trận, mặc định ở provider

The court context provider SHALL treat a match whose rule is side-out as side-out even before any serve state exists (team 1 serving, server number 1), so drawing, `apply` and `syncAutomatic` share one context; a match with rally rule or an existing serve state MUST behave as before; a Lite (open scoring) match MUST run as rally whatever its rule or a saved serve state say.

#### Scenario: Trận side-out vừa mở, kéo bóng
- **WHEN** luật side-out, chưa có trạng thái giao, 0-0, trọng tài kéo trái bóng sang đồng đội
- **THEN** người giao đổi và giữ nguyên (override không bị xoá bởi việc mở lượt giao)

#### Scenario: Điểm đầu tiên
- **WHEN** đội giao ghi điểm đầu tiên
- **THEN** người giao đầu tiên vẫn giao tiếp

#### Scenario: Trận Lite có luật side-out
- **WHEN** trận ở preset Lite, luật cấu hình là side-out và đã có trạng thái giao lưu từ trước
- **THEN** ngữ cảnh sân là rally, không có lượt giao để mất và cả hai đội cộng được điểm

### Requirement: Dùng được bằng trình đọc màn hình và không tràn bố cục

Every drop available by dragging SHALL also be available as a custom semantics action, the touch targets SHALL stay large enough, and the view MUST NOT raise a layout error for any slot at least 240 wide and 80 high.

#### Scenario: TalkBack đổi chỗ
- **WHEN** người dùng TalkBack chọn hành động "Đổi chỗ phải/trái" trên một VĐV của trận đôi
- **THEN** hai VĐV của đội đổi chỗ phải/trái như khi kéo thả

#### Scenario: Trận đơn
- **WHEN** trận đơn và người kéo thả VĐV vào ô trống hoặc nửa sân của mình
- **THEN** không có viền sáng và không có thay đổi nào được ghi

#### Scenario: Vùng chạm
- **WHEN** màn dọc
- **THEN** nút − +, nút ⋯ và các icon ở lưới có vùng chạm ≥ 44dp và trái bóng ≥ 48dp
- **AND** khi khe ngang thấp thì icon ở lưới được thu nhỏ nhưng vẫn ≥ 40dp, sân ngang cuộn khi khe thấp hơn mức vừa

#### Scenario: Hành động TalkBack không lặp
- **WHEN** TalkBack đọc các VĐV
- **THEN** "Đổi sân" chỉ có một lần cho cả sân, "Đổi chỗ phải/trái" chỉ ở trận đôi, "Giao bóng cho người này" không gắn cho người đang giao

## ADDED Requirements

### Requirement: Điều khiển ở lưới là icon

The net SHALL carry the call text (serving score, receiving score, plus the server number for doubles side-out) and icon-only controls: the ⋯ menu, finish set, pick the winner and lose serve; each icon SHALL have a tooltip and a screen-reader label, and the net SHALL NOT contain text buttons. Users without scoring permission SHALL see only the call text.

#### Scenario: Mất giao hợp một nút ở đánh đôi
- **WHEN** đôi side-out, người giao 1 đang giao và trọng tài bấm icon mất giao
- **THEN** quyền giao chuyển cho đồng đội (người giao 2) và lời hô hiện số giao 2

#### Scenario: Người giao 2 thua pha
- **WHEN** đôi side-out, người giao 2 đang giao và trọng tài bấm icon mất giao
- **THEN** quyền giao chuyển sang đội kia với số giao 1

#### Scenario: Đánh đơn mất giao
- **WHEN** đánh đơn side-out và trọng tài bấm icon mất giao
- **THEN** quyền giao chuyển thẳng sang đội kia

#### Scenario: Rally và Lite không có mất giao
- **WHEN** chế độ rally hoặc preset Lite
- **THEN** icon mất giao không hiển thị

#### Scenario: Không có quyền chấm
- **WHEN** người xem không có quyền chấm điểm
- **THEN** lưới chỉ còn lời hô, không có icon nào

### Requirement: Chọn đội thắng bằng popup

The trophy icon SHALL open a "pick the winner" popup with one button per team; tapping a team SHALL save the match result and close the scoring screen. A team that cannot win under the current preset SHALL be locked with an explanation, unless the exception switch is on and its reason is not empty.

#### Scenario: Đội đủ điều kiện thắng
- **WHEN** một đội đã thắng đủ số set theo cấu hình và trọng tài chạm tên đội đó trong popup
- **THEN** kết quả trận được lưu với đội đó thắng và màn chấm điểm đóng lại

#### Scenario: Chưa đội nào đủ điều kiện
- **WHEN** trận chưa kết thúc theo luật và Ngoại lệ tắt
- **THEN** cả hai nút tên đội bị khoá và popup nêu trận chưa đạt điều kiện kết thúc

#### Scenario: Ngoại lệ chưa có lý do
- **WHEN** Ngoại lệ bật nhưng ô lý do rỗng
- **THEN** các nút tên đội bị khoá cho tới khi nhập lý do

#### Scenario: Lưu lỗi
- **WHEN** lưu kết quả thất bại
- **THEN** màn chấm điểm không đóng và lỗi hiển thị trong vùng cảnh báo của tab

### Requirement: Chốt set bằng icon

The check icon SHALL finish the current set after a confirmation dialog that states the score; it SHALL be disabled while the set has no points. In the strict preset a set that is not yet decided MUST be refused when the exception switch is off, with the reason shown in the warning area of the tab.

#### Scenario: Chốt set đủ điều kiện
- **WHEN** tỉ số set là 11-7 và trọng tài chốt set rồi xác nhận
- **THEN** set được thêm vào dải set đã chốt và sân bắt đầu set mới 0-0

#### Scenario: Set chưa có điểm
- **WHEN** tỉ số set hiện tại là 0-0
- **THEN** icon chốt set bị khoá

#### Scenario: Strict chưa đủ điều kiện
- **WHEN** preset Strict, tỉ số 5-3, Ngoại lệ tắt và trọng tài xác nhận chốt set
- **THEN** set không được chốt và vùng cảnh báo nêu lý do

### Requirement: Preset Lite hiển thị sân chạy kiểu rally

When the preset is Lite, the pickleball scoring tab SHALL show the court with rally scoring (both teams can score, the team that wins a rally serves next), with no side-out rule and no exception switch.

#### Scenario: Cả hai đội cộng điểm ở Lite
- **WHEN** preset Lite và trọng tài bấm + của đội đang đỡ
- **THEN** điểm đội đó tăng và đội đó trở thành đội giao

### Requirement: Màn chấm điểm pickleball không còn thanh nút dưới

The pickleball scoring screen SHALL NOT draw the shared bottom bar (exception chip, quick-win, finish set and finish match buttons); their functions live on the court (net icons, ⋯ menu and popups) and in the dialogs they open. Other sports keep the bottom bar unchanged. In landscape the finished sets share the title row instead of a strip under it.

#### Scenario: Pickleball
- **WHEN** trọng tài mở màn chấm điểm pickleball
- **THEN** không có chip Ngoại lệ, nút Xử thắng, nút CHỐT SET hay nút CHỐT TRẬN ĐẤU ở cuối màn

#### Scenario: Môn khác
- **WHEN** trọng tài mở màn chấm điểm cầu lông
- **THEN** thanh nút dưới vẫn hiển thị như cũ

#### Scenario: Màn ngang
- **WHEN** pickleball ở màn ngang và đã chốt ít nhất một set
- **THEN** các set đã chốt nằm cùng hàng với tên trận
