# Tasks

## 1. Chẩn đoán

- [x] 1.1 Đọc log run `39122493011` (`flutter-test.log` dòng 92–93): `POST /tournaments/:id/register` trả 400 ở ca đơn, lúc người test chưa tick đồng ý trên giải có xếp hạng.
- [x] 1.2 Đọc `build` (`tournament_register_screen.dart` dòng ~871): form dùng `registerTournamentProvider((id, invite))`. `_submit` (dòng ~559–562) dùng `tournamentProvider(id).asData?.value`: khác provider.
- [x] 1.3 Riverpod 3.3.2: `AsyncValue.asData` trả `null` khi `AsyncLoading` (`lib/src/core/async_value.dart:132-134`), `value` giữ dữ liệu cũ (dòng 551).
- [x] 1.4 Backend (chỉ đọc): `tournament-registration.repository.ts` yêu cầu `rankingConsent === true` khi giải có xếp hạng.

## 2. Sửa

- [x] 2.1 `tournament_register_screen.dart`, `_submit`: đọc giải bằng `registerTournamentProvider((id, invite)).value`, cùng key với `build`.
- [x] 2.2 `doubles_registration_screen.dart`, `_submit`: đổi `.asData?.value` thành `.value` trên cùng provider. Xong khi: `dart analyze` hai file chỉ còn cảnh báo có sẵn ở dòng ~540 (không do thay đổi này).

## 3. Kiểm trên cloud

- [x] 3.1 Run `app-e2e` trên head chứa sửa (run `39134290417`, head `d77ac38b`, chứa `e23d0387`): ca đơn và đôi có tick đồng ý thì gửi được đăng ký; không còn `POST /register` 400 do thiếu đồng ý. Bằng chứng: hai `POST /tournaments/:id/register status=201` (dòng 7701 với request_bytes=99, dòng 7858 với request_bytes=203), không có dòng register 400; `+6: All tests passed!` (dòng 7969). Xong khi: có run id và log.
- [x] 3.2 Run `app` trên cùng head `d77ac38b`: run `39134286473`, job success, `1132 tests passed, 2 skipped`. Xong khi: có run id.
- [x] 3.3 `npx openspec validate fix-register-consent-gate-source --strict` exit 0. Xong khi: có exit code. Bằng chứng: exit code 0.
