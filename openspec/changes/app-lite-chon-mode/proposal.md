## Why
Giải Lite pickleball trên App luôn là rally: không chọn được cách tính điểm khi tạo giải, và bảng chấm điểm không áp luật giao bóng side-out ở Lite (code chặn bằng `!isOpenScoring`). Backend (change song song) thêm field `pickleballScoring` cho `POST /tournaments/lite` và lưu `sportRules.scoringModel`.

## What Changes
- Hai màn tạo giải Lite (`create_club_tournament_screen.dart`, `create_public_quick_tournament_screen.dart`): khi môn là pickleball hiện lựa chọn Side-out / Rally, mặc định Side-out, gửi `pickleballScoring: 'SIDE_OUT' | 'RALLY'`. Môn khác không hiện, không gửi.
- Thêm `ScorePanelState.isPickleballSideOut` (theo `config.scoringModel`); `pickleballAwardPoint` và `PickleballCourtPanel` dùng nó thay `!isOpenScoring && ...` nên Lite side-out áp luật giao bóng (chỉ đội giao ghi điểm, "+" bên nhận = mất giao, nhãn "Mất giao -> Giao 2").
- Lite vẫn là scorecard mở: không điểm đích, không BO, không tự chốt set (các nhánh `isOpenScoring` khác giữ nguyên).

## Out of scope
- Backend; `create_club_screen.dart` (giải định kỳ mẫu, không gửi field, Backend mặc định SIDE_OUT).
- Đổi luật Lite cũ: giải Lite cũ không có `scoringModel` side-out nên vẫn là rally.

## Capabilities
### New Capabilities
- `app-lite-chon-mode`: chọn cách tính điểm khi tạo giải Lite pickleball và luật giao bóng theo lựa chọn đó.

### Modified Capabilities
(không)

## Impact
- Chỉ App Flutter. Dùng lại khoá l10n `divisionEditorPickleballMode`, `divisionEditorSideOutScoring`, `divisionEditorRallyScoring` (không đổi ARB).
- Test đổi: các test coi "Lite + scoringModel side-out" là rally chuyển sang `rallyPointSet`.
