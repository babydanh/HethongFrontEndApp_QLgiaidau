## Why
Màn chấm điểm Pickleball của app có sơ đồ sân chỉ để xem; chấm điểm ở khối bên dưới, còn đổi ô phải/trái, người giao, đổi sân nằm trong sheet ⚙ Cài đặt sân. Web đang chuyển sang chấm điểm và kéo thả ngay trên sơ đồ (change Web `san-cham-diem-keo-tha`); app cần cùng hành vi.

## What Changes
- Vẽ lại `PickleballCourtView`: sân luôn nằm ngang (tỉ lệ 2:1, cả màn dọc lẫn ngang), màu xanh nhạt, có vạch biên, vạch giữa, vạch bếp, lưới; bỏ tên đội ở tiêu đề.
- Thanh điểm `− n +` mỗi đội trên sơ đồ, gọi lại logic cộng/trừ điểm có sẵn của panel; side-out thì đội đỡ giao bị khoá nút +.
- Kéo thả bằng nhấn giữ (`LongPressDraggable` + `DragTarget`): kéo VĐV sang ô/nửa sân cùng đội = đổi ô phải/trái; sang nửa sân đội kia = đổi sân, đồng đội đi theo. Trái bóng ở người đang giao: kéo sang đồng đội = đổi người giao; sang người đội kia (side-out) = đổi đội giao.
- Hoàn tác, khôi phục tự động, bật/tắt tự đổi sân là icon trên sơ đồ; gỡ sheet cài đặt sân.
- Màn ngang: sân và khối chốt set xếp hàng ngang thay vì cột dọc.
- Logic quyết định cú thả là hàm Dart thuần có test, cùng quy tắc với Web `resolveCourtDrop`.

## Out of scope
- Không đổi Backend, schema, API (`PATCH /matches/:id/court-state`, `sideOutState` có sẵn).
- Không đổi luật suy lượt giao/đổi sân trong `pickleball_court.dart` (chỉ dùng lại `setStartingRight`, `swapEndsNow`, `setServerOverride`, `undoCourtChange`, `restoreAutomaticCourt`, `setAutoSwitchEnds`).
- Khối chấm điểm cũ bên dưới sân (`PickleballPanel`) giữ nguyên.

## Capabilities
### New Capabilities
- `pickleball-court-scoring`: chấm điểm và chỉnh vị trí ngay trên sơ đồ sân Pickleball (app).

### Modified Capabilities
(không có)

## Impact
- `lib/features/match/utils/court_drag.dart` (mới), `test/match/court_drag_test.dart` (mới)
- `lib/features/match/widgets/pickleball_court_view.dart` (viết lại), `pickleball_court_panel.dart`, `pickleball_court_settings_sheet.dart` (xoá)
- `lib/l10n/app_vi.arb`, `app_en.arb` và file sinh `app_localizations*.dart`
- `lib/features/match/widgets/official_score_modal.dart` (`_buildScoreTab`)
- `test/match/pickleball_court_widget_test.dart`
