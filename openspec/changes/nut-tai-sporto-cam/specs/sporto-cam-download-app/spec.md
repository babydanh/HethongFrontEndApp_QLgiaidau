## ADDED Requirements

### Requirement: Nút tải SportO Cam trong sheet Thêm camera
Sheet "Thêm camera" SHALL hiện nút tải app SportO Cam dưới phần hướng dẫn ở tab `Camera / điện thoại`, và MUST NOT hiện ở tab `Live YouTube / Facebook` hay khi sửa camera đã có. Mỗi nút SHALL mở trang store của SportO Cam (không phải app SportO chính) ở ứng dụng ngoài.

#### Scenario: Mở trên điện thoại Android
- **WHEN** BTC mở sheet trên Android và đang ở tab `Camera / điện thoại`
- **THEN** chỉ có nút Google Play trỏ tới `vn.vnvar.sportocam`

#### Scenario: Mở trên iPhone
- **WHEN** BTC mở sheet trên iPhone ở tab `Camera / điện thoại`
- **THEN** chỉ có nút App Store trỏ tới `id6813012756`

#### Scenario: Chuyển sang tab Live YouTube / Facebook
- **WHEN** BTC chọn tab `Live YouTube / Facebook`
- **THEN** các nút tải biến mất
