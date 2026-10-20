# Proposal

## Why

Trong lưới lịch, màu hạng mục hiện phụ thuộc thứ tự thay vì giới tính, còn ô điểm nằm sát tên đội nên khó đọc. Tên dài cũng bị cắt quá sớm; cần giữ điểm ở cạnh phải và không làm trận đang diễn ra trông như đã kết thúc.

## What Changes

- Xác định màu bằng metadata `matchType` và `genderRestriction` của từng hạng mục, không suy màu từ tên hiển thị hay thứ tự.
- Cho tên đội trong thẻ đầy đủ tối đa hai dòng, rồi rút gọn bằng dấu ba chấm nếu vẫn dài.
- Căn các điểm theo set sát cạnh phải của mỗi hàng, tách biệt khỏi tên đội.
- Chỉ nhấn mạnh đội thắng/kết quả cuối khi trạng thái trận thực sự hoàn tất; điểm trực tiếp vẫn được phép hiển thị khi trận đang diễn ra.

## Capabilities

### New Capabilities

- `schedule-grid-match-cards`: màu hạng mục và bố cục tên đội/điểm/trạng thái trong thẻ lịch thi đấu.

### Modified Capabilities

- Không có.

## Impact

- App Flutter: `lib/features/tournament/screens/tournament_intro_screen.dart`, `lib/features/tournament/widgets/matches_tab.dart`, `lib/features/tournament/widgets/schedule_grid.dart` và kiểm thử widget liên quan.
- Dùng metadata `TournamentDivision` đã có (`matchType`, `genderRestriction`) cùng `MatchModel.scoreHistory`/`isCompleted`; không cần API hay field mới.
- Backend API và Web không bị ảnh hưởng.
- Ngoài phạm vi: thay đổi dữ liệu điểm, quy tắc xác định trạng thái trận, bố cục lưới/sân và các màn kết quả/giải thưởng.
