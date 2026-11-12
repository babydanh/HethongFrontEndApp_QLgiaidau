## ADDED Requirements

### Requirement: Một nút tạo buổi giao lưu
Màn quản lý CLB SHALL hiện đúng một nút "Tạo buổi giao lưu" trong mục buổi giao lưu, và màn danh sách buổi giao lưu SHALL có đúng một nút tạo.

#### Scenario: Mục buổi giao lưu
- **WHEN** mở mục buổi giao lưu (có hoặc chưa có buổi nào)
- **THEN** chỉ có một nút tạo

### Requirement: Thẻ buổi giao lưu dùng thẻ Social
Các buổi giao lưu CLB SHALL hiển thị bằng `SocialSessionCard` với chip trạng thái ngắn và số liệu dạng icon + số, tối đa 3 buổi trong màn quản lý.

#### Scenario: Nhiều hơn 3 buổi
- **WHEN** CLB có 4 buổi
- **THEN** màn quản lý hiện 3 thẻ và nút "Tất cả"

### Requirement: Không tràn ở 360px
Mục buổi giao lưu và màn danh sách SHALL không gây RenderFlex overflow ở bề rộng 360px kể cả tên dài.

#### Scenario: Tên dài
- **WHEN** tên buổi dài hơn một dòng ở 360px
- **THEN** không có ngoại lệ layout

### Requirement: Bỏ nhãn kỹ thuật và mô tả thừa
Mục lịch giải định kỳ SHALL không chứa chữ "Cron" và câu mô tả dài; SHALL ẩn khi không có giải định kỳ.

#### Scenario: Chưa có giải định kỳ
- **WHEN** CLB không có giải định kỳ
- **THEN** mục lịch định kỳ không hiển thị
