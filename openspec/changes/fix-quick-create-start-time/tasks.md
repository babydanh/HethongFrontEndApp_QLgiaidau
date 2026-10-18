# Tasks

## 1. Chẩn đoán

- [x] 1.1 Xác định 400 của ca BTC nằm ở payload `POST /tournaments/lite`: log run `39115189414` dòng 3844–3845 (`request_bytes=924`, `status=400`). Đối chiếu khóa payload với `CreateLiteTournamentDto` (`forbidNonWhitelisted: true`, `src/main.ts:33-39`): mọi khóa đều khai báo, nên 400 không đến từ trường thừa.
- [x] 1.2 Xác định cơ chế: `tournament-lite.service.ts:569-610` (nhánh có `startTime` lấy phần ngày UTC của `startDate` và coi giờ là UTC+7), so với `:676-688` và `:857-872`. Mức: [INFERENCE] mạnh; thông điệp 400 thật chưa đọc được (body không có trong log).
- [x] 1.3 Phạm vi cùng lỗi: đã đọc `create_public_quick_tournament_screen.dart:630-632`, `create_club_tournament_screen.dart:192-195`, `create_club_screen.dart:168-170`. Ba màn này đều gửi `startDate` UTC cùng `startTime`. Các chỗ `startTime` còn lại (`create_club_screen.dart:47, 123, 976, 1091, 1193`) là slot lịch CLB, không gửi `POST /tournaments/lite` kèm `startDate`.

## 2. Sửa

- [x] 2.1 Bỏ `startTime` khỏi payload ở `create_public_quick_tournament_screen.dart` (có chú thích). Xong khi: `dart analyze` file sạch.
- [x] 2.2 Bỏ `startTime` ở nhánh `_startDate != null` của `create_club_tournament_screen.dart` (có chú thích), giữ nhánh định kỳ. Xong khi: `dart analyze` file sạch.
- [x] 2.3 Bỏ `startTime` khỏi mẫu lịch định kỳ "Giao hữu" trong `create_club_screen.dart`, giữ `recurringTimeOfDay`. Xong khi: `dart analyze` file sạch.

## 3. Kiểm trên cloud

- [x] 3.1 Run `app-e2e` trên head chứa sửa (run `39134290417`, head `d77ac38b`, chứa `d7d7c4f8`): ca BTC qua bước "nút thêm VĐV". Bằng chứng: log có `POST /tournaments/lite status=201` (dòng 7883), không có `status=400`; `+6: All tests passed!` (dòng 7969). Xong khi: có run id và log.
- [x] 3.2 Run `app` (analyze + toàn bộ widget test) trên cùng head `d77ac38b`: run `39134286473`, job "Test Flutter App" success, `1132 tests passed, 2 skipped`. Xong khi: có run id, job success.
- [x] 3.3 `npx openspec validate fix-quick-create-start-time --strict` exit 0. Xong khi: có exit code. Bằng chứng: exit code 0.
