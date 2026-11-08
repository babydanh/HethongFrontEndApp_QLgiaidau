## ADDED Requirements

### Requirement: Chọn cách tính điểm khi tạo giải Lite pickleball
Hệ thống SHALL hiện lựa chọn Side-out / Rally khi môn của giải Lite là pickleball, mặc định Side-out, và gửi `pickleballScoring` trong `POST /tournaments/lite`; môn khác SHALL không hiện lựa chọn và không gửi field.

#### Scenario: Mặc định
- **WHEN** người tạo mở màn tạo giải Lite với môn pickleball và bấm tạo mà không đổi gì
- **THEN** lựa chọn Side-out được chọn sẵn và payload có `pickleballScoring: 'SIDE_OUT'`

#### Scenario: Chọn Rally
- **WHEN** người tạo chọn Rally rồi bấm tạo
- **THEN** payload có `pickleballScoring: 'RALLY'`

#### Scenario: Môn khác
- **WHEN** người tạo chọn môn khác pickleball
- **THEN** lựa chọn ẩn và payload không có `pickleballScoring`

### Requirement: Giải Lite side-out áp luật giao bóng, vẫn là tính điểm mở
Hệ thống SHALL áp luật side-out ở bảng chấm điểm khi `scoringModel` của giải Lite là side-out: chỉ đội giao ghi điểm, "+" của đội nhận là mất giao (Giao 1 sang Giao 2 sang đổi giao) và không cộng điểm. Lite SHALL không có điểm đích và không tự chốt set; Lite rally giữ nguyên hành vi cũ.

#### Scenario: Đội nhận bấm "+"
- **WHEN** đang Giao 1 của đội 1 trong Lite side-out và đội 2 bấm "+"
- **THEN** điểm giữ nguyên và quyền giao chuyển sang Giao 2, rồi sang đội 2

#### Scenario: Không tự chốt set
- **WHEN** đội giao ghi điểm lên 20-3 trong Lite side-out
- **THEN** set không bị đóng

#### Scenario: Lite rally
- **WHEN** đội nhận bấm "+" trong Lite rally
- **THEN** đội nhận được cộng 1 điểm và quyền giao chuyển sang đội đó
