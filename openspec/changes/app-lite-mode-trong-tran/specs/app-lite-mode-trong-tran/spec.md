## ADDED Requirements

### Requirement: Cờ cách tính điểm theo trận đè cờ giải
Hệ thống SHALL gộp `matchConfig.kind` và `matchConfig.scoringModel` của trận lên trên cùng `sportRules` khi đọc trận, nên cờ của trận thắng cờ của giải và các dấu như `mode: LITE` vẫn giữ. Payload socket không có `matchConfig` SHALL không làm mất cờ đã có.

#### Scenario: Trận side-out trên giải rally
- **WHEN** trận có `matchConfig` `{ kind: PICKLEBALL_SIDE_OUT, scoringModel: PICKLEBALL_SIDE_OUT }` còn `sportRules.scoringModel` là `RALLY_POINT_SET`
- **THEN** cấu hình luật của trận là side-out và `mode: LITE` vẫn còn

#### Scenario: Trận rally trên giải side-out
- **WHEN** trận có `matchConfig` `{ kind: PICKLEBALL_RALLY, scoringModel: RALLY_POINT_SET }` còn `sportRules.scoringModel` là `PICKLEBALL_SIDE_OUT`
- **THEN** cấu hình luật của trận là rally

#### Scenario: Socket thiếu field
- **WHEN** payload socket của trận không có `matchConfig`
- **THEN** cờ cách tính điểm trước đó của trận được giữ

### Requirement: Đổi cách tính điểm trong màn bấm điểm Lite
Menu "⋯" của sân pickleball SHALL có mục "Cách tính điểm" chỉ ở trận Lite. Mục SHALL chỉ bật khi trận 0-0 (mọi set kể cả set đang mở đều 0, chưa thắng set nào); đã có điểm thì SHALL khoá kèm lý do. Chọn xong SHALL gọi `PATCH /matches/:id/pickleball-scoring` với `{ "scoring": "SIDE_OUT" | "RALLY" }`.

#### Scenario: Đổi khi 0-0
- **WHEN** trọng tài trận Lite 0-0 mở mục "Cách tính điểm" và chọn Rally
- **THEN** App gọi PATCH với `{ "scoring": "RALLY" }` và bảng chấm chuyển sang rally ngay

#### Scenario: Đã có điểm
- **WHEN** trận Lite đã có điểm
- **THEN** mục "Cách tính điểm" bị khoá kèm lý do và không gọi PATCH

#### Scenario: Strict
- **WHEN** trận không phải Lite
- **THEN** menu không có mục "Cách tính điểm"

#### Scenario: Lỗi lưu
- **WHEN** PATCH thất bại
- **THEN** bảng chấm giữ cách tính điểm cũ và hiện lỗi; bấm đúp khi đang gửi chỉ gửi một lần

### Requirement: Màn tạo giải Lite không còn chọn cách tính điểm
Hai màn tạo giải Lite SHALL không hiện lựa chọn Side-out/Rally và SHALL không gửi `pickleballScoring`.

#### Scenario: Tạo giải pickleball
- **WHEN** người tạo mở màn tạo giải Lite với môn pickleball và bấm tạo
- **THEN** không có ô chọn cách tính điểm và payload không có `pickleballScoring`
