## Context

Đã đọc code (không đoán):
- `RallyServe`/`rallyServe` (`rally_serve_rules.dart`) cho đội giao, ô phải/trái theo điểm chẵn lẻ, VĐV 1/2 theo `swaps1/2`. `firstServer` có tham số nhưng notifier không truyền (set đầu luôn đội 1).
- `tennisServer` (`tennis_rules.dart`) cho đội giao theo số game + tie-break đổi mỗi 2 điểm; `tennisServerTeam` (`score_panel_tennis.dart`) cứng "đội 1 giao game đầu". State tennis chỉ có `TennisGameState` + `finishedSets`, không có lịch sử từng điểm.
- `rallyRemovePoint` (`score_panel_notifier.dart:885`) tạo `RallySetState` mới không có `lastWinner/swaps` nên chip GIAO ẩn.
- Pickleball có `ScoreUndoStep`/`pushUndoStep` (`court_undo.dart`, giới hạn 50 bước) và `matchSidePlayers` (`core/participants/match_side_players.dart`) lấy VĐV theo `teamNPlayers → MemberInfos → Members`.
- `official_score_modal.dart:886-905` chọn panel theo môn; cầu lông strict đi qua `BadmintonScorePanel → RallyScorePanel`.

## Decisions

1. **Phạm vi hiển thị**: chỉ cầu lông strict và tennis strict dùng sân mới. Lite, bóng bàn, pickleball rally giữ panel cũ. Lý do: bóng bàn chung `RallyScorePanel`, không nằm trong yêu cầu.
2. **Luật thuần ở domain**, không trong widget: thêm hàm vào `rally_serve_rules.dart` và `tennis_rules.dart`, kèm một hàm bố cục `racketCourtCells` (file mới `lib/domain/services/racket_court_layout.dart`) trả về ô nào có ai, ai giao, ai nhận. Widget chỉ vẽ kết quả. Cho phép test không cần widget.
3. **Hướng nhìn**: mỗi đội nhìn lưới từ phía mình. Màn ngang: đội 1 bên trái quay mặt sang phải nên "ô phải" của đội 1 là ô **dưới**; đội 2 bên phải nên "ô phải" là ô **trên**. Màn dọc: đội 1 ở trên, ô phải = bên trái màn hình; đội 2 ở dưới, ô phải = bên phải. Ô nhận luôn là ô cùng phía (phải với phải) của đội đối diện.
4. **Người giao đầu** là một giá trị trong state (`RacketServePick { firstTeam, firstPlayerOfTeam1, firstPlayerOfTeam2 }`), chỉ sống trong phiên như hiện tại với pickleball. Chọn bằng bấm ô lúc 0-0; `⋯` → "Chọn người giao" để sửa giữa chừng (đánh dấu lịch sử cầu lông là chưa biết tới điểm kế, như `−`).
5. **Hoàn tác** dùng ngăn xếp riêng `RacketUndoStep { rally, tennis, pick, finishedSetCount }` (tối đa `undoStepLimit` = 50), không sửa `ScoreUndoStep` của pickleball để không phá test pickleball. Hoàn tác khôi phục cả `lastWinner/swaps`, nên người giao luôn chính xác.
6. **Nút `−`** giữ như pickleball: chỉnh tay của trọng tài, làm lịch sử giao thành chưa biết tới điểm kế (hành vi hiện tại của `rallyRemovePoint`). Đã chọn A; phương án bỏ `−` bị loại vì khác bố cục pickleball.
7. **Tennis đôi**: người giao của đội = người thứ `(số lượt giao của đội) mod 2` tính từ người giao đầu của đội đó; số lượt giao suy ra từ tổng số game đã chơi (tie-break tính một game). Không lưu thêm.
8. **Màn dọc và ngang** cùng dùng một widget, đổi trục như `PickleballCourtView`. Dùng lại `pickleball_court_palette.dart` (màu đội) và widget avatar/tên VĐV; không dùng lại `pickleball_court_scoreboard.dart` (1381 dòng, gắn chặt với side-out và kéo thả). [SUY LUẬN] có thể trích vài widget nhỏ dùng chung khi code; chỉ trích khi trùng thật.

9. **Kéo thả dùng lại, không viết lại**: `resolveCourtDrop` (`court_drag.dart`) là hàm thuần, không phụ thuộc môn; dùng nguyên cho cầu lông và tennis. Thêm một lớp mỏng `racketResolveDrop` (file mới `lib/features/match/utils/racket_court_drag.dart`) chỉ để chặn hai ca luật cấm: trận đơn không có `SwapPlaces`, và tennis đôi không đổi ô đội **đang giao** (thứ tự giao cố định, đổi ô của đội nhận thì được). Widget dùng lại `CourtDraggable` (nhấn giữ 250 ms), `CourtDropOutline`, `courtPlayerActions`.
10. **Thả trái bóng = trọng tài chỉnh tay**: `SetServer` đi qua `racketCorrectServer`, được phép đổi cả đội giao (khác pickleball chỉ cho side-out) vì cầu lông/tennis đội giao do luật suy ra; đây là cách sửa khi trọng tài bấm nhầm. Hoàn tác trả lại. Chỉ cho thả khi biết người giao hiện tại; lúc 0-0 chưa có điểm thì thả trái bóng = chọn người giao đầu.
11. **Đổi ô và đổi sân lưu trong state phiên**: `RacketServePick` thêm `rightStarterTeam1/2` (cầu lông: ai đứng ô phải lúc 0; tennis: ai nhận từ ô phải) và `endsFlipped` (đổi sân tay, XOR với đổi sân theo luật). Chỉ sống trong phiên như người giao đầu.
12. **Pickleball nhận**: `CourtLayout` (`pickleball_court.dart:340`) thêm `receiverCell` và `receiverPlayerIndex`. Đôi: ô nhận là ô chéo người giao (cùng `CourtCell` bên đội kia). Đơn: sửa `_slotsFor` (:732) để người của đội nhận đứng ô chéo người giao, không theo điểm của chính họ; ô còn lại của đội trống. Thay đổi này chỉ ảnh hưởng vị trí vẽ, không đổi luật tính điểm hay dữ liệu lưu.
13. **Đã bỏ qua có chủ ý** (ghi để khỏi hỏi lại): sau khi bấm `−` ở cầu lông đôi chỉ biết **đội** giao, chưa biết VĐV nào, nên chip GIAO ẩn tới điểm kế hoặc chọn bằng bấm ô/kéo trái bóng; tennis đôi trong tie-break hai VĐV luân phiên theo lượt giao của đội (mô hình trong mock Lavish, 39 test logic).

## Risks / open

- Tải lại màn mất lịch sử giao của cầu lông (không lưu Backend). Chấp nhận, ghi ở Out of scope.
- `integration_test/xem_bam_diem_*` đang khẳng định text cũ ("GIAO · ô phải"); phải sửa và chạy trên cloud.
- Màn nhỏ: bốn ô tên VĐV dài; cắt tên bằng ellipsis, kiểm 375px.
- Kéo thả trong cuộn dọc: `CourtDraggable` dùng nhấn giữ 250 ms nên không tranh cuộn; màn dọc vẫn phải kiểm trên máy thật.
- Mock Lavish đơn giản hơn App ở pickleball (`_reconcileTurn`); App là nguồn đúng, mock chỉ để xem thao tác.
