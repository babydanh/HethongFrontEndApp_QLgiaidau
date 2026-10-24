# tournament-results Specification

## Purpose
Mô tả cách App hiển thị kết quả giải đấu theo hạng mục đã chọn, gồm thứ hạng, tên đội, tên vận động viên và ảnh đại diện.

## Requirements

### Requirement: Danh sách kết quả theo hạng mục đang chọn
App MUST giữ bộ chọn hạng mục hiện có và MUST hiển thị danh sách thứ hạng của hạng mục đang chọn ngay dưới bộ chọn. Màn Kết quả MUST NOT hiển thị bục vinh danh tách riêng. Nếu hạng mục có giải thưởng, mỗi mục MUST hiển thị thứ hạng, tên đội, danh hiệu và tên vận động viên theo nội dung đơn/đôi; tên hạng mục MUST NOT thay thế tên đội.

#### Scenario: Hiển thị kết quả của hạng mục được chọn
- **WHEN** người xem chọn một hạng mục có kết quả chính thức
- **THEN** App hiển thị danh sách giải thưởng của đúng hạng mục đó ngay dưới bộ chọn, với tên đội và tên thành viên tương ứng; không hiển thị bục vinh danh

#### Scenario: Hạng mục chưa có giải thưởng
- **WHEN** người xem chọn hạng mục chưa có kết quả chính thức
- **THEN** App hiển thị trạng thái chưa có kết quả và không hiển thị bục hay thẻ giải thưởng

### Requirement: Thành viên và avatar theo loại hạng mục
App MUST xác định loại đơn/đôi từ `matchType` thật của hạng mục đang chọn (`SINGLES`, `DOUBLES` hoặc `MIXED_DOUBLES`). Với `SINGLES`, mỗi kết quả MUST trình bày tên và avatar của một vận động viên; với `DOUBLES` hoặc `MIXED_DOUBLES`, MUST trình bày tên và avatar của hai thành viên theo dữ liệu `participant.members`. Avatar MUST dùng ảnh thành viên khi có URL hợp lệ và MUST dùng chữ cái đầu tên làm ảnh thay thế khi thiếu hoặc ảnh không tải được. App MUST NOT suy ra loại hạng mục từ tên hiển thị.

#### Scenario: Kết quả đơn có ảnh đại diện
- **WHEN** hạng mục đang chọn có `matchType` là `SINGLES` và dữ liệu thành viên có tên cùng ảnh đại diện
- **THEN** thẻ kết quả hiển thị tên đội, tên vận động viên và một ảnh đại diện

#### Scenario: Kết quả đôi thiếu ảnh đại diện
- **WHEN** hạng mục đang chọn có `matchType` là `DOUBLES` hoặc `MIXED_DOUBLES` và một hay cả hai thành viên thiếu ảnh hoặc ảnh tải lỗi
- **THEN** thẻ kết quả hiển thị tên đội, tên các thành viên có trong dữ liệu và avatar chữ cái đầu tương ứng; không tự tạo tên thành viên hoặc ảnh
