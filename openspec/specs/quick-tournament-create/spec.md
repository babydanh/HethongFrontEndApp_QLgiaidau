# quick-tournament-create Specification

## Purpose
Tạo giải nhanh và giải CLB trên App: nội dung mặc định không giới tính, ánh xạ format và genderRestriction gửi lên API.

## Requirements

### Requirement: Nội dung mặc định của giải nhanh không giới tính
Màn tạo giải nhanh môn vợt MUST mặc định một nội dung `OPEN_DOUBLES`, hiển thị "Đôi linh hoạt" (key `tournamentCategoryOpenDoubles`). Luồng này MUST NOT dùng `MALE_DOUBLES` hoặc `MALE` làm mặc định, và MUST NOT thêm nút chọn Đơn/Đôi.

#### Scenario: Mở màn tạo giải nhanh môn vợt
- **WHEN** BTC mở màn tạo giải nhanh với môn vợt
- **THEN** danh sách nội dung chỉ có "Đôi linh hoạt" và không có control chọn Đơn/Đôi

#### Scenario: Đổi môn rồi quay lại môn vợt
- **WHEN** BTC đổi môn sang bóng đá rồi lại chọn môn vợt
- **THEN** nội dung mặc định của môn vợt là "Đôi linh hoạt"

#### Scenario: Thêm nội dung thủ công
- **WHEN** BTC chọn tường minh một nội dung khác trong danh sách có sẵn
- **THEN** nội dung đó được thêm với giới tính BTC đã chọn và mặc định không đổi

### Requirement: Ánh xạ format và giới tính gửi API
App MUST gửi `format` như sau: mọi `*_SINGLES` và mọi `FOOTBALL_*` → `singles`; `OPEN_DOUBLES`, `MALE_DOUBLES`, `FEMALE_DOUBLES` → `doubles`; `MIXED_DOUBLES` → `mixed_doubles`. App MUST gửi `genderRestriction` cấp giải chỉ khi nội dung là `MIXED_DOUBLES` hoặc `FOOTBALL_MIXED` (giá trị `MIXED`). `MALE`/`FEMALE` MUST chỉ nằm ở cấp nội dung.

#### Scenario: Nội dung không giới tính
- **WHEN** nội dung là `OPEN_DOUBLES`
- **THEN** payload cấp giải là `{format: "doubles"}` không có `genderRestriction`, nội dung có `matchType: "DOUBLES"` và không có `genderRestriction`

#### Scenario: Đôi nam nữ
- **WHEN** nội dung là `MIXED_DOUBLES`
- **THEN** payload cấp giải có `format: "mixed_doubles"` và `genderRestriction: "MIXED"`; nội dung có `matchType: "MIXED_DOUBLES"`

#### Scenario: Bóng đá nam
- **WHEN** nội dung là `FOOTBALL_MALE`
- **THEN** payload cấp giải có `format: "singles"` và không có `genderRestriction`; nội dung có `matchType: "SINGLES"` và `genderRestriction: "MALE"`

#### Scenario: Khoá nội dung không nhận diện
- **WHEN** `formatKey` không nằm trong danh sách hỗ trợ
- **THEN** App không ném lỗi, gửi `format: "doubles"` và không gửi `genderRestriction` cấp giải

### Requirement: Giải CLB gửi format đúng theo môn
Khi tạo giải CLB, App MUST gửi `format: "singles"` cho môn bóng đá, `format: "mixed_doubles"` khi người dùng chọn đôi nam nữ, và giữ `format: "doubles"` mặc định cho môn vợt.

#### Scenario: CLB bóng đá
- **WHEN** CLB thuộc môn bóng đá
- **THEN** body gửi `format: "singles"`

#### Scenario: CLB đôi nam nữ
- **WHEN** người dùng chọn đôi nam nữ
- **THEN** body gửi `format: "mixed_doubles"`, không ép thành `doubles`

#### Scenario: CLB vợt mặc định
- **WHEN** người dùng không đổi định dạng của CLB vợt
- **THEN** body gửi `format: "doubles"` như trước
