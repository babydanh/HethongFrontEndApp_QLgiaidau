## ADDED Requirements

### Requirement: Thẻ trận toàn màn hình giống thẻ trong tab
Thẻ trận của sơ đồ toàn màn hình SHALL dùng cùng thiết kế với thẻ của tab Bảng đấu: header mã trận · sân · LIVE · giờ, bên thắng được tô nền và đánh dấu, bên trống ghi "Miễn đấu" hoặc "N/A", không có footer chữ.

#### Scenario: Trận đã xong
- **WHEN** sơ đồ toàn màn hình hiển thị trận COMPLETED có người thắng
- **THEN** hàng bên thắng nền nhạt, điểm màu chính, đậm; bên thua giữ màu thường

#### Scenario: Trận miễn đấu
- **WHEN** một bên của trận là BYE
- **THEN** bên đó ghi "Miễn đấu" màu mờ, không ghi "BYE"
