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

## Risks / open

- Tải lại màn mất lịch sử giao của cầu lông (không lưu Backend). Chấp nhận, ghi ở Out of scope.
- `integration_test/xem_bam_diem_*` đang khẳng định text cũ ("GIAO · ô phải"); phải sửa và chạy trên cloud.
- Màn nhỏ: bốn ô tên VĐV dài; cắt tên bằng ellipsis, kiểm 375px.
