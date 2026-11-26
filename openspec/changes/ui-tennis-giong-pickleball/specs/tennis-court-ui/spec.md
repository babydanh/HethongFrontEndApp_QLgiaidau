## ADDED Requirements

### Requirement: Màn Tennis dùng giao diện bảng điểm Pickleball
Màn bấm điểm Tennis Lite và Strict SHALL hiển thị bằng cùng bảng điểm với màn Pickleball (cùng bố cục dọc và ngang, cùng nút +/−, Hoàn tác, Đổi sân, menu ⋯, cùng cỡ số điểm), và MUST giữ nguyên toàn bộ logic tính điểm tennis.

#### Scenario: Hiển thị điểm tennis trên bảng Pickleball
- **WHEN** trận Tennis đang tính điểm và game hiện tại là 30-15
- **THEN** bảng điểm hiện "30" và "15" bằng cỡ số của màn Pickleball, không hiện số thô 2 và 1

#### Scenario: Chọn người giao qua menu ⋯
- **WHEN** trọng tài mở menu ⋯ và chọn "Chọn người giao" rồi chạm một VĐV
- **THEN** VĐV đó là người giao và logic tennis hiện tại áp dụng như trước
