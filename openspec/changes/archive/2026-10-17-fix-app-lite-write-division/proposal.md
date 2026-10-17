## Why

Màn quản lý Lite còn ghi cấu hình vào nội dung đầu tiên khi giải có nhiều nội dung và BTC chưa chọn. `updateMatchType` đọc `divisions.first` để PATCH cấu hình, `updateMaxParticipants` PATCH cấu hình theo `_readDivisionId` (nội dung đang xem, mặc định là nội dung đầu). Đổi đơn/đôi và sức chứa vì thế có thể ghi sai nội dung mà BTC không thấy.

## What Changes

- Notifier: `updateMatchType`, `updateMaxParticipants` và `generatePairs` ghi qua `_writeDivision()` / `_writeDivisionId()`. Giải nhiều nội dung chưa chọn ném `StateError` trước khi gửi request. Không còn đường GHI nào đọc `divisions.first` hoặc `_readDivisionId`.
- Màn quản lý: đổi thể thức và sức chứa gọi `_ensureDivisionChosen` trước khi mở hộp xác nhận / trước khi ghi. BTC huỷ hộp chọn thì không gọi API.
- Màn quản lý: hiển thị định dạng đọc `displayDivision` (nội dung đang xem), không đọc `divisions.first`.
- Giải một nội dung giữ nguyên.

## Ngoài phạm vi

- `updateMaxParticipants` vẫn nuốt lỗi khi PATCH cấu hình nội dung (`catch (_) {}`). Đây là vấn đề khác với ghi sai nội dung; giữ nguyên và báo lại.
- `_canonicalMatchType` và `payload.divisions.first` trong notifier chỉ đọc để hiển thị, không ghi.
- Màn tổ chức (organizer ops), sơ đồ (bracket view) và đăng ký giải (tournament intro) chọn nội dung hiển thị có selector hoặc dropdown nhìn thấy; không đổi.
- Không đổi Backend, không thêm chuỗi l10n mới.
