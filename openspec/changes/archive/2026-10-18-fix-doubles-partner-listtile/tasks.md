# Tasks

## 1. Sửa

- [x] 1.1 `lib/features/register/screens/doubles_registration_screen.dart`: bọc `ListView.separated` của danh sách tìm đồng đội trong `Material(type: MaterialType.transparency)` đặt bên trong `Container` có nền, kèm chú thích. Giữ nguyên `Container`, viền, bo góc, `maxHeight`. Xong khi: có commit. Bằng chứng: commit `e23d0387` (cùng commit với `fix-register-consent-gate-source`).

## 2. Kiểm chứng

- [x] 2.1 Run `app-e2e` đủ bộ trên head chứa sửa: ca "VĐV đăng ký đôi tự ghép, mời đồng đội bằng email và thấy trạng thái chờ đồng đội" (`integration_test/tournament_player_flow_test.dart:189`) qua, log không còn `ListTile background color`. Xong khi: có run id. Bằng chứng: run `39134290417` (app `d77ac38b`, chứa `e23d0387`): `+6: All tests passed!`, 0 dòng `ListTile background`, 0 `EXCEPTION CAUGHT`. Mốc đỏ: run `39122493011`.
- [x] 2.2 Run `app` (analyze + widget test) cùng head. Xong khi: có run id, job success. Bằng chứng: run `39134286473` (`d77ac38b`): success, 1132 test pass, 2 skip.
- [x] 2.3 `npx openspec validate fix-doubles-partner-listtile --strict` exit 0. Xong khi: có exit code. Bằng chứng: ghi ở commit thêm file này.
