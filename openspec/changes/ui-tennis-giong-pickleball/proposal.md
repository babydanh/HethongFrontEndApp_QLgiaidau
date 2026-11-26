## Why

Màn bấm điểm Tennis (Lite/Strict) trong App là một bản dựng riêng (`racket_court_view.dart`, `racket_court_bar.dart`), không dùng chung bảng điểm Pickleball (`CourtScoreboard`). Số điểm nhỏ, nút +/− tách xa ở thanh dưới, cột giữa chật ở màn ngang. Trọng tài đã quen màn Pickleball nên màn Tennis phải giống hệt về giao diện và thao tác, chỉ khác logic tennis.

## What Changes

- `RacketCourtView` hiển thị bằng `CourtScoreboard` của Pickleball (cùng bố cục dọc/ngang, nút +/−, Hoàn tác, Đổi sân, menu ⋯, cỡ số điểm). Chữ ký công khai của `RacketCourtView` giữ nguyên (thêm `sportIcon` tuỳ chọn) nên panel và notifier không đổi logic.
- `CourtScoreboard` thêm tham số tuỳ chọn: `scoreTextOf` (điểm chữ 15/30/40/Ad), `canRemovePoint`, `onPlayerTap`, `setText`, `sportIcon`. Mặc định giữ hành vi Pickleball.
- `CourtMenuActions.onPickServer`: mục "Chọn người giao" trong menu ⋯.
- Bỏ `racket_court_bar.dart` (thanh +/− riêng).
- Logic tennis giữ nguyên, kể cả quy tắc đổi sân tự động.

## Out of scope

- Logic tính điểm tennis, quy tắc đổi sân, người giao/nhận, chips, banner.
- Màn Pickleball (chỉ thêm tham số tuỳ chọn cho `CourtScoreboard`).
- Backend, API, bản Web.
- Modal "Tính điểm / Phạm lỗi" (`official_score_modal.dart`, `courtMode`) cho Tennis: làm riêng nếu cần.

## Capabilities

### New Capabilities
- `tennis-court-ui`: màn bấm điểm Tennis Lite/Strict dùng giao diện bảng điểm Pickleball.

### Modified Capabilities
(không có)

## Impact

- `lib/features/match/widgets/racket_court_view.dart`, `racket_court_panel.dart`, `racket_court_bar.dart` (xoá), `pickleball_court_scoreboard.dart`, `pickleball_court_controls.dart`.
- Test: `test/match/racket_court_view_test.dart`, `test/match/racket_court_panel_test.dart`.
