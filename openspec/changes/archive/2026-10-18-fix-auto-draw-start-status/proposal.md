# Proposal

## Why

Ca BTC `integration_test/organizer_flow_test.dart` bấm "Lưu & Bắt đầu giải": nhánh đã được tạo trên Backend nhưng app vẫn báo lỗi. Run `39129778085` (head app `606a9506`, log `e2e-39129778085/job.log`):

- `13:16:56.948 POST /tournaments/:id/generate-bracket status=201`
- `13:16:57.018 start PATCH /tournaments/:id request_bytes=24`
- `13:16:57.037 error PATCH /tournaments/:id status=400 type=badResponse`

Nguyên nhân (đọc code; chi tiết ở `openspec/changes/app-e2e-integration/findings.md` F16 và B3):

- `_saveBracket` trong `auto_draw_screen.dart` gửi `{'status': 'in_progress'}` (chữ thường). DTO `update-tournament.dto.ts:12-17` chỉ nhận chữ hoa, nên 400.
- Đổi sang chữ hoa vẫn không đủ: `tournament-lifecycle.service.ts:669-673` từ chối `status` với mọi vai trò không phải ADMIN (403), và `generateBracket` (`tournament-bracket.service.ts:362`) không tự đổi trạng thái. Không có đường API hợp lệ để BTC đưa giải sang `IN_PROGRESS` (B3, chỉ ghi lại).
- Sau khi bỏ PATCH, lỗi tầng kế tiếp lộ ra: `context.pop()` ném `GoError('There is nothing to pop')` khi màn được mở bằng `go()` (go_router 17.3.0, `delegate.dart:104-105`). Lỗi nằm trong `try` nên vẫn báo "Lỗi:" dù nhánh đã lưu.

Mức chắc chắn: đường đi mã đã đọc đầy đủ và khớp log. Mã 403 của Backend đọc từ source, chưa quan sát trực tiếp qua HTTP vì log không có body lỗi.

## What Changes

- `lib/features/bracket/screens/auto_draw_screen.dart`:
  - Bỏ hẳn `repo.update(... status ...)` khỏi `_saveBracket`, có chú thích lý do. Tạo nhánh vẫn qua `generateBracket`. Không đổi giá trị status (vẫn bị 403 với BTC).
  - Thêm `_leaveScreen()` dùng chung với nút back: `canPop()` thì pop, không thì `go(managementRouteBase)`. Thay `context.pop()` sau lưu thành công.
- `test/features/auto_draw_save_bracket_test.dart` (mới): hai ca widget, mở bằng push và mở bằng go. Kiểm `generateBracket` đúng một lần, không gọi `update`/`updateStatus`, có snackbar thành công, không có "Lỗi:".
- `integration_test/organizer_flow_test.dart`: sau bước lưu, khẳng định có thông báo thành công và không có "Lỗi: ".
- `openspec/changes/app-e2e-integration/findings.md`: ghi F16 (đã sửa), F17 (chưa sửa: đặt lại bốc thăm gửi `registration` chữ thường), B3 (Backend, chỉ ghi).

### Out of scope (KHÔNG làm)

- Không sửa Backend (B3).
- Không sửa `reset_tournament_draw_use_case.dart` (F17): đổi trạng thái sau khi đặt lại bốc thăm là quyết định nghiệp vụ.
- Không đổi `.github/workflows/test-runner.yml`.
- Không đổi status thành chữ hoa `IN_PROGRESS`: vẫn bị 403 với BTC, nên bỏ hẳn.
