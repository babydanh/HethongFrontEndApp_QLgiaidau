## ADDED Requirements

### Requirement: Thẻ buổi giao lưu chỉ dùng icon SVG của môn ở đầu thẻ
Thẻ buổi giao lưu trên App SHALL thể hiện môn bằng icon SVG của môn ở đầu thẻ (bên trái, trước tiêu đề), không có chip chữ tên môn.

#### Scenario: Thẻ danh sách kèo
- **WHEN** thẻ có sport `badminton` và sportName "Cầu lông"
- **THEN** thẻ có đúng một `SvgPicture` 32dp nằm bên trái tiêu đề, `Semantics` và `Tooltip` là "Cầu lông", và không có `Text` "Cầu lông"
- **AND** không còn icon outline Material ở cột phải

#### Scenario: Không tràn ở 360px
- **WHEN** tiêu đề và tên sân rất dài, bề rộng 360dp
- **THEN** không có overflow và icon rộng 28–32dp

#### Scenario: Kết quả tìm kiếm Kèo
- **WHEN** tìm kiếm toàn cục ở scope Kèo có kết quả
- **THEN** mỗi dòng dùng cùng icon làm leading, bên trái tiêu đề, kèm tooltip tên môn

#### Scenario: sportName rỗng
- **WHEN** sportName rỗng
- **THEN** nhãn lấy từ tên môn i18n theo slug
