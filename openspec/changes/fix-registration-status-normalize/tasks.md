# Tasks

## 1. Chẩn đoán

- [x] 1.1 Xác định đường đi gây thanh đăng ký biến mất: `status: mappedStatus` (`lib/domain/entities/tournament.dart:380`) → `isTournamentRegistration(tournament.status)` (`lib/core/utils/status_helpers.dart:70`) → `normalizeTournamentStatus('registration')` đi vào `_unknownStatus` (`status_helpers.dart:22-23, 41`) và trả `raw_registration`. Bằng chứng: log run `39113523342` dòng ~3640–3670 có `GET /tournaments/:id` 200 và các API chi tiết 200, nên dữ liệu đã tới; thanh đăng ký (`tournament_intro_screen.dart:294-334`) không được dựng. Mức: [INFERENCE] mạnh, chờ run xanh để xác nhận.

## 2. Sửa

- [x] 2.1 `lib/core/utils/status_helpers.dart` (`normalizeTournamentStatus`): trả nguyên mã nội bộ đã chuẩn hoá trước khi viết hoa; chuỗi thô vẫn qua nhánh cũ. Xong khi: unit test xanh. Bằng chứng: `dart analyze lib/core/utils/status_helpers.dart test/core/utils/status_helpers_registration_test.dart` → `No issues found!` (EXIT 0); `flutter test --no-pub --no-test-assets test/core/utils/status_helpers_registration_test.dart` → `All tests passed!` 5/5 (EXIT 0).
- [x] 2.2 Thêm test `re-reading a normalized internal code keeps its meaning` vào `test/core/utils/status_helpers_registration_test.dart`. Xong khi: nằm trong 5/5 ở 2.1.

## 3. Kiểm trên cloud

- [ ] 3.1 Run `app-e2e` trên head chứa sửa: ca đơn và ca đôi trong `tournament_player_flow_test.dart` thấy nút "Đăng ký" trên thanh đăng ký. Xong khi: có run id và log cho thấy hai ca đó qua bước tìm nút.
- [ ] 3.2 Run `app` (analyze + toàn bộ widget test) trên cùng head: các test fixture dùng `'status': 'registration'` vẫn xanh. Xong khi: có run id, job "Test Flutter App" success.
- [ ] 3.3 `npx openspec validate fix-registration-status-normalize --strict` exit 0. Xong khi: có exit code.
