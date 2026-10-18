# Tasks

## 1. Chẩn đoán

- [x] 1.1 Xác định PATCH 400 ngay sau generate-bracket 201 trong log run `39129778085` (`e2e-39129778085/job.log`, `13:16:57.037`). Xong khi: có dòng log và thời điểm.
- [x] 1.2 Đối chiếu với code: DTO `update-tournament.dto.ts:12-17` (chỉ chữ hoa), `tournament-lifecycle.service.ts:669-673` (403 cho non-ADMIN), `tournament-bracket.service.ts:362` (generate không ghi status). Xong khi: có kết luận B3 trong findings.
- [x] 1.3 Tìm chỗ khác gửi status chữ thường. `reset_tournament_draw_use_case.dart` gửi `registration` (F17, chưa sửa). Các chỗ khác đã đọc không gửi status giải. Xong khi: có danh sách trong findings.
- [x] 1.4 Xác định lỗi tầng kế tiếp: `context.pop()` ném `GoError` khi không có route trước (go_router 17.3.0, `delegate.dart:104-105`). Xong khi: đã đối chiếu source go_router.

## 2. Sửa và test

- [x] 2.1 Bỏ `repo.update(... status ...)` khỏi `_saveBracket`, có chú thích lý do. Xong khi: `dart analyze` file sạch.
- [x] 2.2 Thêm `_leaveScreen()` dùng chung với nút back, thay `context.pop()` sau lưu. Xong khi: `dart analyze` file sạch.
- [x] 2.3 Thêm `test/features/auto_draw_save_bracket_test.dart` (ca push và ca go). Xong khi: file viết xong và `dart analyze` sạch. Chạy trên cloud, không chạy cục bộ.
- [x] 2.4 Organizer test: khẳng định có thông báo thành công và không có "Lỗi: " sau bước lưu. Xong khi: `dart analyze` file sạch.
- [x] 2.5 Ghi F16, F17, B3 trong `findings.md`. Xong khi: findings có đủ bằng chứng.

## 3. Kiểm trên cloud

- [ ] 3.1 Run `app-e2e` đầy đủ trên head chứa sửa: `POST /tournaments/:id/generate-bracket` 201, không còn `PATCH /tournaments/:id status=400`, có snackbar thành công, ca BTC qua bước 4. Xong khi: có run id và dòng log.
- [ ] 3.2 Run `app` (analyze và toàn bộ widget test, gồm `auto_draw_save_bracket_test`) trên cùng head, job success. Xong khi: có run id.
- [ ] 3.3 `npx openspec validate fix-auto-draw-start-status --strict` exit 0. Xong khi: có exit code.
