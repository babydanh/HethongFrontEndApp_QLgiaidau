# app-ranking-format-filter Specification

## Purpose
Cho người dùng lọc bảng xếp hạng theo định dạng thi đấu (Tất cả, Đơn, Đôi, Đôi nam nữ) giống Web, và hiển thị đúng tên cặp ở hàng, podium và ô tìm kiếm của bảng xếp hạng đôi.

## Requirements

### Requirement: Ranking format filter
Màn Xếp hạng (môn không phải bóng đá) SHALL có hàng chip Định dạng gồm Tất cả, Đơn, Đôi, Đôi nam nữ, mặc định Tất cả, và SHALL gửi `matchType` tương ứng (`SINGLES`, `DOUBLES`, `MIXED_DOUBLES`) cho `GET /rankings`; chọn Tất cả SHALL không gửi `matchType`. Chip Nam/Nữ SHALL ẩn khi chọn Đôi nam nữ, và khi đó request SHALL không gửi `genderRestriction`; với các định dạng còn lại request SHALL gửi giới tính đang chọn.

#### Scenario: Mở màn Xếp hạng lần đầu
- **WHEN** người dùng mở tab Xếp hạng của một môn không phải bóng đá
- **THEN** chip Tất cả được chọn, chip Nam/Nữ hiện với Nam được chọn, và request không có `matchType`

#### Scenario: Chọn Đôi
- **WHEN** người dùng chọn chip Đôi
- **THEN** request có `matchType=DOUBLES` cùng giới tính đang chọn và chip Nam/Nữ vẫn hiện

#### Scenario: Chọn Đôi nam nữ
- **WHEN** người dùng chọn chip Đôi nam nữ
- **THEN** request có `matchType=MIXED_DOUBLES`, không có `genderRestriction`, và chip Nam/Nữ ẩn

#### Scenario: Định dạng không có dữ liệu
- **WHEN** Backend trả danh sách rỗng cho định dạng đã chọn
- **THEN** màn hình hiện trạng thái rỗng sẵn có của bảng xếp hạng, không lỗi

### Requirement: Pair ranking display
Hàng và bục podium của bảng xếp hạng đôi SHALL hiển thị tên cặp theo `PlayerRanking.displayName` (tên đội nếu có, ngược lại tên hai VĐV nối " / "), và ô tìm kiếm SHALL khớp tên đội lẫn tên từng VĐV trong cặp.

#### Scenario: Podium của bảng đôi
- **WHEN** bảng xếp hạng Đôi có hạng 1 gồm hai VĐV không có tên đội
- **THEN** podium hiện tên cả hai VĐV, không chỉ tên một người

#### Scenario: Tìm theo một VĐV trong cặp
- **WHEN** người dùng gõ tên VĐV thứ hai của một cặp vào ô tìm kiếm
- **THEN** cặp đó vẫn nằm trong kết quả

#### Scenario: Tìm không khớp
- **WHEN** từ khoá không khớp tên đội, tên VĐV nào, hạng mục hay bậc
- **THEN** danh sách hiện trạng thái rỗng, không lỗi
