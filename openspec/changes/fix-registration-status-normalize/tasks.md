# Tasks

## 1. Chẩn đoán

- [x] 1.1 Xác định đường đi gây thanh đăng ký biến mất: `status: mappedStatus` (`lib/domain/entities/tournament.dart:380`) → `isTournamentRegistration(tournament.status)` (`lib/core/utils/status_helpers.dart:70`) → `normalizeTournamentStatus('registration')` đi vào `_unknownStatus` (`status_helpers.dart:22-23, 41`) và trả `raw_registration`. Bằng chứng: log run `39113523342` dòng ~3640–3670 có `GET /tournaments/:id` 200 và các API chi tiết 200, nên dữ liệu đã tới; thanh đăng ký (`tournament_intro_screen.dart:294-334`) không được dựng. Mức: [INFERENCE] mạnh, chờ run xanh để xác nhận.

## 2. Sửa

- [x] 2.1 `lib/core/utils/status_helpers.dart` (`normalizeTournamentStatus`): trả nguyên mã nội bộ đã chuẩn hoá trước khi viết hoa; chuỗi thô vẫn qua nhánh cũ. Xong khi: unit test xanh. Bằng chứng: `dart analyze lib/core/utils/status_helpers.dart test/core/utils/status_helpers_registration_test.dart` → `No issues found!` (EXIT 0); `flutter test --no-pub --no-test-assets test/core/utils/status_helpers_registration_test.dart` → `All tests passed!` 5/5 (EXIT 0).
- [x] 2.2 Thêm test `re-reading a normalized internal code keeps its meaning` vào `test/core/utils/status_helpers_registration_test.dart`. Xong khi: nằm trong 5/5 ở 2.1.

## 3. Kiểm trên cloud

- [x] 3.1 Run `app-e2e` trên head chứa sửa (run `39134290417`, head `d77ac38b`, chứa `f2aa0362`): ca đơn và ca đôi thấy nút "Đăng ký" trên thanh đăng ký. Bằng chứng: hai ca đều tới `POST /tournaments/:id/register status=201` (dòng 7701 và 7858), tức đã tìm và bấm được nút; `+6: All tests passed!` (dòng 7969). Xong khi: có run id và log cho thấy hai ca đó qua bước tìm nút.
- [x] 3.2 Run `app` (analyze + toàn bộ widget test) trên cùng head `d77ac38b`: run `39134286473`, job "Test Flutter App" success, `1132 tests passed, 2 skipped`; các test fixture dùng `'status': 'registration'` vẫn xanh. Xong khi: có run id, job "Test Flutter App" success.
- [x] 3.3 `npx openspec validate fix-registration-status-normalize --strict` exit 0. Xong khi: có exit code. Bằng chứng: exit code 0.
