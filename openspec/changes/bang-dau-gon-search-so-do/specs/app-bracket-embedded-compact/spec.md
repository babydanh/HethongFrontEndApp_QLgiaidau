## ADDED Requirements

### Requirement: Tab Bảng đấu nhúng trong hub chỉ còn ô tìm kiếm và sơ đồ
Khi `BracketViewScreen` chạy với `isEmbedded` và không `isLite`, hệ thống SHALL ẩn banner mô tả sơ đồ và nút mở sơ đồ riêng, hiển thị đúng một ô tìm kiếm và sơ đồ; sơ đồ SHALL chỉ cuộn ngang (`scrollOnly`), cao theo nội dung và không bị đóng khung cao cố định, để cuộn dọc thuộc trang hub.

#### Scenario: Nhúng trong hub
- **WHEN** quản lý mở tab Bảng đấu của một giải loại trực tiếp có trận
- **THEN** không hiện tiêu đề/mô tả banner, có đúng một ô tìm kiếm và một sơ đồ
- **AND** sơ đồ có vùng cuộn ngang kéo được, không nằm trong `SizedBox` cao 420

#### Scenario: Màn sơ đồ không nhúng
- **WHEN** người dùng mở màn bảng đấu không nhúng
- **THEN** banner và sơ đồ trong khung 420 hiển thị như trước

#### Scenario: Lite nhúng trong khung cao cố định
- **WHEN** màn Lite nhúng `BracketViewScreen` (`isEmbedded` và `isLite`) trong `Expanded`
- **THEN** banner và sơ đồ trong khung 420 hiển thị như trước, không tràn
