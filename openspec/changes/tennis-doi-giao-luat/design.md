## Context

`ScorePanelState.racketPick` (`score_panel_state.dart:89-142`, ":302 session only") giữ `firstTeam`, `firstPlayerTeam1/2`, `rightStarterTeam1/2`, `endsFlipped`. Người giao tennis = `(firstPlayer + teamServiceGames + tiebreakTurns) % 2` cho cả trận (`score_panel_racket.dart:73-96`); người đỡ ô phải = `rightStarterOf` không khoá; `racketCanPickFirstServer` chỉ trước điểm đầu trận (:31-35); `_racketCorrectTennisServer` sửa cho cả trận (`score_panel_notifier.dart:1089-1121`). Pickleball đã lưu courtState (`pickleball_court_notifier.dart:151-172`, chuỗi `_enqueue` ở `pickleball_court_panel.dart`). Luật tham chiếu: `C:/Users/GIGABYTE/.lavish/tennis-doi/tennis-rules.js` + `tennis-rules.test.js` (21 test, đã duyệt).

## Decisions

### Hợp đồng dữ liệu (giống Backend design.md)

```json
{ "version": 1, "kind": "TENNIS",
  "firstServerTeam": 1,
  "sets": [ { "serveFirst": { "team1": 0, "team2": null }, "receiveRight": { "team1": null, "team2": 1 } } ],
  "gameFix": null, "decidingReceiver": null, "endsFlipped": false }
```
`firstServerTeam` 1|2|null (null = đội 1); `sets[i]` theo số set đã xong, 1..5; giá trị null = người 0; `gameFix`/`decidingReceiver` `{set, game, team, playerIndex}` hoặc null; `endsFlipped` true = đội 1 ở nửa trên. Server gán thêm `updatedAt`/`updatedBy` (client bỏ qua).

### Service thuần `tennis_serve_state.dart`

- `TennisScoreInput(gamesBefore, games1, games2, points1, points2, isTiebreak, setIndex, noAd)` dựng từ `finishedSets` + `TennisGameState`.
- Hàm: `tennisServeOf`, `tennisReceiverOf`, `tennisRightReceiver`, `tennisIsLocked`, `tennisNeedsPick` (gợi ý, không chặn), thao tác trả `TennisCourtState?`: `tennisPickServer`, `tennisPickReceiveRight`, `tennisCorrectServer` (27c), `tennisFixReceiver` (27e), `tennisChooseDecidingReceiver`, `tennisToggleEnds`; `TennisCourtState.fromJson` (sai/thiếu → mặc định), `ensureSet(setIndex)`.
- Port nguyên logic `tennis-rules.js`; null = mặc định 0.
- Đổi sân: giữ `_racketEndsAfterTennisPoint`, ghi kết quả vào `endsFlipped`.

### Notifier và lưu

- `ScorePanelState` thêm `tennisCourt: TennisCourtState`; `RacketUndoStep` snapshot thêm trường này.
- `_hydrateState` đọc `scoreDetails['courtState']` khi kind TENNIS; thao tác đổi court gọi `_persistTennisCourt()` nối chuỗi tuần tự (như `_enqueue` pickleball), chỉ khi `canScore` và trận chưa kết thúc; lỗi → giữ local, đánh dấu chưa lưu, thử lại ở thao tác sau; báo lỗi một lần (`pickleballCourtSaveError`).

### Giao diện

- Bấm ô: đội giao chưa khoá → "Giao bóng cho người này"; đã khoá → "Sửa sai: người này đang giao"; đội nhận chưa khoá → "Đổi chỗ phải/trái"; đã khoá → "Sửa sai: đổi người nhận trong game này"; No-Ad 40-40 → "Người này đỡ điểm quyết định"; luôn có "Đổi sân".
- Dòng nhắc: đầu set "Bấm VĐV để chọn người giao", đội nhận chưa khoá "Bấm ⇄ nếu muốn đổi người nhận".
- Responsive: dùng `LayoutBuilder`/`Flexible` sẵn có của `RacketCourtView`, chữ dài `maxLines` + ellipsis; widget test ở 320 và 768 px rộng không tràn.

## Rejected

- Giữ session-only: mất khi thoát modal, lệch với Web.
- Chặn ghi điểm tới khi chọn: rủi ro kẹt khi chấm trực tiếp.

## Risks

- [Backend chưa gộp] → lưu 400, giữ local, báo một lần.
