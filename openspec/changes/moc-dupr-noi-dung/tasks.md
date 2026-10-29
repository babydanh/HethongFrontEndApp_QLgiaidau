# Tasks

Phụ thuộc Backend: change `moc-dupr-noi-dung` của Backend phải apply trước (cung cấp `minDupr`, `maxDupr`, `DUPR_LIMIT_VIOLATION`). Thứ tự App: 1.1 → 1.2 → 2.1 → (3.1, 4.1) → 5.1 → 6.1, tuần tự trong một worktree. Không chạy `flutter run`, không build, không integration test; chỉ `flutter test --no-pub <file>`.

## 1. Nền tảng

- [x] 1.1 Tạo `lib/core/utils/dupr_limit.dart`: `const List<double> duprLimitOptions` (2.0 → 6.0 bước 0.5), `enum DuprLimitStatus { ok, missing, belowMin, aboveMax }`, `DuprLimitStatus checkDuprAgainstLimit({required double? value, required double? minDupr, required double? maxDupr})` (không có mốc → `ok`; có mốc mà `value == null` → `missing`; biên đóng), `String? formatDuprRange(double? minDupr, double? maxDupr)` (`3.0 – 3.5`, `≤ 3.5`, `≥ 3.0`, `null` khi không có mốc), `double? pickDuprFromRatings(List<Map<String, dynamic>> rows)` (dòng `source == 'API'` trước, rồi `SELF`, `null` khi rỗng). Thêm `minDupr`, `maxDupr` (`double?`) vào `TournamentDivisionOption` và `fromJson` (camelCase và snake_case, dùng `_parseDouble`). Tiêu chí: `flutter test --no-pub test/core/dupr_limit_test.dart test/registration/division_option_parse_test.dart` → exit 0 (biên đóng 3.0 và 3.5; 3.62 với đến 3.5 ra `aboveMax`; `null` ra `missing`; không mốc ra `ok`; format ba dạng; API thắng SELF; parse `minDupr` dạng chuỗi số lẫn số).
  - Files: tạo `lib/core/utils/dupr_limit.dart`, `test/core/dupr_limit_test.dart`; sửa `lib/domain/entities/tournament_registration.dart:~26-30,~129-177`, `test/registration/division_option_parse_test.dart`
  - Giao: các hàm/kiểu trên cho 3, 4 · Nhận: không
  - Chủ file chung: 1.1 giữ `tournament_registration.dart`
  - Phụ thuộc: không

- [x] 1.2 Thêm khoá l10n vi và en (cùng tên): nhóm editor (`divisionEditorDuprLimit`, `divisionEditorDuprFrom`, `divisionEditorDuprTo`, `divisionEditorDuprUnlimited`, `divisionEditorDuprInclusiveHint`, `divisionEditorAccDupr`, `divisionEditorAccDuprNone`), nhóm đăng ký (`registerDuprRange` tham số `{range}`, `registerDuprChecking`, `registerDuprMatches`, `registerDuprBelowMin` và `registerDuprAboveMax` tham số `{value}`, `{range}`, `registerDuprMissing`, `registerDuprInputLabel`, `registerDuprSave`, `registerDuprSaved`, `registerDuprSaveFailed`, `registerDuprSelfDeclaredNote`), đặt cạnh khoá ELO (`divisionEditorEloLimit` ~dòng 6620, `registerEloRange` ~813). Chỉ thêm khoá, không đổi khoá cũ; chạy `flutter gen-l10n` sinh lại `lib/l10n/*`. Tiêu chí: `flutter gen-l10n` exit 0 và `flutter test --no-pub test/core/dupr_l10n_keys_test.dart` → exit 0 (test đọc hai file .arb, mọi khoá `*Dupr*` có ở cả hai và placeholder khớp).
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, sinh lại `lib/l10n/app_localizations*.dart`; tạo `test/core/dupr_l10n_keys_test.dart`
  - Giao: khoá cho 3, 4, 5 · Nhận: không
  - Chủ file chung: 1.2 giữ phần DUPR trong hai file .arb (lane khác cũng sửa: chỉ thêm cuối nhóm)
  - Phụ thuộc: sau 1.1

## 2. Client điểm quốc tế

- [x] 2.1 Tạo `abstract class ExternalRatingRepository { Future<double?> getMyDuprRating({required String categoryId, required String matchType}); Future<void> saveMyDuprRating({required String categoryId, required String matchType, required double value}); }` ở `lib/domain/repositories/external_rating_repository.dart`; bản `ApiExternalRatingRepository` ở `lib/data/repositories/api/api_external_rating_repository.dart` (Dio như `api_ranking_repository.dart`): GET `/users/me/external-ratings` với `provider=DUPR`, `categoryId`, `matchType`, `limit=100`, đọc đúng dạng body thật của Backend (đọc `external-ratings-page-response.dto.ts` và cách repository khác bóc `data`), dùng `pickDuprFromRatings`; PUT cùng đường dẫn với `provider: 'DUPR'`, `isPublic: true`. Thêm `externalRatingRepositoryProvider` vào `lib/core/di/repository_providers.dart`. Tiêu chí: `flutter test --no-pub test/data/api_external_rating_repository_test.dart` → exit 0 (mock Dio: đọc đúng query, trả `null` khi rỗng, PUT đúng body, lỗi mạng ném ra ngoài).
  - Files: tạo hai file trên và `test/data/api_external_rating_repository_test.dart`; sửa `lib/core/di/repository_providers.dart`
  - Giao: `externalRatingRepositoryProvider` cho 4 · Nhận: `pickDuprFromRatings` từ 1.1
  - Chủ file chung: 2.1 giữ `repository_providers.dart` cho phần này
  - Phụ thuộc: sau 1.1

## 3. Editor nội dung

- [ ] 3.1 `division_editor_sheet.dart`: mục accordion `dupr` (cạnh mục `elo` ~577) chỉ khi `_isPickleball`; hai `DropdownButtonFormField` Từ/Đến (key `division-editor-dupr-min`, `division-editor-dupr-max`) từ `duprLimitOptions` cộng giá trị ngoài danh sách khi gặp, mục "Không giới hạn"; Từ > Đến thì Đến về `null`; nạp từ `widget.division?['minDupr']`/`['maxDupr']` (số hoặc chuỗi số); payload (~1589) thêm `minDupr`/`maxDupr` khi `_isPickleball` (kể cả `null` để xoá), không thêm khi môn khác. Không tái cấu trúc phần ELO. Tiêu chí: `flutter test --no-pub test/features/division_editor_sheet_test.dart` → exit 0 (thêm ca: chọn 3.0–3.5 ra payload đúng; Từ > Đến; môn khác không có mục; mở nội dung có mốc rồi xoá ra `null`).
  - Files: sửa `lib/features/tournament/widgets/division_editor_sheet.dart`, `test/features/division_editor_sheet_test.dart`
  - Giao: nội dung gửi `minDupr`, `maxDupr` · Nhận: 1.1, 1.2
  - Chủ file chung: 3.1 giữ `division_editor_sheet.dart`
  - Phụ thuộc: sau 1.2

## 4. Màn đăng ký

- [ ] 4.1 Tạo `lib/features/register/widgets/dupr_limit_card.dart` (`DuprLimitCard({required TournamentDivisionOption division, required ValueChanged<bool> onValidityChanged})`): không mốc → `SizedBox.shrink()` và không gọi repository; có mốc → đọc điểm qua `externalRatingRepositoryProvider`, hiện trạng thái (đang kiểm / hợp lệ / thấp / cao / chưa khai), ô nhập + nút lưu khi `missing` (nút tắt lúc đang gửi, lỗi giữ số đã nhập), báo `onValidityChanged`. Dùng trong `tournament_register_screen.dart` (dòng nội dung `_divisionMeta` ~895-902 thêm `registerDuprRange`; thẻ đặt cạnh khối ELO ~2161-2187; khoá nút ở `_register` ~702-706) và `doubles_registration_screen.dart` (cạnh `_checkElo` ~426-452 và chỗ khoá đăng ký). Tiêu chí: `flutter test --no-pub test/features/register/dupr_limit_card_test.dart test/registration/tournament_register_elo_gate_test.dart` → exit 0 (card: không mốc không gọi repo; 3.2 hợp lệ; 3.62 vượt; chưa khai rồi lưu thì hợp lệ; lưu lỗi giữ số; test ELO cũ vẫn xanh).
  - Files: tạo `lib/features/register/widgets/dupr_limit_card.dart`, `test/features/register/dupr_limit_card_test.dart`; sửa `lib/features/register/screens/tournament_register_screen.dart`, `lib/features/register/screens/doubles_registration_screen.dart`
  - Giao: không · Nhận: 1.1, 1.2, 2.1
  - Chủ file chung: 4.1 giữ hai màn đăng ký
  - Phụ thuộc: sau 2.1 (có thể song song với 3.1 vì file không trùng)

## 5. Lỗi từ Backend

- [ ] 5.1 Xác nhận `ErrorParser.parse` đã trả nguyên `message` của body lỗi `{ code: 'DUPR_LIMIT_VIOLATION', message }` (viết test trước). Nếu không (bị khớp chuỗi con khác hoặc rơi về fallback) thì thêm đúng một nhánh theo `code` trong `lib/core/utils/error_parser.dart`. Đường vào đội `join_team_screen.dart:49` và `tournament_register_screen.dart:~821-850` đã dùng `ErrorParser`; chỉ sửa khi test cho thấy thiếu. Tiêu chí: `flutter test --no-pub test/core/error_parser_dupr_test.dart` → exit 0 (400 + `DUPR_LIMIT_VIOLATION` ra đúng message Backend; lỗi khác không đổi).
  - Files: tạo `test/core/error_parser_dupr_test.dart`; sửa `lib/core/utils/error_parser.dart` (chỉ nếu test đỏ), `lib/features/register/screens/join_team_screen.dart` (chỉ nếu cần)
  - Giao: không · Nhận: không
  - Chủ file chung: không
  - Phụ thuộc: sau 1.2

## 6. Kiểm tổng

- [ ] 6.1 `flutter analyze lib/core lib/domain lib/data lib/features/register lib/features/tournament lib/l10n` không thêm lỗi so với `origin/main`; `flutter test --no-pub` cho mọi test của change này và các test cũ cùng thư mục đã nêu → exit 0; `openspec validate moc-dupr-noi-dung --strict` pass; ast-grep kiểm không còn chỗ dựng `TournamentDivisionOption` bị vỡ; `app-run.py status` không có `errors` thuộc nhánh này.
  - Files: không sửa file
  - Giao/Nhận: không
  - Chủ file chung: không
  - Phụ thuộc: sau 3.1, 4.1, 5.1
