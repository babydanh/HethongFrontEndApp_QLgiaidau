# Proposal

## Why

Tab "Danh sách đội" của trang chi tiết giải trên App khó đọc trên điện thoại:

- Cột số người (`9/16`, `8/16`…) lệch hàng theo độ dài tên nội dung. Trong `lib/features/tournament/widgets/division_accordion.dart`, tên nằm trong `Flexible` còn khoảng trống bên phải là `Spacer`, hai khối chia đôi phần trống nên cột số trôi theo tên.
- Mỗi đội đôi (`tournament_team_card.dart`) phải bấm tiếp mới thấy hai thành viên, mỗi lần bấm lại cuộn màn hình (`Scrollable.ensureVisible`).
- Hàng đội đôi nhiều chữ ("Thành viên: A, B", "Elo: 1000"), còn đội đôi chỉ có 1 người đang chờ đồng đội không có dấu hiệu nào.
- Đội mà API trả `members: []` bị App dựng thành viên giả từ tên đội (`api_team_repository.dart` `getAllByTournament`), nên tên đội lặp lại ở chỗ tên thành viên.

## What Changes

- Hàng nội dung (dùng chung ở mọi tab chi tiết giải): cột số người có bề rộng cố định, căn phải, thẳng một cột; tên dài cắt bằng "…".
- Tab "Danh sách đội" khi giải có nhiều nội dung: giữ kiểu bấm hàng nội dung để mở/thu, mỗi lần chỉ mở 1 nội dung; bấm lại nội dung đang mở thì thu.
- Đội đôi: không còn bấm để xổ. Hai thành viên hiện sẵn dưới tên đội dạng chip nhỏ (avatar chữ cái đầu hoặc ảnh + tên, tên dài cắt "…"). Bấm chip mở hồ sơ VĐV như hiện nay.
- Bớt chữ ở hàng đội đôi: bỏ dòng "Thành viên: …" và badge Elo; trạng thái phí chỉ còn icon (đồng hồ = chờ thanh toán, tích = đã đóng).
- Đội đôi có đúng 1 thành viên thật hoặc trạng thái `PENDING_PARTNER`: thêm ô tròn viền đứt màu hổ phách chỉ có icon thêm người, không chữ. Chữ "Chờ đồng đội" (key có sẵn `teamStatusWaitingForPartner`) chỉ nằm trong tooltip và nhãn trợ năng.
- Chip thành viên chỉ lấy từ roster thật của API. Repository không còn điền tên đội vào `Team.members` khi roster rỗng; đội chưa có roster chỉ hiện tên đội, không chip, không ô chờ (trừ `PENDING_PARTNER`). Bỏ key i18n `teamMemberFallback` không còn dùng.
- VĐV chưa có tài khoản (đội BTC nhập Excel): đọc `guestNames` mà Backend trả trong `GET /tournaments/:id/participants` (change Backend `hien-ten-vdv-khach-cong-khai`), thêm thành chip sau thành viên roster, giống trang công khai của Web. Chip khách không có hồ sơ: bấm thì báo "đang cập nhật", không mở hồ sơ người đăng ký (thường là BTC) thay họ.
- Hàng VĐV đơn giữ như hiện tại.

## Capabilities

### New Capabilities

- `tournament-team-list`: cách App hiển thị danh sách đội/VĐV theo nội dung trong trang chi tiết giải.

### Modified Capabilities

(không có)

## Out of scope

- Không thêm màn chi tiết đội; bấm thành viên vẫn mở hồ sơ VĐV.
- Không đổi cách mở/thu nội dung ở các tab; các tab chỉ hưởng phần căn cột số.
- Không đổi danh sách đội của giải CLB lite (`_buildLiteTeamList`).
- Không tự tính VĐV khách ở App; chỉ đọc `guestNames` của Backend.

## Impact

- Code App: `lib/features/tournament/widgets/division_accordion.dart`, `lib/features/tournament/widgets/teams_tab.dart`, `lib/features/tournament/widgets/tournament_team_card.dart`, `lib/features/tournament/screens/tournament_intro_screen.dart`, `lib/data/repositories/api/api_team_repository.dart`, `lib/domain/entities/tournament.dart` (getter `TournamentDivision.isDoubles`), `lib/l10n/app_*.arb`.
- Dữ liệu: dùng `Team.approvalStatus` (đã đọc `teamStatus` từ API trong `lib/domain/entities/team.dart`) để nhận `PENDING_PARTNER`. Không đổi API.
- Backend: cần field `guestNames: string[]` (Backend `cfd00b5d`). Server chưa có field thì đội nhập Excel chỉ hiện tên đội.
- Web: cùng nguồn `guestNames` (change Web `cong-khai-ten-vdv-khach`).
