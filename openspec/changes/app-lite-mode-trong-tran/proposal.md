## Why
Thiết kế trước (`app-lite-chon-mode`) cho chọn Side-out/Rally ngay ở màn TẠO giải Lite. Người dùng muốn đổi: cách tính điểm là chuyện của từng trận, trọng tài chọn ngay trong màn bấm điểm. Change này ĐẢO thiết kế trước: bỏ ô chọn ở màn tạo giải, chuyển vào màn bấm điểm của trận Lite. Backend (change song song) lưu theo trận ở `matches.match_config` và thêm `PATCH /matches/:id/pickleball-scoring`.

## What Changes
- BỎ ô chọn Side-out/Rally ở hai màn tạo giải Lite; App không gửi `pickleballScoring` nữa (Backend vẫn nhận, mặc định SIDE_OUT).
- Đọc cờ theo trận: gộp `matchConfig.kind` + `matchConfig.scoringModel` lên trên cùng `sportRules` của trận (cờ trận thắng cờ giải); socket thiếu field không làm mất cờ.
- Thêm mục "Cách tính điểm" vào menu "⋯" của sân pickleball: chỉ trận Lite, chỉ đổi được khi 0-0; đã có điểm thì khoá kèm lý do. Gọi `PATCH /matches/:id/pickleball-scoring` body `{ "scoring": "SIDE_OUT" | "RALLY" }`; thành công cập nhật bảng chấm ngay, thất bại giữ lựa chọn cũ và báo lỗi.
- Hộp "Thông tin trận" của Lite cũng hiện nhãn cách tính điểm hiện tại.
- GIỮ luật side-out ở bảng chấm điểm (`isPickleballSideOut`, `pickleballAwardPoint`); Strict giữ nguyên theo preset giải (nhãn chỉ đọc, không có mục đổi).

## Out of scope
- Backend; `create_club_screen.dart`.
- `pickleball_court_panel.dart` `const isSideOut = true` giữ nguyên: App luôn hiện lượt giao cho mọi trận pickleball, luật chặn đội nhận ghi điểm do `panel.isPickleballSideOut` quyết định.

## Capabilities
### New Capabilities
- `app-lite-mode-trong-tran`: chọn và đọc cách tính điểm pickleball theo từng trận Lite.

### Modified Capabilities
(không)

## Impact
- Chỉ App Flutter. Xoá `lite_pickleball_scoring.dart`, `lite_pickleball_scoring_picker.dart`. Khoá l10n `divisionEditorSideOutScoring/RallyScoring` giữ nguyên, thêm vài khoá mới cho menu.
