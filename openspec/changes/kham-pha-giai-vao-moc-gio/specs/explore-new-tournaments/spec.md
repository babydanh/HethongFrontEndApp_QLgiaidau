## ADDED Requirements

### Requirement: Giải nằm trong mốc giờ của màn Khám phá

The Explore screen SHALL list just-opened and just-started tournaments inside the time slot of their start time, together with the Social sessions of the selected day.

#### Scenario: Giải vừa bắt đầu hiện trong mốc giờ
- **WHEN** một giải đang diễn ra bắt đầu lúc 08:30 và người dùng xem ngày hôm nay
- **THEN** mốc "08:30" có thẻ giải đó và số đếm của mốc tính cả giải

#### Scenario: Ngày chỉ có giải
- **WHEN** ngày được chọn không có buổi Social nhưng có giải thuộc ngày đó
- **THEN** danh sách hiện mốc giờ của giải, không hiện thông báo "Không có buổi Social"

#### Scenario: Gần bạn
- **WHEN** người dùng bật "Gần bạn"
- **THEN** giải vẫn hiện ở khối riêng phía trên danh sách
