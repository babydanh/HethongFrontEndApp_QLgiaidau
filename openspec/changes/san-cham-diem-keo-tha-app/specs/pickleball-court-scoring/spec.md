## ADDED Requirements

### Requirement: Sân Pickleball luôn nằm ngang và kẻ vạch như sân thật

The court view SHALL render horizontally (aspect ratio 2:1) in both portrait and landscape, in a light blue palette, with boundary line, center line, kitchen line and net, and SHALL NOT show team names in the half headers.

#### Scenario: Màn dọc
- **WHEN** trọng tài mở màn chấm điểm Pickleball ở màn dọc
- **THEN** sân nằm ngang vừa chiều rộng, tên VĐV rút gọn không tràn

### Requirement: Chấm điểm bằng − và + trên sơ đồ

Each team SHALL have a minus and plus control on the court that uses the existing score update of the pickleball panel; in side-out scoring the plus MUST be disabled for the non-serving team; users without scoring permission or a finished match MUST NOT be able to change scores from the court.

#### Scenario: Đội đỡ giao
- **WHEN** luật side-out và đội không giao
- **THEN** nút + của đội đó bị khoá

### Requirement: Kéo thả người trong sân bằng nhấn giữ

Long-pressing then dragging a player onto a teammate or the free area of the same half SHALL swap their left and right cells; dropping on the other half SHALL switch ends for both teams so the partner moves along; every change MUST go through the court notifier `apply` so it is saved and undoable.

#### Scenario: Đổi ô phải/trái
- **WHEN** trọng tài nhấn giữ VĐV A rồi kéo sang đồng đội B
- **THEN** A và B đổi chỗ phải/trái và được lưu

#### Scenario: Đổi sân
- **WHEN** trọng tài kéo VĐV A sang nửa sân đội kia
- **THEN** hai đội đổi sân, đồng đội của A đi theo

### Requirement: Trái bóng chỉ người đang giao

The court view SHALL show a ball token on the serving player; dragging it onto a teammate SHALL make that teammate the server; dragging it onto an opponent SHALL make the opponent team serve (side-out scoring only).

#### Scenario: Đổi đội giao
- **WHEN** luật side-out và trọng tài kéo trái bóng sang VĐV đội kia
- **THEN** đội kia thành đội giao và VĐV đó là người giao

### Requirement: Hoàn tác và khôi phục là icon, màn ngang xếp hàng

Undo, restore-automatic and auto-switch toggle SHALL be icon buttons on the court and the court settings sheet MUST NOT exist; in landscape the court and the set controls SHALL be laid out side by side.

#### Scenario: Màn ngang
- **WHEN** điện thoại xoay ngang
- **THEN** nếu khe đủ rộng cho cả sân (tối thiểu 240dp) và khối chấm điểm (tối thiểu 360dp, nhân theo cỡ chữ) thì sân ở bên trái và khối chấm điểm ở bên phải (khối phải cuộn được); khe hẹp hơn thì xếp dọc trong một vùng cuộn
- **AND** chữ số điểm của khối chấm điểm luôn cao ít nhất 28dp (đo bằng `PickleballPanel` thật: khối 304dp cho ~10dp nên bị loại; 360dp cho ~35dp; 384dp cho ~46dp)

#### Scenario: Xoay màn hình
- **WHEN** điện thoại xoay giữa dọc và ngang
- **THEN** sân và khối chấm điểm giữ nguyên State (không dựng lại, cú kéo hoặc lần lưu đang chạy không bị huỷ)

#### Scenario: Hoàn tác
- **WHEN** trọng tài bấm hoàn tác sau một thay đổi từ sân (đổi ô phải/trái, đổi người giao, đổi sân, tự đổi sân, khôi phục tự động)
- **THEN** ô phải/trái, người giao và trạng thái đổi sân trở về như trước thay đổi đó
- **AND** việc đổi ĐỘI giao bằng trái bóng không nằm trong lịch sử hoàn tác (đội giao thuộc logic điểm của panel chấm điểm, không thuộc trạng thái sân)

### Requirement: Mọi lần ghi sân đi qua một hàng đợi

Every court write (user action or automatic sync) SHALL go through one sequential queue, so two writes are never in flight together and reach the server in the order they were made; an automatic sync requested while a user action is queued MUST wait until the last action finishes; a failed write MUST NOT stop the writes queued behind it; an error of a user action MUST always be shown, while the repeating automatic sync reports a given error once.

#### Scenario: Bấm đúp
- **WHEN** trọng tài bấm hai lần liên tiếp (vd. công tắc tự đổi sân, hoặc hoàn tác) trong lúc lần ghi đầu còn chạy
- **THEN** hai lệnh ghi chạy lần lượt, không bao giờ cùng lúc

### Requirement: Luật side-out lấy từ luật trận, mặc định ở provider

The court context provider SHALL treat a match whose rule is side-out as side-out even before any serve state exists (team 1 serving, server number 1), so drawing, `apply` and `syncAutomatic` share one context; a match with rally rule or an existing serve state MUST behave as before.

#### Scenario: Trận side-out vừa mở, kéo bóng
- **WHEN** luật side-out, chưa có trạng thái giao, 0-0, trọng tài kéo trái bóng sang đồng đội
- **THEN** người giao đổi và giữ nguyên (override không bị xoá bởi việc mở lượt giao)

#### Scenario: Điểm đầu tiên
- **WHEN** đội giao ghi điểm đầu tiên
- **THEN** người giao đầu tiên vẫn giao tiếp

### Requirement: Nút − + chỉ khi trận đang diễn ra

The minus and plus controls SHALL be shown only to users with scoring permission while the match is in progress, and the side-out rule SHALL come from the match rule, not from whether a serve state exists yet.

#### Scenario: Trận chưa bắt đầu hoặc đã huỷ
- **WHEN** trận ở trạng thái chưa bắt đầu (SCHEDULED/PENDING/NOT_STARTED/UPCOMING) hoặc đã huỷ (CANCELLED)
- **THEN** sân không có nút − và +

#### Scenario: Trận side-out vừa mở
- **WHEN** luật trận là side-out và chưa có trạng thái giao
- **THEN** đội 1 là đội giao mặc định, trái bóng nằm ở đội 1 và nút + của đội 2 bị khoá


#### Scenario: Trận đã kết thúc hoặc đã huỷ
- **WHEN** trận đã kết thúc hoặc ở trạng thái CANCELLED
- **THEN** không có nút − và +, kéo thả và icon công cụ bị tắt (PAUSED/POSTPONED/SUSPENDED không có trong App, repository ánh xạ trạng thái lạ về scheduled)

#### Scenario: Chấm điểm mở
- **WHEN** luật trận là chấm điểm mở
- **THEN** cả hai đội đều được bấm +
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
- **THEN** nút − +, trái bóng và icon công cụ có vùng chạm ≥ 48dp; khe ngang thấp thì khối sân thu tối đa 0,92 (nút ≥ 40dp) và cuộn khi thấp hơn

#### Scenario: Hành động TalkBack không lặp
- **WHEN** TalkBack đọc các VĐV
- **THEN** "Đổi sân" chỉ có một lần cho cả sân, "Đổi chỗ phải/trái" chỉ ở trận đôi, "Giao bóng cho người này" không gắn cho người đang giao