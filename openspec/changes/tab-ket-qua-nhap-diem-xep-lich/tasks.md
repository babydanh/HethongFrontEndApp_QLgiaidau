## 1. Hàm thuần luật kết quả (port từ Web `results.ts`)

- [x] 1.1 Viết test đỏ rồi tạo `results_rounds.dart`: `canEnterScore`, `isLiveMatch`, `buildResultsRounds`, `splitResultsMatches`, `splitUpcomingByTime`, `defaultResultsRoundKey`. Tiêu chí: `flutter test --no-pub test/features/tournament/utils/results_rounds_test.dart` → exit 0 (đã thấy đỏ trước khi viết code)
  - Files: tạo `lib/features/tournament/utils/results_rounds.dart`; test `test/features/tournament/utils/results_rounds_test.dart`
  - Giao: `bool canEnterScore(MatchModel m)`; `bool isLiveMatch(MatchModel m)` (`m.isLive`, không BYE, `completedAt == null`, `winnerId` rỗng, `hasTeams`); `List<ResultsRound> buildResultsRounds(List<MatchModel> all, String Function(MatchModel) labelOf)` (bỏ BYE, `pending` = số trận `canEnterScore`, sắp theo `min(round)` rồi nhãn, trong vòng theo `matchNumber`); `({List<MatchModel> live, List<MatchModel> finished, List<MatchModel> upcoming}) splitResultsMatches(List<MatchModel>)` (`live` = `isLiveMatch` theo `matchNumber`; finished mới nhất trước theo `completedAt ?? scheduledTime`; upcoming sớm trước, không giờ cuối, KHÔNG chứa trận live); `splitUpcomingByTime`; `String? defaultResultsRoundKey(List<ResultsRound>)` (vòng đầu còn chờ nhập, không có thì vòng cuối, rỗng thì null) cho 4.1 · Nhận: `MatchModel` (`lib/domain/entities/match.dart`)
  - Chủ file chung: 1.1 sở hữu `results_rounds.dart`
  - Phụ thuộc: không

## 2. Chuỗi hiển thị

- [x] 2.1 Thêm chuỗi mới (bảng trận, "Đã xong", "Sắp tới", "chờ nhập", "Xếp lịch", hộp xếp lịch, lỗi lưu lịch, trạng thái rỗng, tiêu đề khối "Đang diễn ra", chú giải nút nhập điểm trên card live) vào cả hai ARB rồi sinh l10n. Tiêu chí: `flutter gen-l10n` → exit 0 và `flutter analyze --no-pub lib/l10n` → exit 0
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (không sửa tay `app_localizations*.dart`)
  - Giao: các key l10n dùng bởi 4.1, 5.1, 6.1 · Nhận: (không)
  - Chủ file chung: 2.1 sở hữu cả hai ARB; task khác cần thêm key thì phải đi qua 2.1
  - Phụ thuộc: không

## 3. Card trận đang diễn ra

- [x] 3.1 Widget test đỏ rồi tạo `live_match_summary_card.dart` (chấm đỏ nhấp nháy, nhãn lượt, mã trận, hai đội avatar + tên cắt "…", tỉ số ván to + điểm từng ván, "giờ · sân", nút bút khi `onScore != null`). Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/live_match_summary_card_test.dart` → exit 0 (đỏ trước; ca thiếu giờ/sân, tên dài ở 320 dp không overflow, `onScore == null` không có nút bút, chạm card gọi `onTap`, chạm nút bút chỉ gọi `onScore`)
  - Files: tạo `lib/features/tournament/widgets/live_match_summary_card.dart`; test `test/features/tournament/widgets/live_match_summary_card_test.dart`
  - Giao: `LiveMatchSummaryCard({required MatchModel match, required String roundLabel, required VoidCallback onTap, String? matchCode, VoidCallback? onScore})` · Nhận: `MatchModel.currentLiveScore`, `scoreHistory`, `matchSideTeamName`, `matchSidePlayers`, `TournamentLocationFormatter.matchShortCourt`, key l10n từ 2.1
  - Chủ file chung: 3.1 sở hữu `live_match_summary_card.dart`; KHÔNG sửa `live_match_card_v2.dart` (còn 4 nơi khác dùng)
  - Phụ thuộc: sau 2.1

- [x] 3.2 `LiveTab` dùng `LiveMatchSummaryCard` thay `LiveMatchCardV2`; nhận `canManage`; danh sách và số đếm lấy từ `isLiveMatch` (một nguồn). Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/live_tab_test.dart` → exit 0 (đỏ trước; ca 2 hạng mục đếm khớp danh sách, trận ONGOING đã có `winnerId` không hiện, `canManage=false` không có nút bút)
  - Files: sửa `lib/features/tournament/widgets/live_tab.dart`, `lib/features/tournament/screens/tournament_intro_screen.dart` (~632–635 dùng `isLiveMatch`, ~703–716 truyền `canManage`); test `test/features/tournament/widgets/live_tab_test.dart`
  - Giao: `LiveTab({..., bool canManage = false})` · Nhận: 1.1, 3.1
  - Chủ file chung: `tournament_intro_screen.dart` do 4.1 giữ; 3.2 chỉ sửa các dòng ~632–635 và ~703–716, làm TRƯỚC 4.1
  - Phụ thuộc: sau 1.1, 3.1

## 4. Bảng trận trong tab Kết quả

- [x] 4.1 Widget test đỏ rồi tạo `results_match_board.dart`; `ResultsTab` thêm `canManage` và ghép bảng trận phía trên trao thưởng, khối "Đang diễn ra" (card 3.1) ở đầu bảng; hiện tab khi `hasResults || canManage`. Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_match_board_test.dart` → exit 0 (đỏ trước), `flutter analyze --no-pub lib/features/tournament` → exit 0
  - Files: tạo `lib/features/tournament/widgets/results_match_board.dart`; sửa `lib/features/tournament/widgets/results_tab.dart`, `lib/features/tournament/screens/tournament_intro_screen.dart` (điều kiện hiện tab ~506–520, truyền `canManage` ~643–646, 720–721); test `test/features/tournament/widgets/results_match_board_test.dart`
  - Giao: `ResultsMatchBoard({tournamentId, isLite, canManage, divisionId})`, `ResultsTab({..., bool isLite = false, bool canManage = false})`; `matchDivisionId(MatchModel)` ở `results_rounds.dart` là nguồn lọc hạng mục chung cho `LiveTab` và bảng trận · Nhận: 1.1 (hàm thuần), 2.1 (key l10n), `MatchScoreEntryChooser.show(context, {match, tournamentId})`, `MatchRoundLabel.formatRound`
  - Chủ file chung: 4.1 giữ `tournament_intro_screen.dart`
  - Phụ thuộc: sau 1.1, 2.1, 3.1, 3.2
  - Kiểm: khối Đang diễn ra ẩn khi không có trận live, trận live không lặp ở Sắp tới, số đếm = số card; hàng chờ nhập bấm được chỉ khi `canManage`; ADMIN không phải BTC không có thao tác; lỗi mạng giữ dữ liệu cũ; hạng mục khác lọc đúng `divisionId`

## 5. Hộp xếp lịch một trận

- [x] 5.1 Widget test đỏ rồi tạo `match_schedule_dialog.dart` (sân, ngày giờ, thời lượng, Lưu, Bỏ lịch; `_saving` chặn bấm đúp; `on DioException`; kiểm `mounted`). Tiêu chí: `flutter test --no-pub test/features/bracket/widgets/match_schedule_dialog_test.dart` → exit 0 (đỏ trước; có ca bấm đúp chỉ gửi 1 yêu cầu, ca lỗi giữ dữ liệu nhập, ca bỏ lịch)
  - Files: tạo `lib/features/bracket/widgets/match_schedule_dialog.dart`; test `test/features/bracket/widgets/match_schedule_dialog_test.dart`
  - Giao: `Future<bool?> showMatchScheduleDialog(BuildContext, {required String tournamentId, required MatchModel match})` (true khi đã lưu) · Nhận: `MatchRepository.updateSchedule(tournamentId, matchId, {courtName, courtAddress, courtId, scheduledAt, durationMinutes, clear})`, `scheduleDurationOptions`, `isScheduleLocked`, 2.1
  - Chủ file chung: 5.1 sở hữu `match_schedule_dialog.dart`
  - Phụ thuộc: sau 2.1

## 6. Nút Xếp lịch và nhập điểm ở Bracket, Lịch, bảng trận

- [ ] 6.1 (Đã làm: nút Xếp lịch ở hàng bảng trận tab Kết quả, `ResultsMatchBoard._scheduleAction`, mở hộp 5.1 rồi invalidate provider trận. Còn lại, hoãn đến khi `bang-dau-gon-search-so-do` và `ma-tran` lên main để khỏi xung đột: `onSchedule` ở `bracket_match_card.dart`, `match_table_row.dart`, tab Lịch) Thêm callback `onSchedule` vào thẻ Bracket và hàng bảng trận; nối hộp xếp lịch và `MatchScoreEntryChooser` dùng chung `canEnterScore`; invalidate provider trận sau khi lưu. Tiêu chí: `flutter test --no-pub test/features/bracket` → exit 0 và `flutter analyze --no-pub lib/features/bracket` → exit 0
  - Files: sửa `lib/features/bracket/widgets/bracket_match_card.dart`, `lib/features/bracket/widgets/match_table_row.dart:162`, `lib/features/bracket/screens/bracket_view_screen.dart` (~259 làm mới, 395–494 quyền nhập điểm), `lib/features/tournament/widgets/results_match_board.dart` (nối nút Xếp lịch, giữ bởi 4.1: chỉ thêm sau khi 4.1 xong), tab Lịch (`matches_tab.dart`); test cạnh các file trên
  - Giao: `onSchedule: VoidCallback?` (null khi không phải BTC hoặc `isScheduleLocked`) · Nhận: 1.1, 4.1, 5.1
  - Chủ file chung: 6.1 chỉ thêm tham số/callback ở các file Bracket (giữ diff nhỏ để rebase với `bang-dau-gon-search-so-do`, `ma-tran`)
  - Phụ thuộc: sau 1.1, 4.1, 5.1

## 7. Kiểm tích hợp

- [ ] 7.1 Phân tích và test liên quan toàn bộ phần đã sửa; chọn test bằng ripwire `affected`. Tiêu chí: `flutter analyze --no-pub lib/features/tournament lib/features/bracket` → exit 0 và `flutter test --no-pub` đúng các file `affected` chọn → exit 0
  - Files: không sửa file mới (chỉ chạy kiểm)
  - Giao: (không) · Nhận: toàn bộ 1.1–6.1
  - Chủ file chung: (không)
  - Phụ thuộc: sau 6.1

## Workflow follow-up

- Sau khi nhánh lên `main`: `openspec archive tab-ket-qua-nhap-diem-xep-lich`.
- Rebase sau `bang-dau-gon-search-so-do` và `ma-tran` (xung đột tiềm tàng ở `bracket_view_screen.dart`, `match_table_row.dart`, 2 ARB).
