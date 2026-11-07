## 1. Pickleball (chuỗi P, nhánh `cbd-pickleball`)

- [ ] 1.1 Nhặt 2 commit giao bóng mở màn, rồi đổi luật bấm: "+" đội nhận ở side-out = đội giao thua pha (không điểm), nhãn nút giữa thành "MẤT GIAO" + dòng "→ Giao 2 / → đổi giao", thông báo giải thích. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_panel_actions_test.dart test/match/pickleball_court_widget_test.dart` → exit 0 (có TC-CBD-PB-01..04: Giao 1→2, Giao 2→đổi giao, 0-0-2 đổi ngay, đơn đổi ngay)
  - Files: sửa `lib/features/match/widgets/pickleball_court_panel.dart` (`_changeScore`, `_loseServe`, `receiverCanScore`), `lib/features/match/widgets/pickleball_court_view.dart:185` (`lockReceiverPlus`), `lib/features/match/widgets/pickleball_court_scoreboard.dart` (nút ĐỔI GIAO, nút +), `lib/features/match/notifiers/score_panel_notifier.dart` (vùng `pickleball*`), `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (khoá `cbdPb*`); test `test/match/pickleball_court_panel_actions_test.dart`, `test/match/pickleball_court_widget_test.dart`
  - Giao: (không) · Nhận: commit `324b7074`, `402ffbaf` từ nhánh `giao-bong-mo-man-app`
  - Chủ file chung: 1.1 giữ `pickleball_court_*.dart`; `score_panel_notifier.dart` chỉ vùng pickleball
  - Phụ thuộc: (không)
- [ ] 1.2 Sân ngang tràn cả mép trái (bỏ SafeArea trái khi pickleball ngang), nút điều khiển vẫn tránh lỗ camera hai bên. Tiêu chí: `flutter test --no-pub test/match/official_score_modal_pickleball_court_test.dart` → exit 0 (test đỏ trước: `FakeViewPadding(left: 47, right: 47)`, sân `left == 0` và `right == 800`)
  - Files: sửa `lib/features/match/widgets/official_score_modal.dart:171-177` (`bleedRight`, `SafeArea(right:)`), `lib/features/match/widgets/pickleball_court_scoreboard.dart` (đệm hai mép cho hàng nút); test `test/match/official_score_modal_pickleball_court_test.dart:337-350`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.2 giữ `official_score_modal.dart`
  - Phụ thuộc: sau 1.1 (cùng `pickleball_court_scoreboard.dart`)
- [ ] 1.3 Lite pickleball: xác nhận (đọc code + test) Lite dùng rally và không hiện giao bóng side-out; sửa nếu đang hiện. Tiêu chí: `flutter test --no-pub test/match/pickleball_court_panel_actions_test.dart` → exit 0 (TC-CBD-PB-05)
  - Files: sửa `lib/features/match/widgets/pickleball_court_panel.dart` nếu cần; test `test/match/pickleball_court_panel_actions_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: (theo 1.1)
  - Phụ thuộc: sau 1.1

## 2. Cầu lông, bóng bàn, tennis (chuỗi R, nhánh `cbd-rally-tennis`)

- [ ] 2.1 Hàm thuần xác định người giao: cầu lông (người giao = bên vừa thắng pha, ô theo điểm chẵn/lẻ, đôi đổi ô, nghỉ 60s khi đạt 11), bóng bàn (đổi giao mỗi 2 điểm, 10-10 mỗi 1, người giao đầu game đổi luân phiên). Tiêu chí: `flutter test --no-pub test/domain/rally_serve_rules_test.dart` → exit 0 (TC-CBD-RALLY-01..08, đối chiếu `reference/scoring-engine.test.js`)
  - Files: tạo `lib/domain/services/rally_serve_rules.dart`; test `test/domain/rally_serve_rules_test.dart`
  - Giao: `RallyServe rallyServe({required SportRuleKind kind, required int p1, required int p2, required int gameIndex, required bool doubles, int firstServer = 1})` trả `{int? serverTeam, bool? rightCourt}`; `String? rallyServeBanner(...)` · Nhận: (không)
  - Chủ file chung: 2.1 giữ file mới
  - Phụ thuộc: (không)
- [ ] 2.2 Hiện "● GIAO" (+ ô phải/trái cầu lông) dưới tên đội ở thẻ điểm rally, và banner nhắc nghỉ/đổi sân. Tiêu chí: `flutter test --no-pub test/match/rally_score_panel_serve_test.dart` → exit 0 (TC-CBD-RALLY-09..11)
  - Files: sửa `lib/features/match/widgets/rally_score_panel.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (khoá `cbdRally*`); tạo test `test/match/rally_score_panel_serve_test.dart`
  - Giao: (không) · Nhận: `rallyServe` từ 2.1
  - Chủ file chung: 2.2 giữ `rally_score_panel.dart`
  - Phụ thuộc: sau 2.1
- [ ] 2.3 Tennis luật: No-Ad, tie-break theo `tiebreakPoints`/`tiebreakMode` (không cứng 6-6), `finalSetMode` gồm `MATCH_TB10`; người giao đổi mỗi game, tie-break giao 1 điểm đầu rồi mỗi 2. Tiêu chí: `flutter test --no-pub test/domain/tennis_rules_test.dart test/match/score_panel_notifier_tennis_test.dart` → exit 0 (TC-CBD-TN-01..08, đối chiếu `reference/scoring-engine.test.js`)
  - Files: tạo `lib/domain/services/tennis_rules.dart`; sửa `lib/features/match/notifiers/score_panel_notifier.dart` (vùng `tennis*`, `_checkTennisGameEnd`, `_finishTennisGame`), `lib/domain/services/sport_rule_service.dart` (đọc `noAd`, `finalSetMode`); test `test/domain/tennis_rules_test.dart`, `test/match/score_panel_notifier_tennis_test.dart`
  - Giao: `TennisServe tennisServer({...})`, `bool tennisGameWon({required int a, required int b, required bool noAd, required bool tiebreak, int tiebreakTarget = 7})` · Nhận: (không)
  - Chủ file chung: 2.3 giữ `tennis_rules.dart`; notifier chỉ vùng tennis
  - Phụ thuộc: (không)
- [ ] 2.4 Thẻ tennis hiện "● GIAO", banner match tie-break 10 điểm, chip DEUCE ẩn khi No-Ad. Tiêu chí: `flutter test --no-pub test/match/tennis_score_panel_test.dart` → exit 0 (TC-CBD-TN-09..11)
  - Files: sửa `lib/features/match/widgets/tennis_score_panel.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (khoá `cbdTennis*`); test `test/match/tennis_score_panel_test.dart`
  - Giao: (không) · Nhận: `tennisServer`, `tennisGameWon` từ 2.3
  - Chủ file chung: 2.4 giữ `tennis_score_panel.dart`
  - Phụ thuộc: sau 2.3

## 3. Bóng đá (chuỗi F, nhánh `cbd-bong-da`)

- [ ] 3.1 Hàm thuần: ghi thẻ có số áo, vàng thứ 2 → đỏ, đếm người trên sân (<7 dừng trận), giới hạn thay người, chặn ghi bàn ngoài hiệp. Tiêu chí: `flutter test --no-pub test/domain/football_rules_test.dart` → exit 0 (TC-CBD-FB-01..08, đối chiếu `reference/scoring-engine.test.js` phần Football)
  - Files: tạo `lib/domain/services/football_rules.dart`; sửa `lib/features/match/notifiers/score_panel_notifier.dart` (vùng `football*`), `lib/features/match/notifiers/score_panel_state.dart` (`FootballLiveState`: thêm trường tuỳ chọn số áo/thẻ, giữ trường cũ); test `test/domain/football_rules_test.dart`
  - Giao: `FootballLiveState footballApplyCard(FootballLiveState s, {required bool isTeam1, required int? shirt, required bool red})`, `int footballPlayersOnField(FootballLiveState s, bool isTeam1)`, `bool footballGoalAllowed(String phase)` · Nhận: (không)
  - Chủ file chung: 3.1 giữ `football_rules.dart`, `score_panel_state.dart`
  - Phụ thuộc: (không)
- [ ] 3.2 Giao diện: bảng chọn số áo sau khi chọn đội, nhãn "11 người · thay n/5" dưới tên đội, cảnh báo khi ghi bàn ngoài hiệp / hết lượt thay / dưới 7 người. Tiêu chí: `flutter test --no-pub test/match/football_score_panel_test.dart` → exit 0 (TC-CBD-FB-09..12)
  - Files: sửa `lib/features/match/widgets/football_score_panel.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (khoá `cbdFb*`); test `test/match/football_score_panel_test.dart`
  - Giao: (không) · Nhận: hàm từ 3.1
  - Chủ file chung: 3.2 giữ `football_score_panel.dart`
  - Phụ thuộc: sau 3.1

## 4. Web (chuỗi W, repo `HethongFrontEndWeb_QLgiaidau`, nhánh `cbd-web`; change OpenSpec riêng của repo Web)

- [ ] 4.1 Nhặt 2 commit `3f3edff0`, `8c97e2db` (nhánh `giao-bong-mo-man`), rồi áp luật tennis (No-Ad, `tiebreakPoints`/tiebreakAt không cứng 6-6, `MATCH_TB10`) và hiển thị "● GIAO" cầu lông/bóng bàn/tennis ở màn chấm điểm Web; bóng đá nếu Web có màn chấm điểm. Tiêu chí: `pnpm test:unit` chỉ các file liên quan → exit 0 (TC-CBD-WEB-01..10)
  - Files: sửa `src/features/matches/live-score-state.ts:27`, `src/features/matches/side-out.ts`, `src/app/organizer/tournaments/[id]/ops/components/scoring/ScoringPanel.tsx`, `src/app/(public)/live/[matchId]/components/LiveMatchControlPanel.tsx`; tạo `src/features/matches/rally-serve.ts`; test `test/unit/live-score-state.test.ts`, `test/unit/rally-serve.test.ts`
  - Giao: `rallyServe(...)` cùng ngữ nghĩa với 2.1 · Nhận: (không)
  - Chủ file chung: 4.1 giữ các file trên
  - Phụ thuộc: (không)

## 5. Tích hợp và kiểm tra cuối

- [ ] 5.1 Gộp ba nhánh App vào nhánh tích hợp `cach-bam-diem-cac-mon` (giữ ý định cả hai bên ở `app_vi.arb`/`app_en.arb`/`score_panel_notifier.dart`), `flutter gen-l10n`, chạy toàn bộ test hẹp của 1.x–3.x, `flutter analyze --no-pub lib/features/match lib/domain/services`. Tiêu chí: các lệnh trên → exit 0; `python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py` → exit 0
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (giải xung đột), `lib/features/match/notifiers/score_panel_notifier.dart` (giải xung đột)
  - Giao: (không) · Nhận: 1.x, 2.x, 3.x
  - Chủ file chung: 5.1 giữ hai file `.arb`
  - Phụ thuộc: sau 1.3, 2.4, 3.2
