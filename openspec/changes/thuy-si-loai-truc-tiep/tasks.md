Mọi đường dẫn tính từ gốc repo App. Số dòng là số dòng tại `origin/thuy-si-20261021` lúc lập plan (đọc lại code trước khi sửa). Hợp đồng chung: `design.md`, mục "Hợp đồng chung" (Backend là nguồn; KHÔNG đổi tên trường/mã lỗi). Lệnh test hẹp: `flutter test --no-pub <file>`; phân tích: `flutter analyze <file đã đổi>`. Tám test cũ của `test/features/public_bracket_view_test.dart` đỏ sẵn do thiếu asset/`.env` (baseline): không tính là lỗi mới, nhưng test mới thêm phải xanh. `lib/l10n/app_localizations*.dart` là file sinh tự động: chạy `flutter gen-l10n` sau khi sửa `.arb`, không sửa tay. Không chạy flutter run/build/integration test. Cả change làm tuần tự trong MỘT worktree/nhánh theo thứ tự số task. Không sửa file `generated_plugin*` (đã bị sửa sẵn ngoài việc này).

## 1. Model và cấu hình

- [ ] 1.1 `SwissConfig.advanceTopN`. Tiêu chí: `flutter test --no-pub test/domain/entities/swiss_test.dart` → exit 0 (tạo file nếu chưa có; ca: `fromJson` thiếu khóa → 0; `fromJson`/`toJson` khứ hồi giữ 8; `planSwissSave` với stage có `advanceTopN = 8` gửi lại `swiss.advanceTopN = 8`; không đổi gì các ca Swiss sẵn có)
  - Files: sửa `lib/domain/entities/swiss.dart` (`SwissConfig` `:34-77`, `planSwissSave` `:305-336`); test `test/domain/entities/swiss_test.dart` (hoặc file test entity Swiss sẵn có, tìm bằng Glob `test/**/swiss*`)
  - Giao: `SwissConfig({required totalRounds, required tiebreakOrder, required firstRoundPairing, this.advanceTopN = 0})`; `final int advanceTopN;`; `toJson()` có `'advanceTopN'`; `static bool isValidAdvanceTopN(int value)` (0 hoặc 2..64)
  - Nhận: không
  - Chủ file chung: 1.1 giữ `swiss.dart`
  - Phụ thuộc: không
- [ ] 1.2 Ô cấu hình và chuỗi. Tiêu chí: `flutter test --no-pub test/features/swiss_config_editor_test.dart` → exit 0 (ca thêm: ô hiện, nhập 8 → callback trả `advanceTopN = 8`; nhập 1 → báo lỗi và không cho lưu; `locked = true` → ô chỉ đọc, hiện giá trị đã lưu; 0 hiển thị `Không`) và `flutter analyze lib/features/tournament lib/domain/entities/swiss.dart` không lỗi mới
  - Files: sửa `lib/features/tournament/widgets/swiss_config_editor.dart` (316 dòng; thêm ô nhập số, tham số `locked`), `lib/features/tournament/screens/tournament_management_divisions_section.dart` (`:560-680`: nơi tạo/sửa dùng `SwissConfigEditor`, `:630`, `:677`; truyền `locked` khi đã có stage Swiss), `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/swiss_config_editor_test.dart`
  - Giao: chuỗi (khóa arb, vi / en): `swissAdvanceTopN` = `Số đội vào loại trực tiếp` / `Teams advancing to knockout`; `swissAdvanceNone` = `Không` / `None`; `swissAdvanceRange` = `0 hoặc từ {min} đến {max}` / `0, or {min} to {max}`
  - Nhận: `SwissConfig.advanceTopN`, `isValidAdvanceTopN` từ 1.1
  - Chủ file chung: 1.2 giữ `swiss_config_editor.dart` và hai file `.arb` đến hết change
  - Phụ thuộc: sau 1.1

## 2. Sơ đồ

- [ ] 2.1 Nhận ra giải "Thụy Sĩ có loại trực tiếp" (thuần). Tiêu chí: `flutter test --no-pub test/features/bracket/bracket_stage_utils_test.dart` → exit 0 (tạo nếu chưa có; ca: chỉ trận Swiss → false; trận Swiss + trận stage `SINGLE_ELIMINATION` → true; chỉ loại trực tiếp → false; trận stage cũ GSK (vòng bảng + loại trực tiếp) → false)
  - Files: sửa `lib/features/bracket/utils/bracket_stage_utils.dart` (`isSwissMatch`, `isKnockoutMatch` `:3-95`: đọc trước để dùng đúng); test `test/features/bracket/bracket_stage_utils_test.dart`
  - Giao: `bool hasSwissKnockout(Iterable<MatchModel> matches)` (kiểu trận theo `bracket_stage_utils.dart`; true khi có trận `isSwissMatch` và có trận `isKnockoutMatch`)
  - Nhận: không
  - Chủ file chung: 2.1 giữ `bracket_stage_utils.dart`
  - Phụ thuộc: không
- [ ] 2.2 Màn sơ đồ và `PublicBracketView` hiển thị hai phần. Tiêu chí: `flutter test --no-pub test/features/public_bracket_view_test.dart test/features/swiss_standings_view_test.dart` → các test mới thêm xanh (8 test cũ đỏ sẵn đã nêu ở trên không tính) và `flutter analyze lib/features/bracket` không lỗi mới
  - Files: sửa `lib/features/bracket/screens/bracket_view_screen.dart` (chọn `effectiveBracketType` `:310-323`, `:376-405`; các nhánh `isSwiss` `:821,827,963,1001,1005,1019,1306,1343,1392`: nhánh "Swiss thắng mọi nhánh khác" phải nhường khi `hasSwissKnockout`; với `hasSwissKnockout` thì `groupMatches` = trận Swiss, `bracketMatches` = trận loại trực tiếp), `lib/features/bracket/widgets/public_bracket_view.dart` (`_kindOf` `:43-60`, `:79-90`: thêm nhánh hai phần), `lib/features/bracket/widgets/swiss_standings_view.dart` (đường ngăn sau hạng `advanceTopN`, đọc từ `roundConfig.swiss.advanceTopN` của stage qua `SwissStageInfo`, `swiss.dart:232-265`; không thêm chữ mới), `lib/domain/entities/swiss.dart` (nếu cần thêm `advanceTopN` vào `SwissStageInfo`; ĐÃ thuộc 1.1, chỉ thêm getter, không đổi chữ ký cũ); test `test/features/public_bracket_view_test.dart`, `test/features/swiss_standings_view_test.dart`
  - Giao: không đổi chữ ký công khai; `SwissStandingsView` thêm tham số tùy chọn `int cutAfterRank = 0` (0 = không kẻ)
  - Nhận: `hasSwissKnockout` từ 2.1; `SwissConfig.advanceTopN` từ 1.1
  - Chủ file chung: 2.2 giữ `bracket_view_screen.dart`, `public_bracket_view.dart`, `swiss_standings_view.dart`
  - Phụ thuộc: sau 1.1, 2.1

## 3. Kiểm cuối

- [ ] 3.1 Phân tích, test liên quan, bàn giao. Tiêu chí: `flutter analyze lib/domain/entities/swiss.dart lib/features/tournament lib/features/bracket` không lỗi mới so với baseline; `flutter test --no-pub test/features/swiss_config_editor_test.dart test/features/swiss_standings_view_test.dart test/features/swiss_pairing_screen_test.dart test/features/swiss_format_labels_test.dart test/domain test/data/api_tournament_swiss_test.dart` → exit 0
  - Files: `openspec/changes/thuy-si-loai-truc-tiep/handoff.md`
  - Giao: không
  - Nhận: toàn bộ task trên
  - Chủ file chung: 3.1 giữ `handoff.md`
  - Phụ thuộc: sau 2.2
