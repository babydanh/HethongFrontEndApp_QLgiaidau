## 1. Nền tảng
- [x] 1.1 Thêm `matchCode` vào entity và parse JSON; thêm helper `formatMatchCode` + `abbreviateNameForCode` (TDD: test trước, đỏ rồi xanh, bộ ca trùng Web). Tiêu chí: `flutter test --no-pub test/core/utils/match_code_test.dart` exit 0; `flutter analyze --no-pub` các file đã sửa exit 0.
  - Files: sửa `lib/domain/entities/match.dart:160, 252, 588, 753, 813, 878`, `lib/domain/entities/tournament_workspace.dart:53, 68, 89, 103`, `lib/data/repositories/api/api_tournament_repository.dart:1358-1415`, `lib/data/repositories/api/api_match_repository.dart:694`; tạo `lib/core/utils/match_code.dart`, `test/core/utils/match_code_test.dart`
  - Giao: `String formatMatchCode(Match match)`, `String abbreviateNameForCode(String name)`
  - Chủ file chung: task này sở hữu `match.dart`, `match_code.dart`
  - Phụ thuộc: Backend 2.2 (hợp đồng trường)

## 2. Màn hình
- [x] 2.1 Hiện mã ở dòng bảng trận, nhãn vòng/trận, Vận hành, lưới lịch, workspace, xuất Excel. Tiêu chí: widget test hiện mã khi có và "Trận N" khi thiếu; `flutter test --no-pub test/features/dashboard_screen_typed_football_summary_test.dart --plain-name 'TC-FEAT-12'` exit 0.
  - Files: `lib/features/bracket/widgets/match_table_row.dart:99, 112`, `lib/core/utils/match_round_label.dart:322`, `lib/features/organizer_ops/screens/organizer_ops_screen.dart:3789`, `lib/features/tournament/widgets/schedule_grid.dart:1056`, `lib/features/dashboard/screens/dashboard_screen.dart:998`, `lib/core/services/excel_export_service.dart:42, 204`, `test/features/dashboard_screen_typed_football_summary_test.dart`
  - Nhận: `formatMatchCode` từ 1.1
  - Phụ thuộc: 1.1
- [x] 2.2 Kiểm App có thẻ "Theo vòng"/popup ma trận vòng bảng không; nếu có thì hiện mã cùng quy tắc, nếu không thì ghi vào handoff "không áp dụng". Tiêu chí: kết luận có bằng chứng `rg`/ripwire, kèm test nếu có sửa.
  - Phụ thuộc: 1.1

## 3. Kiểm chứng
- [ ] 3.1 `ripwire affected` các file đã sửa và chạy đúng test nó chọn; xem `app-run.py status` trước khi báo người dùng nhìn máy. Tiêu chí: exit 0, `errors` rỗng với nhánh `ma-tran`.
  - Phụ thuộc: 2.1, 2.2

## 4. Định dạng mã mới (`#DNTB-K1-T3`, không tên tắt VĐV)
Backend trả `matchCode` đầy đủ (`DNTB-K1-T3`); App chỉ thêm `#`. Giữ chữ ký công khai để không phải sửa các màn gọi.
- [x] 4.1 Đổi helper sang định dạng mới (TDD: sửa test trước, thấy đỏ). Tiêu chí: `flutter test --no-pub test/core/utils/match_code_test.dart` exit 0, có ca: Backend trả `DDNTB-K1-T3` cho "Đôi nam trung bình" (hiển thị `#DDNTB-K1-T3`) dù chưa biết đối thủ, thiếu mã → "Trận 7"; `flutter analyze --no-pub lib/core/utils/match_code.dart` exit 0.
  - Files: sửa `lib/core/utils/match_code.dart` (`buildMatchCode`, `matchCodeOrNull`, `formatMatchCode`; xoá `abbreviateNameForCode`/`_sideNameForCode` nếu `uses` không còn nơi dùng), `test/core/utils/match_code_test.dart`; call-site chỉ sửa khi bắt buộc; không `git add` file sinh tự động (`generated_plugin_registrant.*`)
  - Giao: `formatMatchCode(match, {l10n})` và `matchCodeOrNull` giữ chữ ký
  - Chủ file chung: task này sở hữu `match_code.dart`
  - Phụ thuộc: Backend 4.2
- [ ] 4.2 Kiểm tra cuối. Tiêu chí: `flutter test --no-pub` đúng các file test liên quan exit 0; `ripwire affected`; `openspec validate ma-tran-ma-so-tran --strict` exit 0; xem `app-run.py status`.
  - Phụ thuộc: 4.1
