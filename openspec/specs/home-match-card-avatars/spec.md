# home-match-card-avatars Specification

## Purpose
Thẻ trận ở Trang chủ hiện ảnh thật của VĐV khi có, để người xem nhận ra người chơi giống màn chi tiết trận.

## Requirements

### Requirement: Thẻ trận hiện ảnh VĐV
Thẻ trận ở Trang chủ SHALL hiện ảnh của tối đa 2 VĐV mỗi đội từ dữ liệu thành viên của trận, đã lọc trùng. VĐV không có ảnh, hoặc ảnh tải lỗi, MUST hiện vòng tròn chữ viết tắt.

#### Scenario: Đội đơn có ảnh
- **WHEN** đội 1 là "Nguyễn Minh Danh" có `avatarUrl`
- **THEN** dòng đội 1 hiện một ảnh tròn của người đó, không hiện "NM"

#### Scenario: API trả trùng thành viên
- **WHEN** `participant1.members` có 5 bản ghi của cùng một người
- **THEN** dòng đội hiện đúng 1 ảnh

#### Scenario: Không có ảnh
- **WHEN** đội không có thành viên hoặc thành viên không có `avatarUrl`
- **THEN** dòng đội hiện chữ viết tắt như trước
