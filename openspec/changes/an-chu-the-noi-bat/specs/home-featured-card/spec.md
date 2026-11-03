## ADDED Requirements

### Requirement: Thẻ nổi bật ẩn tên giải theo cờ
Thẻ nổi bật ở trang chủ SHALL không hiện tên giải (và lớp mờ tối phía sau chữ) khi mục nổi bật có `hideFeaturedCardText = true`, và SHALL vẫn hiện huy hiệu môn thể thao và trạng thái đăng ký.

#### Scenario: Cờ bật
- **WHEN** mục nổi bật có `hideFeaturedCardText = true`
- **THEN** tên giải không xuất hiện trên thẻ, huy hiệu vẫn hiện

#### Scenario: Cờ tắt hoặc thiếu
- **WHEN** API không trả `hideFeaturedCardText` hoặc giá trị không phải `true`
- **THEN** thẻ hiện tên giải như trước
