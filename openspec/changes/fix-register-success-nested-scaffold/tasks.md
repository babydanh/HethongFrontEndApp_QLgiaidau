# Tasks

## 1. Chẩn đoán

- [x] 1.1 Đọc `flutter-test.log` run `39123946327` (dòng 98–183): `RenderCustomMultiChildLayoutBox was given an infinite size`, widget gây lỗi `Scaffold` tại `tournament_register_screen.dart:1272`.
- [x] 1.2 Xác nhận cây widget: `build` (dòng ~886) `Scaffold` → `SingleChildScrollView` (dòng ~889) → `_buildSuccess` (dòng ~939, ~965) trả `Scaffold` lồng.
- [x] 1.3 Đối chiếu màn đôi: `_buildSuccess(colors)` ở `doubles_registration_screen.dart:763` trả trước Scaffold ngoài cùng, không lồng.

## 2. Sửa

- [x] 2.1 `tournament_register_screen.dart`, `_buildSuccess`: trả `Center(...)`, bỏ Scaffold lồng; chú thích lý do.
- [x] 2.2 Kiểm cú pháp: cặp ngoặc đóng `Center` và `;` ở cuối biểu thức khớp. Xong khi: `dart analyze` file không có lỗi mới (cảnh báo có sẵn dòng ~540 không đổi).

## 3. Kiểm trên cloud

- [x] 3.1 Run `app-e2e` có ca đơn (run `39134290417`, head `d77ac38b`, chứa `1477bdbe`): sau khi gửi đăng ký thành công, không còn lỗi `infinite size` trong log; ca đi tiếp, có `GET /tournaments/:id/my-registration` 200 (dòng 7860). Bằng chứng: không có dòng `infinite size`; `POST /tournaments/:id/register status=201` (dòng 7701, 7858); `+6: All tests passed!` (dòng 7969). Xong khi: có run id và log.
- [x] 3.2 Run `app` trên cùng head `d77ac38b`: run `39134286473`, job success, `1132 tests passed, 2 skipped`. Xong khi: có run id.
- [x] 3.3 `npx openspec validate fix-register-success-nested-scaffold --strict` exit 0. Xong khi: có exit code. Bằng chứng: exit code 0.
