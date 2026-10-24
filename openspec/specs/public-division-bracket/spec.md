# public-division-bracket Specification

## Purpose
Sơ đồ bảng đấu theo nội dung chỉ vẽ trận của đúng nội dung đó; nội dung chưa bốc thăm không hiện trận của nội dung khác.

## Requirements

### Requirement: Nội dung chưa bốc thăm không hiện bracket ảo
Khi mở một nội dung ở tab "Bảng đấu", App SHALL chỉ vẽ trận thuộc nội dung đó. Nội dung chưa có bracket trong giải đã gán bracket cho nội dung khác MUST hiện thông báo chưa có trận, không vẽ trận của nội dung khác.

#### Scenario: Nội dung chưa bốc thăm trong giải nhiều nội dung
- **WHEN** giải có "Đôi Nam" đã bốc thăm và "Đôi linh hoạt" chưa bốc thăm, người xem mở "Đôi linh hoạt"
- **THEN** tab hiện thông báo chưa có trận, không có sơ đồ

#### Scenario: Giải bracket cũ chưa gán nội dung
- **WHEN** giải chỉ có một nội dung và bracket được tạo khi chưa gán nội dung
- **THEN** sơ đồ vẫn hiện trận của giải

#### Scenario: Nội dung đã bốc thăm
- **WHEN** nội dung đã có bracket
- **THEN** sơ đồ hiện đúng trận của nội dung đó như trước
