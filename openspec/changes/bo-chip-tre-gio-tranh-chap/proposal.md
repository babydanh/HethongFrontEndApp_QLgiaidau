## Why
Web bỏ chip "Trễ giờ" và "Tranh chấp" khỏi bảng Kết quả của BTC; App giữ cùng bộ lọc (parity với Web `ResultsBoard`).

## What Changes
- Bỏ `ResultsBoardFilter.late` và `.disputed`, cùng đồng hồ `clock` chỉ phục vụ chip "Trễ giờ".
- Checklist tiến trình giữ dòng "trễ giờ" và "tranh chấp"; "trễ giờ" mở chip "Chưa xong", "tranh chấp" mở tab Kết quả ở "Tất cả" (trận tranh chấp không thuộc "Đã xong" lẫn "Chưa xong").

## Out of scope
- Hàm `isLateMatch` và `isDisputedMatch` (checklist còn dùng để đếm).
- Khoá l10n `resultsBoard_late`/`resultsBoard_disputed` để nguyên: xoá phải sinh lại `app_localizations*.dart`, dễ xung đột với các nhánh khác đang sửa `.arb`.

## Capabilities
### New Capabilities
- `results-board-filters`: tập chip lọc của bảng Kết quả phía BTC.

### Modified Capabilities
(không có)

## Impact
- `lib/features/tournament/widgets/results_match_board.dart`, `lib/features/tournament/utils/tournament_step_summary.dart`.
- Không đổi API.
