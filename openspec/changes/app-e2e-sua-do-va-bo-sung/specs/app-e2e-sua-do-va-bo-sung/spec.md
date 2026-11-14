## ADDED Requirements

### Requirement: Bộ E2E App không đỏ vì test lỗi thời
Mọi file trong `integration_test/` SHALL chạy xanh trên job `app-e2e` cloud, trừ các ca `skip: true` mang mã `BUG-...` đã ghi ở `design.md`.

#### Scenario: File đỏ vì màn đã đổi
- **WHEN** một ca đỏ vì app đã đổi giao diện có chủ ý
- **THEN** test được sửa theo giao diện mới và vẫn kiểm đúng ý ban đầu

#### Scenario: File đỏ vì lỗi app thật
- **WHEN** một ca đỏ vì app hành xử sai
- **THEN** ca giữ nguyên `expect`, bị `skip: true` kèm mã `BUG-...`, và `design.md` ghi lỗi

### Requirement: Test logic giao bóng và đổi sân
Bộ test SHALL kiểm logic giao bóng, đổi bên giao và đổi sân của pickleball, tennis và cầu lông trên màn bấm điểm kiểu sân mới.

#### Scenario: Mất giao ở pickleball đôi
- **WHEN** đội nhận thắng điểm khi đội kia đang giao
- **THEN** quyền giao chuyển đúng theo luật side-out và màn hiển thị người giao mới
