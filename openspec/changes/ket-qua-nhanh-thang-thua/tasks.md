## 1. Logic thuần (nhánh, khoá vòng, trạng thái hàng, mở/gập)

- [x] 1.1 Thêm nhánh và hàm mở/gập vào `results_rounds.dart`. Tiêu chí: `flutter test --no-pub test/features/tournament/utils/results_rounds_test.dart` → exit 0 (test đỏ trước, xanh sau)
  - Files: sửa `lib/features/tournament/utils/results_rounds.dart` (`ResultsRound`, `buildResultsRounds`, cuối file); test `test/features/tournament/utils/results_rounds_test.dart` (TC-RBR-01..06)
  - Giao: `enum ResultsBranch { main, winners, losers, grandFinal }`; `ResultsBranch branchOfMatch(MatchModel match)`; `ResultsRound.branch` (final ResultsBranch); `enum MatchTone { live, done, cancel, ready, wait }`; `MatchTone matchTone(MatchModel match)`; `bool isRoundBoxOpen({required bool? choice, required bool isDefault, required bool searching})`; `Map<String, bool> openOnlyRound(Iterable<String> keys, String picked)`; · Nhận: (không)
  - Chủ file chung: 1.1 giữ `results_rounds.dart`
  - Phụ thuộc: không
  - Cách làm: `branchOfMatch` đọc `match.bracketPosition.bracket` (`losers`, `grand_final`, `grand_final_reset`, `winners`) và `match.stageType` (`DOUBLE_ELIMINATION` thì `winners`, ngược lại `main`). Khoá nhánh thua `losers|<match.round>`. Sắp: hạng nhánh (main/winners 0, losers 1, grandFinal 2) rồi số vòng nhỏ nhất rồi nhãn. Các test cũ của `buildResultsRounds` phải còn xanh.

## 2. Chuỗi và màu (file dùng chung, một chủ)

- [x] 2.1 Thêm key l10n và màu theo nhánh/trạng thái. Tiêu chí: `flutter gen-l10n` rồi `flutter analyze --no-pub lib/l10n lib/features/tournament/widgets/results_board_palette.dart` → exit 0
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (khối `resultsBoard_*` quanh dòng 7201..7223); sinh lại `lib/l10n/app_localizations*.dart` (không sửa tay); sửa `lib/features/tournament/widgets/results_board_palette.dart`
  - Giao: `resultsBoard_colPair` ("Cặp đấu"), `resultsBoard_colResult` ("Kết quả"), `resultsBoard_referee` ("TT: {name}"), `resultsScore_title`, `resultsScore_set`, `resultsScore_addSet`, `resultsScore_save`, `resultsScore_openLive`, `resultsScore_tied`, `resultsScore_error`; palette `BranchTone ResultsBoardPalette.branchTone(BuildContext, ResultsBranch)` với `BranchTone{head, pill, pillLine, pillText, icon}` và `Color ResultsBoardPalette.toneBorder(MatchTone)` · Nhận: `ResultsBranch`, `MatchTone` từ 1.1
  - Chủ file chung: 2.1 giữ `app_vi.arb`, `app_en.arb`, `app_localizations*.dart`, `results_board_palette.dart` (mọi task sau chỉ đọc, cần key mới thì báo 2.1)
  - Phụ thuộc: sau 1.1
  - Cách làm: màu theo Web `BOX_TONE`: thắng xanh lá, thua hổ phách, chung kết tổng tím, chính xám; viền hàng: ready xanh dương, wait xám, live hồng, done xanh lá (tranh chấp tính là done), cancel xám nhạt; có cả bản tối. Key phải có ở cả vi và en.

## 3. Hộp vòng có màu, gập được, hàng cột

- [x] 3.1 `_MatchBox` đổi màu theo nhánh, bấm đầu hộp để gập/mở, có hàng cột. Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_match_board_test.dart` → exit 0 (thêm TC-RBR-10..16)
  - Files: sửa `lib/features/tournament/widgets/results_match_board.dart` (`_roundBox` ~dòng 318, `_MatchBox` ~dòng 480..560, `build` ~dòng 270..315, thêm `Map<String,bool> _boxChoice`); test `test/features/tournament/widgets/results_match_board_test.dart`, `test/features/tournament/widgets/results_match_board_open_speed_test.dart`
  - Giao: `_MatchBox({title, rows, branch, isLive, open, onToggle})` · Nhận: `ResultsRound.branch`, `isRoundBoxOpen`, `defaultResultsRoundKey` (1.1); `BranchTone`, l10n (2.1)
  - Chủ file chung: 3.1 giữ `results_match_board.dart`
  - Phụ thuộc: sau 1.1, 2.1
  - Cách làm: đầu hộp là `InkWell` có `Semantics(expanded:)`; mũi tên `AnimatedRotation` (easeOutCubic); thân dùng `AnimatedSize` ~200 ms; hộp "Đang đấu" gập được, mặc định mở. Bỏ chip late/disputed khỏi `_filterChips` (giữ enum cho popup tiến trình; chip chỉ hiện khi `_filter` đang là late/disputed) và sửa test chip cũ (`results_match_board_test.dart` ~dòng 693, 742). Khoá test: `results-box-<key>`, `results-box-toggle-<key>`. Hộp gập vẫn dựng đầu hộp để `GlobalKey` còn.

## 4. "Tới vòng" mở đúng một vòng

- [x] 4.1 Menu "Tới vòng" gập các vòng khác, mở vòng chọn, cuộn tới; mục menu có chấm nhánh và số chờ. Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_match_board_test.dart` → exit 0 (thêm TC-RBR-20..22)
  - Files: sửa `lib/features/tournament/widgets/results_match_board.dart` (`_jumpTo` ~dòng 258, `PopupMenuButton` trong `_searchRow` ~dòng 410); test cùng file test của 3.1
  - Giao: `void _jumpTo(String roundKey)` (setState `_boxChoice = openOnlyRound(...)`, chờ 220 ms rồi `Scrollable.ensureVisible`, kiểm `mounted`) · Nhận: `openOnlyRound` (1.1), `_boxChoice` và `GlobalKey` hộp (3.1), l10n `resultsBoard_roundOption` có sẵn
  - Chủ file chung: không (file thuộc 3.1, task này chạy sau 3.1 trong cùng nhánh)
  - Phụ thuộc: sau 3.1
  - Cách làm: bấm hai lần liên tiếp không được cuộn hai lần chồng nhau (huỷ hẹn giờ cũ); `dispose` huỷ hẹn giờ.

## 5. Hàng trận: viền trạng thái, giờ, sân, trọng tài, đơn/đôi

- [x] 5.1 Viền trái theo `matchTone`, dòng meta thêm trọng tài; khoá hành vi đơn/đôi/đội. Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_match_row_test.dart` → exit 0 (file mới, TC-RBR-30..35)
  - Files: sửa `lib/features/tournament/widgets/results_match_row.dart` (`ResultsMatchRow.build` ~dòng 48..100, `_MetaLine._line` ~dòng 330..384); tạo `test/features/tournament/widgets/results_match_row_test.dart`
  - Giao: `ResultsMatchRow` giữ nguyên chữ ký; key mới `results-tone-<matchId>`, `results-meta-referee-<matchId>` · Nhận: `matchTone` (1.1), `ResultsBoardPalette.toneBorder` và l10n `resultsBoard_referee` (2.1)
  - Chủ file chung: 5.1 giữ `results_match_row.dart`
  - Phụ thuộc: sau 2.1 (song song được với 3.1, 4.1 vì khác file)
  - Cách làm: nút "+" nhập điểm: vòng tròn 32 dp, vùng bấm 44 dp, căn giữa dọc cột Kết quả giữa hai bên (key `results-add-score-<matchId>` giữ nguyên). Không sửa `ParticipantSideLines` (đã hiện đôi "A / B" có ảnh, đội có logo); test dựng ba trận (đơn, đôi, đội có logo) và khẳng định số tên/ảnh.

## 6. Popup nhập điểm

- [x] 6.1 Popup nhập điểm tại bảng. Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_score_dialog_test.dart` → exit 0 (file mới, TC-RBR-40..46)
  - Files: tạo `lib/features/tournament/widgets/results_score_dialog.dart`; sửa `lib/features/tournament/widgets/results_match_board.dart` (`_scoreAction` ~dòng 185: gọi popup thay `MatchScoreEntryChooser.show`; sau lưu `ref.invalidate(matchesProvider / liteBracketMatchesProvider)` như `_openSchedule`); test `test/features/tournament/widgets/results_score_dialog_test.dart`
  - Giao: `Future<bool?> showResultsScoreDialog(BuildContext context, {required MatchModel match, required String tournamentId, required String liveRoute})` (true khi đã lưu) · Nhận: `MatchRepository.updateScoreDetails(...)` có sẵn qua `matchRepositoryProvider`; `SetScoreData` (`lib/domain/services/sport_rule_service.dart:328`); `ParticipantSideLines`; l10n 2.1
  - Chủ file chung: 6.1 giữ `results_score_dialog.dart`; `results_match_board.dart` mượn tạm sau 4.1
  - Phụ thuộc: sau 4.1 (cùng file board), sau 2.1
  - Cách làm: tách logic tính set thắng/bên thắng thành hàm thuần trong cùng file để test; nút Lưu khoá khi hoà set hoặc đang gửi (chống bấm đúp); lỗi mạng giữ popup, hiện lỗi, mở lại nút; nút "Vào trang Live" `context.push(liveRoute)`. Nếu gặp luật điểm phức tạp hơn "số set", dừng và báo, chỉ giữ nút "Vào trang Live".

- [x] 6.2 Ô "Ngày giờ thi đấu" trong popup như `PlayedAtField` của Web; giờ đã nhập hiện ở dòng trận và đầu popup. Tiêu chí: `flutter test --no-pub test/features/tournament/utils/played_at_test.dart test/features/tournament/widgets/results_score_dialog_test.dart test/features/tournament/widgets/results_match_row_test.dart` → exit 0 (TC-RBR-34, TC-RBR-50..57, TC-RBR-60..67)
  - Files: tạo `lib/features/tournament/utils/played_at.dart`; sửa `lib/domain/entities/match.dart` (`playedDate`, `playedTime`), `lib/domain/repositories/match_repository.dart:108`, `lib/data/repositories/api/api_match_repository.dart:1235` (`playedAt`), `lib/features/tournament/widgets/results_score_dialog.dart`, `lib/features/tournament/widgets/results_match_row.dart` (`resultsMatchClock`), `lib/l10n/app_vi.arb`, `app_en.arb` (+ sinh lại `app_localizations*.dart`); test `test/features/tournament/utils/played_at_test.dart` (mới), `results_score_dialog_test.dart`, `results_match_row_test.dart`
  - Giao: `typedef PlayedAt = ({String date, String? time})`; `PlayedAt? parsePlayedAt(String)`; `String formatPlayedAt(PlayedAt)`; `PlayedAt seedPlayedAt({playedDate, playedTime, today})`; `String resultsMatchClock(MatchModel)`; tham số `playedAt` của `updateScoreDetails` · Nhận: Backend `UpdateMatchScoreDto.playedDate/playedTime` và `MatchResponseDto.playedDate/playedTime` (đã có trên `origin/main`, không đổi Backend)
  - Chủ file chung: 6.2 giữ `played_at.dart`; mượn `results_score_dialog.dart`, `results_match_row.dart`, `app_*.arb` sau 6.1
  - Phụ thuộc: sau 6.1
  - Cách làm: một ô chữ `dd/mm/yyyy HH:mm` (giờ không bắt buộc) và nút lịch mở chọn ngày rồi chọn giờ. Mặc định là giá trị đã lưu, không có thì hôm nay và để trống giờ (không đoán giờ). Ô trống thì không gửi `playedAt` (Backend giữ nguyên); ô sai thì khoá Lưu. Chỉ gửi khi có `tournamentId` (endpoint CLB không nhận).

## 7. Kiểm tra cuối

- [x] 7.1 Phân tích tĩnh, test liên quan, kiểm phạm vi ảnh hưởng. Tiêu chí: `flutter analyze --no-pub lib/features/tournament/widgets lib/features/tournament/utils lib/l10n` → exit 0 (thư mục `lib/features/tournament` còn 10 info cũ ở file khác, không thuộc change này); `flutter test --no-pub` cho đúng các file test ở 1.1, 3.1, 5.1, 6.1 và `test/features/tournament/management_results_tab_test.dart` → exit 0; `openspec validate ket-qua-nhanh-thang-thua --strict` → exit 0
  - Kết quả: analyze phạm vi đã sửa exit 0; test liên quan (board, hàng, popup, rounds, tab quản lý, step summary, live tab) exit 0; validate exit 0. Chụp điện thoại CHƯA làm: máy đang tắt màn hình (Dozing) và app còn build.
  - Files: không sửa code; chạy ripwire `affected` với các file đã sửa và chạy đúng test nó nêu
  - Giao: (không) · Nhận: toàn bộ task 1..6
  - Chủ file chung: không
  - Phụ thuộc: sau 6.1
  - Cách làm: chạy trên điện thoại qua `app-run.py status` (một app chung), chụp màn Kết quả của giải loại kép: hộp xanh lá/hổ phách/tím, gập mở, "Tới vòng", popup. Test nặng toàn bộ chạy cloud qua `cloud-test-runner`, không chạy local.
