## ADDED Requirements

### Requirement: Đội nhận bấm điểm khi đội giao thua pha ở pickleball side-out
Hệ thống SHALL cho phép bấm "+" của đội đang nhận bóng trong side-out; thao tác này coi là đội giao thua pha: không ai được điểm, Giao 1 chuyển Giao 2, Giao 2 đổi giao sang đội nhận; đánh đơn đổi giao ngay.

#### Scenario: Đôi, Giao 1 thua pha
- **WHEN** đội A đang Giao 1 ở 3-2 và người chấm bấm "+" của đội B
- **THEN** điểm vẫn 3-2, lời hô thành "3 - 2 - 2", thông báo nêu đội A thua pha và không ai được điểm

#### Scenario: Mở màn 0-0-2 thua pha
- **WHEN** ván bắt đầu 0-0-2 và đội nhận bấm "+"
- **THEN** đổi giao ngay sang đội nhận, lời hô "0 - 0 - 1"

### Requirement: Hiển thị người đang giao ở cầu lông, bóng bàn, tennis
Hệ thống SHALL hiện "● GIAO" dưới tên đội đang giao theo luật từng môn mà không đổi cách bấm điểm.

#### Scenario: Bóng bàn đổi giao mỗi 2 điểm
- **WHEN** đội A giao đầu và tổng điểm hai đội đạt 2
- **THEN** "● GIAO" chuyển sang đội B; từ 10-10 chuyển sau mỗi điểm

#### Scenario: Cầu lông ô giao
- **WHEN** đội giao có điểm chẵn
- **THEN** hiện "ô phải", điểm lẻ hiện "ô trái"

### Requirement: Tennis dùng cấu hình No-Ad, tie-break và set quyết định
Hệ thống SHALL áp dụng `noAd`, `tiebreakPoints` và `finalSetMode` (`TB7`, `TB10_FINAL`, `NO_TB_FINAL`, `MATCH_TB10`) khi tính game và set.

#### Scenario: No-Ad
- **WHEN** game ở 40-40 và `noAd` bật, một đội thắng điểm kế tiếp
- **THEN** đội đó thắng game, không có AD

#### Scenario: Match tie-break thay set 3
- **WHEN** hai đội hoà 1-1 set và `finalSetMode` là `MATCH_TB10`
- **THEN** set quyết định là tie-break 10 điểm hơn 2 điểm

### Requirement: Bóng đá có hậu quả cho thẻ và thay người
Hệ thống SHALL hỏi số áo khi ghi thẻ, đổi thẻ vàng thứ hai của cùng cầu thủ thành thẻ đỏ, đếm cầu thủ trên sân, chặn thay người quá giới hạn và chỉ cho ghi bàn khi đang trong hiệp.

#### Scenario: Vàng thứ hai
- **WHEN** cầu thủ số 7 đội A nhận thẻ vàng lần hai
- **THEN** ghi thêm thẻ đỏ cho số 7 và đội A còn 10 người

#### Scenario: Ghi bàn lúc nghỉ giữa hiệp
- **WHEN** trạng thái là "Nghỉ giữa hiệp" và người chấm bấm thêm bàn
- **THEN** hiện cảnh báo và không ghi bàn
