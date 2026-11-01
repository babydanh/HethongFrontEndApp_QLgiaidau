## 1. Hiển thị hai bên của trận
- [x] 1.1 Thêm widget `ParticipantSideLines` hiện một bên của trận: đội có tên riêng = logo vuông (chữ cái đầu hoặc ảnh logo) + một dòng tên đội; ngược lại mỗi VĐV một dòng avatar + tên viết tắt; bên thắng in đậm kèm dấu tích. Tiêu chí: `flutter test --no-pub test/core/participants/participant_side_lines_test.dart` exit 0 (viết test đỏ trước).
  - Files: sửa `lib/core/participants/participant_display.dart` (thêm widget cuối file, dùng lại `resolveParticipantDisplay`, `abbreviateName`, `_PlayerAvatar`); tạo test `test/core/participants/participant_side_lines_test.dart`
  - Giao: `ParticipantSideLines({required String? teamName, required List<ParticipantPlayer> players, String? logoUrl, bool teamOnly = false, bool won = false})`
  - Chủ file chung: task này giữ `participant_display.dart`
  - Phụ thuộc: không

## 2. Bảng trận
- [x] 2.1 Viết lại `ResultsMatchBoard`: chip lọc + ô tìm + menu "Tới vòng", hộp "Đang đấu" (đỏ) rồi mỗi vòng một hộp, hàng trận dùng `ParticipantSideLines`, điểm ngang hàng; mã `#V…` khi `canManage`, số thứ tự khi người xem; bấm hàng đang đấu mở phòng live; giữ nút bút (hộp chọn nhập điểm) và nút xếp lịch cho Ban tổ chức; chuỗi qua l10n. Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_match_board_test.dart` exit 0.
  - Files: sửa `lib/features/tournament/widgets/results_match_board.dart`, tạo `lib/features/tournament/widgets/results_match_row.dart` (tách hàng trận cho gọn file), sửa `lib/features/tournament/utils/results_rounds.dart` (thêm `isMatchClosed`), `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ `flutter gen-l10n`), test `test/features/tournament/widgets/results_match_board_test.dart`
  - Giao: `ResultsMatchBoard({tournamentId, isLite, canManage, divisionId})` giữ chữ ký; key hàng `results-row-<id>`, `results-score-<id>`, `results-schedule-<id>` giữ nguyên
  - Chủ file chung: task này giữ `results_match_board.dart` và hai file arb
  - Phụ thuộc: 1.1
- [x] 2.2 `LiveTab` thành vỏ mỏng quanh `ResultsMatchBoard` (kèm chọn hạng mục khi có nhiều hạng mục). Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/live_tab_test.dart` exit 0.
  - Files: sửa `lib/features/tournament/widgets/live_tab.dart`, test `test/features/tournament/widgets/live_tab_test.dart`
  - Giao: `LiveTab({tournamentId, isLite, divisions, selectedDivisionId, onSelectDivision, canManage})`
  - Chủ file chung: task này giữ `live_tab.dart`
  - Phụ thuộc: 2.1

## 3. Tab Kết quả và màn chi tiết
- [x] 3.1 `ResultsTab` bỏ bảng trận, chỉ còn bục vinh danh và icon chia sẻ (`AppShareModal`); bỏ chuỗi cứng sang l10n. Tiêu chí: `flutter test --no-pub test/features/tournament/results_tab_test.dart` exit 0.
  - Files: sửa `lib/features/tournament/widgets/results_tab.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, test `test/features/tournament/results_tab_test.dart`
  - Chủ file chung: 2.1 giữ hai file arb; task này chỉ thêm key sau khi 2.1 xong
  - Phụ thuộc: 2.1
- [x] 3.2 Màn chi tiết: tab "Đang diễn ra" hiện khi giải đang thi đấu hoặc có trận live, truyền tham số mới cho `LiveTab`/`ResultsTab`. Tiêu chí: `flutter analyze --no-pub lib/features/tournament` không lỗi mới; `ripwire affected` các file đã sửa và test nó chọn exit 0.
  - Files: sửa `lib/features/tournament/screens/tournament_intro_screen.dart:652-763`
  - Chủ file chung: task này giữ `tournament_intro_screen.dart`
  - Phụ thuộc: 2.2, 3.1

## 4. Kiểm chứng
- [x] 4.1 `flutter analyze --no-pub` các file đã sửa; chạy test hẹp; `app-run.py status` không lỗi nhánh này; chụp màn thật khi điện thoại thức. Tiêu chí: exit 0.
  - Phụ thuộc: 3.2
