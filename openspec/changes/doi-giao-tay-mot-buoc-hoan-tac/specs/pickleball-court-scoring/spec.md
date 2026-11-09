## MODIFIED Requirements

### Requirement: Trái bóng chỉ người đang giao

The court view SHALL show a ball token on the serving player; dragging it onto a teammate SHALL make that teammate the server; dragging it onto an opponent SHALL make the opponent team serve at any score without changing the points; tapping the server in doubles SHALL offer switching serve 1 <-> 2 without changing the team, the points or the opening flag. Each manual serve change that changes something MUST be exactly one undo step.

#### Scenario: Đổi đội giao
- **WHEN** luật side-out và trọng tài kéo trái bóng sang VĐV đội kia
- **THEN** đội kia thành đội giao và VĐV đó là người giao

#### Scenario: Đổi đội giao ở mọi tỉ số, không đổi điểm
- **WHEN** tỉ số set hiện tại khác 0-0 và trọng tài đổi đội giao bằng tay
- **THEN** đội kia giao ở Giao 1, hết mở màn (`openingDone` true), điểm giữ nguyên
- **AND** ở 0-0 thì đội kia giao Giao 1 và vẫn là mở màn (`openingDone` false)
- **AND** chọn đúng đội đang giao thì không có gì thay đổi và không tạo bước hoàn tác

#### Scenario: Đổi Giao 1 <-> Giao 2
- **WHEN** đánh đôi và trọng tài chạm người đang giao rồi chọn số giao kia
- **THEN** số giao đổi, đội giao, điểm và cờ mở màn giữ nguyên, trái bóng sang đồng đội
- **AND** đánh đơn không có thao tác này

#### Scenario: Một lần hoàn tác cho một lần đổi giao
- **WHEN** trọng tài vừa đổi đội giao hoặc đổi số giao bằng tay rồi bấm hoàn tác một lần
- **THEN** đội giao, số giao, cờ mở màn, điểm và sân trở về đúng như ngay trước thao tác
