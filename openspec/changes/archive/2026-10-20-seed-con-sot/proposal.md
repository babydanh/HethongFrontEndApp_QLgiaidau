## Why

Backend và tab Đăng ký của Web đã bỏ seed cho thể thức khác vòng bảng + loại trực tiếp (SE/DE/RR xếp ngẫu nhiên). App vẫn hiện seed ở tab Đội, ở sơ đồ Ops và ở mục "Quản lý nội dung" (ô nhập seed, nút tự xếp, mô tả "xếp hạt giống"). Người dùng thấy seed còn hiện sai thể thức.

## What Changes

- Thêm `AppConstants.supportsSeeding(bracketType)`: chỉ `group_stage_knockout` (so khớp không phân biệt hoa thường).
- Tab Đội (`TeamsTab`, màn intro) chỉ hiện "Hạt giống #N" cho đội thuộc nội dung vòng bảng + loại trực tiếp. `TournamentTeamCard` nhận cờ `showSeed` mặc định `false`.
- Quản lý nội dung: khối hạt giống chỉ liệt kê nội dung vòng bảng + loại trực tiếp; không có nội dung nào thì ẩn cả khối (ô seed, nút tự xếp, nút lưu).
- Organizer ops: chip seed của người tham gia chỉ hiện khi nội dung đang chọn là vòng bảng + loại trực tiếp (`_OpsDivision.bracketType` đọc từ cùng key API với `TournamentDivisionOption`).
- `TournamentTeamSheet` (hiện không có chỗ gọi) nhận cùng cờ `showSeed`.
- Copy ARB vi/en: bỏ lời hứa "xếp hạt giống" ở mô tả nội dung, tiêu đề bốc thăm (en), thông báo ghép lại cặp (en). Giữ nguyên key.

## Impact

- Chỉ App Flutter. Không đổi API, không đổi dữ liệu seed đã lưu, không đổi `Team.seed` và `OrganizerOpsParticipant.seed` ở domain.
- Backend và Web: không đổi code trong change này.
- Lưu ý đã biết: App vẫn gửi `seedingType: 'RANDOM'` cho mọi thể thức, kể cả vòng bảng + loại trực tiếp. Hành vi này giữ nguyên theo yêu cầu.

## Out of scope

- Không đổi hành vi vòng bảng + loại trực tiếp và không gửi `seedingType: 'SEEDED'`.
- Không sửa `RegistrationTab.tsx` và `roster-import/` của Web (thuộc lane khác).
- Không xóa `TournamentTeamSheet` (dead code, chỉ gate cờ) và không xóa key i18n còn dùng cho vòng bảng.
- Không chạy bộ test đầy đủ cục bộ; chạy trên cloud theo skill `cloud-test-runner`.
