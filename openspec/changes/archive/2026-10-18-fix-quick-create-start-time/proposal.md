# Proposal

## Why

Ca BTC `integration_test/organizer_flow_test.dart` tạo giải nhanh và bị HTTP 400 khi gửi `POST /tournaments/lite` (run `39115189414`, ref `9d84bed7`, log `%TEMP%/cloud-test-39115189414-117639458931.log` dòng 3844–3845: `POST /tournaments/lite request_bytes=924`, rồi `status=400`). Test chờ "nút thêm VĐV" trên trang quản lý và hết 60 giây.

Nguyên nhân nằm ở payload của app. App gửi cùng lúc:

- `startDate` = mốc UTC đầy đủ (`toUtc().toIso8601String()`), ví dụ `2026-10-18T17:00:00.000Z` cho 00:00 ngày 19/10 giờ UTC+7;
- `startTime` = giờ địa phương `HH:mm`.

Backend (`tournament-lite.service.ts:569-610`) khi có `startTime` không dùng mốc ISO. Nó lấy phần ngày UTC của `startDate`, ghép với `startTime` và coi kết quả là giờ UTC+7 (`Date.UTC(..., hh - 7, mm)`). Hai nguồn này lệch nhau nên giờ bắt đầu bị dịch:

- Máy ở UTC (như emulator CI): giờ bắt đầu thành `17:00Z` hôm trước, trước mốc hạn đăng ký `23:59Z` mà app gửi. Backend trả 400 `Thời gian đóng đăng ký phải trước giờ bắt đầu giải.` (`:676-684`, và `:869` cho từng nội dung).
- Máy ở UTC+7, giờ bắt đầu từ 00:00 đến 06:59: phần ngày UTC lùi một ngày, giờ bắt đầu thành quá khứ. Backend trả 400 `Ngày bắt đầu giải phải ở tương lai khi tạo giải nhanh.` (`:685-688`).

Mức chắc chắn: đường đi mã đã đọc đầy đủ và khớp với 400 của run. Body lỗi không có trong log nên chưa đọc được thông điệp 400 thật; xác nhận bằng run xanh của ca BTC. Múi giờ thiết bị CI chưa đo được; cả hai kịch bản đều dẫn tới 400 đã nêu.

## What Changes

- `lib/features/tournament/screens/create_public_quick_tournament_screen.dart`: bỏ trường `startTime` khỏi payload `POST /tournaments/lite`. Giờ bắt đầu đã nằm đầy đủ trong `startDate` (mốc UTC). Backend nhận nhánh ISO có múi giờ (`tournament-lite.service.ts:574-579`) và không ghép giờ nữa. Có chú thích tại chỗ bỏ trường.
- `lib/features/community/screens/create_club_tournament_screen.dart`: cùng lỗi ở nhánh có `startDate` (`_startDate != null`). Bỏ `startTime` ở nhánh đó. Nhánh định kỳ (không có `startDate`, `else if (_isRecurring)`) giữ nguyên vì không có ngày để ghép.
- `lib/features/community/screens/create_club_screen.dart`: mẫu lịch định kỳ "Giao hữu" gửi `startDate` UTC cùng `startTime` (`:168-170`). Bỏ `startTime`; giữ `recurringTimeOfDay` (backend dùng cho lịch lặp). Khối này bọc `try/catch` nên lỗi 400 trước đây bị nuốt im lặng (ghi vào findings).

### Out of scope (KHÔNG làm)

- Không sửa Backend. Lỗi ghép `startTime` với phần ngày UTC và giả định UTC+7 ở `tournament-lite.service.ts:588-610` được ghi vào `findings.md` (F9) để báo, không sửa.
- Không đổi lịch mặc định của bộ chọn thời gian, không đổi chữ hiển thị.
- Không đổi nhánh định kỳ không có `startDate`.
- Không đổi khối `try/catch` của màn CLB (phạm vi khác; ghi lại để xử lý riêng).
