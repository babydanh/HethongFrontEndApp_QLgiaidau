Thứ tự làm: 1.1, 1.2, 1.3, 1.4, 1.5 → 2.1 → 4.1 → 3.1 → 3.2, 3.3 → 5.1 → 6.1 (một chuỗi, một worktree `app-bam-diem-san-cau-long-tennis`, một agent làm; không chia subagent vì 2.1, 3.1, 3.2 phụ thuộc nhau và 2.1, 3.2 cùng đụng file notifier/modal).

## 1. Luật thuần (domain)

- [ ] 1.1 Tennis: hàm ô giao, game point, đổi sân, người giao trong đôi. Tiêu chí: `flutter test --no-pub test/domain/tennis_rules_test.dart` → exit 0 (thêm TC-RACKET-T-01..06)
  - Files: sửa `lib/domain/services/tennis_rules.dart` (thêm sau `tennisServer`, dòng ~130); test `test/domain/tennis_rules_test.dart`
  - Giao: `bool tennisServeRight(int pointsInGame)` · `int tennisGamePointTeam({required int p1, required int p2, required bool noAd, required bool tiebreak, int tiebreakTarget = 7})` trả 0 khi không có, 1|2 là đội thắng game bằng điểm kế · `bool tennisChangeEndsAfterGame(int gamesInSet)` (lẻ) · `bool tennisTiebreakChangeEnds(int tiebreakPoints)` (>0 và chia hết 6) · `int tennisTeamServiceGames({required int gamesPlayed, required int team, int firstServer = 1})` · `int tennisServerPlayerIndex({required int teamServiceGames, int firstPlayer = 0})` trả 0|1 cho 2 tasks 2.1, 3.1
  - Nhận: (không)
  - Chủ file chung: 1.1 giữ `tennis_rules.dart`
  - Phụ thuộc: không

- [ ] 1.2 Cầu lông: điểm set, điểm vàng. Tiêu chí: `flutter test --no-pub test/domain/rally_serve_rules_test.dart` → exit 0 (thêm TC-RACKET-B-01..04)
  - Files: sửa `lib/domain/services/rally_serve_rules.dart` (thêm cuối file); test `test/domain/rally_serve_rules_test.dart`
  - Giao: `int rallySetPointTeam({required int p1, required int p2, required int target, required bool winByTwo, required int cap})` trả 0|1|2 (đội thắng set bằng điểm kế) · `bool rallyGoldenPoint({required int p1, required int p2, required int cap})` (p1 == p2 == cap - 1) cho 3.1
  - Nhận: (không)
  - Chủ file chung: 1.2 giữ `rally_serve_rules.dart`
  - Phụ thuộc: không

- [ ] 1.3 Bố cục ô sân: ai đứng ô nào, ai giao, ai nhận. Tiêu chí: `flutter test --no-pub test/domain/racket_court_layout_test.dart` → exit 0 (TC-RACKET-L-01..06: 4 ví dụ trong mock Lavish + trận đơn + màn dọc)
  - Files: tạo `lib/domain/services/racket_court_layout.dart`; test `test/domain/racket_court_layout_test.dart`
  - Giao: `enum CourtCellRole { none, server, receiver }` · `class RacketCourtCell { final int team; final bool rightCourt; final int? playerIndex; final CourtCellRole role; }` · `List<RacketCourtCell> racketCourtCells({required int serverTeam, required bool serverRight, required int? serverPlayerIndex, required int team1Size, required int team2Size, int? receiverPlayerIndex})` luôn trả 4 ô (đội 1 phải/trái, đội 2 phải/trái), ô không có người có `playerIndex == null`, dùng cho 3.1
  - Nhận: `tennis*`/`rally*` từ 1.1, 1.2 không cần; tham số truyền vào từ 3.2
  - Chủ file chung: 1.3 giữ `racket_court_layout.dart`
  - Phụ thuộc: không (có thể làm song song với 1.1, 1.2 nhưng cùng một agent)

- [ ] 1.4 Pickleball: người nhận và trận đơn nhận chéo. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_test.dart` → exit 0 (thêm TC-PLF-RECV-01..04: đôi giao ô phải thì nhận ô phải đội kia, đơn nhận chéo không theo điểm riêng, đơn đổi ô theo điểm đội giao, không đội giao thì không có nhận; các TC-PLF cũ giữ xanh)
  - Files: sửa `lib/features/match/utils/pickleball_court.dart` (`CourtLayout` :340 thêm field, `resolveCourtLayout` :403 điền, `_slotsFor` :732 trận đơn); test `test/match/pickleball_court_test.dart`
  - Giao: `CourtLayout.receiverCell: CourtCell?` · `CourtLayout.receiverPlayerIndex: int?` cho 3.3
  - Nhận: (không)
  - Chủ file chung: 1.4 giữ `pickleball_court.dart`
  - Phụ thuộc: không

- [ ] 1.5 Luật thả cho cầu lông/tennis (lớp mỏng trên `resolveCourtDrop`). Tiêu chí: `flutter test --no-pub test/match/racket_court_drag_test.dart` → exit 0 (TC-RACKET-D-01..07 theo mock Lavish: đôi đổi ô, kéo sang nửa kia đổi sân, đơn không đổi ô, tennis đội giao không đổi ô, thả trái bóng đổi người giao và đội, thả lên chính mình hoặc nửa sân thì không làm gì, hết trận thì không nhận thả)
  - Files: tạo `lib/features/match/utils/racket_court_drag.dart`; test `test/match/racket_court_drag_test.dart`
  - Giao: `CourtDropAction? racketResolveDrop({required CourtDragSource source, required CourtDropTarget target, required int? servingTeam, required bool isDoubles, required bool isTennis, required bool finished})` gọi `resolveCourtDrop` rồi chặn `SwapPlaces` khi `!isDoubles` hoặc (`isTennis` và `source.team == servingTeam`) cho 2.1, 3.1
  - Nhận: `resolveCourtDrop`, `CourtDragSource`, `CourtDropTarget`, `CourtDropAction` từ `lib/features/match/utils/court_drag.dart` (đã có)
  - Chủ file chung: 1.5 giữ `racket_court_drag.dart`
  - Phụ thuộc: không

## 2. State và notifier

- [ ] 2.1 State người giao đầu, đổi ô/đổi sân tay + ngăn xếp Hoàn tác riêng. Tiêu chí: `flutter test --no-pub test/match/score_panel_notifier_racket_test.dart` → exit 0 (TC-RACKET-N-01..11: áp thả `SwapPlaces`/`SwitchEnds`/`SetServer` đều Hoàn tác được, đổi ô không đổi điểm,  chọn người giao đầu chỉ lúc 0-0, cầu lông cộng điểm giữ `lastWinner/swaps`, Hoàn tác 3 bước trả đúng người giao, `−` làm lịch sử chưa biết, Hoàn tác không vượt qua set đã chốt, 50 bước tối đa, tennis đôi luân phiên người giao, tennis tie-break)
  - Files: sửa `lib/features/match/notifiers/score_panel_state.dart` (thêm `RacketServePick` có `rightStarterTeam1/2`, `endsFlipped`, `RacketUndoStep`, hai field `racketPick`, `racketUndo` vào `ScorePanelState` + `copyWith`); sửa `lib/features/match/notifiers/score_panel_notifier.dart` (`rallyAddPoint` :836, `rallyRemovePoint` :885, `tennisAwardPoint` :549, `tennisRemovePoint` :573, `_rallyAfterPoint` :851: truyền `firstServer`); sửa `lib/features/match/notifiers/score_panel_tennis.dart` (`tennisServerTeam` nhận `firstServer` từ `racketPick`); tạo test `test/match/score_panel_notifier_racket_test.dart`
  - Giao: `class RacketServePick { final int firstTeam; final int firstPlayerTeam1; final int firstPlayerTeam2; final int rightStarterTeam1; final int rightStarterTeam2; final bool endsFlipped; }` (0|1) · `ScorePanelNotifier.racketApplyDrop(CourtDropAction action)` (SwapPlaces → đổi `rightStarter`, SwitchEnds → đảo `endsFlipped`, SetServer → `racketCorrectServer`; mỗi cái một bước Hoàn tác) · `ScorePanelNotifier.racketPickFirstServer(int team, int playerIndex)` (chỉ khi cả set 0-0 và chưa có điểm, ngược lại không làm gì) · `ScorePanelNotifier.racketCorrectServer(int team, int playerIndex)` (từ `⋯`, đánh dấu lịch sử cầu lông chưa biết) · `ScorePanelNotifier.racketUndoStep()` · `bool ScorePanelState.canRacketUndo` · `int ScorePanelState.racketServerPlayerIndex(int team)` cho 3.1, 3.2
  - Nhận: 1.1 (`tennisServerPlayerIndex`, `tennisTeamServiceGames`), 1.2 (không cần ở đây), 1.5 (`racketResolveDrop` do widget gọi trước, notifier chỉ nhận action hợp lệ)
  - Chủ file chung: 2.1 giữ `score_panel_state.dart`, `score_panel_notifier.dart`, `score_panel_tennis.dart`
  - Phụ thuộc: sau 1.1, 1.5

## 3. Giao diện sân

- [ ] 3.1 Widget sân (ngang + dọc), dải giữa, thanh dưới, kéo thả. Tiêu chí: `flutter test --no-pub test/match/racket_court_view_test.dart` → exit 0 (TC-RACKET-W-01..12: kéo VĐV lên đồng đội gọi `onDrop(SwapPlaces)`, kéo chip GIAO sang VĐV khác gọi `onDrop(SetServer)`, đơn không có viền sáng khi kéo trong đội, ô đích hợp lệ có viền xanh, bấm ô khi đã có điểm mở thao tác tương đương,  chip GIAO đúng ô, viền NHẬN chéo, đơn có ô trống mờ, không tên VĐV thì hiện tên đội, bấm ô lúc 0-0 gọi `onPickServer`, bấm ô khi đã có điểm không gọi, hoàn tác tắt khi hết bước, không có nút "Đổi giao")
  - Files: tạo `lib/features/match/widgets/racket_court_view.dart` (vẽ từ `RacketCourtCell`), `lib/features/match/widgets/racket_court_bar.dart` (thanh dưới + nút), dùng lại `pickleball_court_palette.dart` và `pickleball_court_drag_widgets.dart` (`CourtDraggable`, `CourtDropOutline`, `courtPlayerActions`, `courtPlayerDisplayName`; không sửa file này); test `test/match/racket_court_view_test.dart`
  - Giao: `class RacketCourtView extends StatelessWidget` với `cells: List<RacketCourtCell>`, `team1Players`, `team2Players` (`List<ParticipantPlayer>`), `team1Name`, `team2Name`, `score1`, `score2`, `call: String`, `setText: String`, `chip: String?`, `axis: Axis`, `canScore`, `canUndo`, `onScore(int team, bool increment)`, `onUndo`, `onSwitchEnds`, `onPickServer(int team, int playerIndex)?` (null = đã có điểm), `onDrop(CourtDropAction action)`, `resolveDrop: ResolveCourtDrop`, `onMenu` cho 3.2
  - Nhận: `RacketCourtCell` từ 1.3; `racketResolveDrop` từ 1.5 (qua `resolveDrop`)
  - Chủ file chung: 3.1 giữ `racket_court_view.dart`, `racket_court_bar.dart`
  - Phụ thuộc: sau 1.3, 1.5

- [ ] 3.2 Panel nối state với sân cho cầu lông và tennis, gắn vào màn chấm điểm. Tiêu chí: `flutter test --no-pub test/match/racket_court_panel_test.dart test/match/rally_score_panel_serve_test.dart test/match/tennis_score_panel_test.dart` → exit 0 (TC-RACKET-P-01..06: cầu lông strict hiện sân, Lite và bóng bàn giữ panel cũ, chip điểm set/điểm vàng, tennis hiện Game point/Deuce/đổi sân, `⋯` có "Chọn người giao", test cũ pass sau khi sửa phần khẳng định giao diện cũ)
  - Files: tạo `lib/features/match/widgets/racket_court_panel.dart`; sửa `lib/features/match/widgets/official_score_modal.dart:886-905` (cầu lông strict và tennis strict → `RacketCourtPanel`); sửa `lib/features/match/widgets/badminton_score_panel.dart`; sửa test `test/match/rally_score_panel_serve_test.dart`, `test/match/tennis_score_panel_test.dart`, `test/match/official_score_modal_slice_b_test.dart` (chỉ chỗ khẳng định panel cũ); tạo test `test/match/racket_court_panel_test.dart`
  - Giao: `class RacketCourtPanel extends ConsumerWidget { const RacketCourtPanel({required MatchControlParams params, bool isReadOnly = false}) }`
  - Nhận: `RacketCourtView` từ 3.1; `racketPickFirstServer`, `racketCorrectServer`, `racketUndoStep`, `canRacketUndo`, `racketServerPlayerIndex` từ 2.1; hàm luật từ 1.1, 1.2; `matchSidePlayers` (`core/participants/match_side_players.dart`)
  - Chủ file chung: 3.2 giữ `official_score_modal.dart` (chỉ vùng :878-910), `badminton_score_panel.dart`
  - Phụ thuộc: sau 2.1, 3.1

- [ ] 3.3 Pickleball vẽ NHẬN ở ô chéo. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_scoreboard_test.dart test/match/pickleball_court_panel_actions_test.dart` → exit 0 (thêm TC-PLF-RECV-05..06: ô nhận có nhãn NHẬN và viền nét đứt, đơn hiện đúng ô; test cũ xanh)
  - Files: sửa `lib/features/match/widgets/pickleball_court_scoreboard.dart` (cạnh :512 nơi dùng `serverPlayerIndex`), `lib/features/match/widgets/pickleball_court_panel.dart:437`; test `test/match/pickleball_court_scoreboard_test.dart`
  - Giao: (không)
  - Nhận: `CourtLayout.receiverCell`, `receiverPlayerIndex` từ 1.4; khoá l10n `racketReceive` từ 4.1
  - Chủ file chung: 3.3 giữ `pickleball_court_scoreboard.dart` (chỉ vùng vẽ ô)
  - Phụ thuộc: sau 1.4, 4.1

## 4. Chuỗi hiển thị

- [ ] 4.1 Khoá l10n vi + en (chip luật, GIAO/NHẬN, "Chọn người giao", điểm set, điểm vàng, Game point, Đổi sân, lời hô). Tiêu chí: `flutter gen-l10n` exit 0 và `flutter analyze --no-pub lib/l10n lib/features/match` → exit 0
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (cạnh nhóm `cbdRally*` dòng ~7791); không sửa tay `lib/l10n/app_localizations*.dart`
  - Giao: tên khoá `racketServe`, `racketReceive`, `racketPickServer`, `racketServeHere`, `racketSwapPlaces`, `racketDropHint`, `racketSetPoint(team)`, `racketGoldenPoint`, `racketGamePoint`, `racketAdvantage(team)`, `racketDecidingPoint`, `racketChangeEnds`, `racketTiebreakServe(n)` cho 3.1, 3.2
  - Nhận: (không)
  - Chủ file chung: 4.1 giữ cả hai file `.arb`; task 3.x chỉ dùng khoá, không thêm khoá
  - Phụ thuộc: làm TRƯỚC 3.1 nếu cần biên dịch; thứ tự thực tế: 4.1 → 3.1 → 3.2

## 5. E2E (cloud)

- [ ] 5.1 Sửa E2E hai môn khớp màn mới. Tiêu chí: `python C:/Users/GIGABYTE/.omp/scripts/cloud-test-runner.py run --target app-e2e --app-ref <nhánh đã push> --specs integration_test/xem_bam_diem_rally_test.dart integration_test/xem_bam_diem_tennis_test.dart` → exit 0 trên cloud (không chạy máy này)
  - Files: sửa `integration_test/xem_bam_diem_rally_test.dart`, `integration_test/xem_bam_diem_tennis_test.dart` (chỉ chỗ khẳng định text GIAO/ô cũ, giữ ID TC-CBD-APP-03..07); `integration_test/support/bam_diem.dart` giữ nguyên `_probeNoShots`
  - Giao: (không) · Nhận: `RacketCourtPanel` từ 3.2
  - Chủ file chung: 5.1 giữ hai file integration
  - Phụ thuộc: sau 3.2

## 6. Kiểm cuối

- [ ] 6.1 Phân tích tĩnh và test liên quan. Tiêu chí: `flutter analyze --no-pub lib/domain lib/features/match lib/core/participants` → exit 0; `flutter test --no-pub` cho mọi file test của task 1–3 (kể cả `test/match/pickleball_court_test.dart`, `court_drag_test.dart`) → exit 0; `openspec validate app-bam-diem-san-cau-long-tennis --strict` → exit 0
  - Files: không sửa file mới ngoài sửa lỗi phát hiện
  - Giao/Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1–5
