## Vì sao

Backend (`origin/main` 6f23c46) đã tự ghép ngẫu nhiên trong đúng nội dung khi tạo sơ đồ Lite (`autoPairLiteDivision`) và trả `autoPaired`/`unpairedNames`. App vẫn làm việc cũ ở hai chỗ:

1. Notifier `createBracket` gọi `POST /tournaments/lite/:id/pairs/generate` (RANDOM, không `divisionId`) trước khi tạo sơ đồ, và `catch` nuốt mọi lỗi. Người dùng không biết ghép thất bại.
2. Ghép ngẫu nhiên không gửi `divisionId`. Giải nhiều nội dung bị Backend trả 400 "Vui lòng chọn nội dung để ghép đôi.", nhưng màn hiện `e.toString()` của Dio thay vì thông điệp đó. Notifier `_liteDivisionId` lấy `divisions.first`, tức đoán nội dung.

## Thay đổi

- Ghép ngẫu nhiên (màn ghép cặp và notifier) gửi `divisionId` khi giải có đúng một nội dung. Giải nhiều nội dung mà màn không có nội dung đang chọn thì không gửi `divisionId` và hiện nguyên văn `message` 400 của Backend.
- Hiện cặp vừa ghép theo `paired[].memberNames` và người lẻ theo `unpairedNames` (fallback: `unpairedParticipantIds` đổi qua map id→tên).
- Notifier `createBracket`: bỏ khối tự ghép RANDOM phía client và `catch` nuốt lỗi; hiện `autoPaired`/`unpairedNames` từ response tạo sơ đồ.
- Lỗi 400/401/403/… từ Backend được hiện nguyên văn `message` của body; không có `message` thì dùng thông điệp dự phòng như cũ.
- Thêm test unit và widget cho: gửi `divisionId`, không gọi `pairs/generate` trước khi tạo sơ đồ, lỗi 400 hiện ra người dùng.

## Ngoài phạm vi

- Không đổi Backend và Web.
- Không đổi `_liteDivisionId` dùng cho đọc sơ đồ, reset và danh sách trận (vẫn lấy `divisions.first`). Đây là chỗ đoán nội dung còn lại, cần quyết định sản phẩm riêng.
- Không thêm bộ chọn nội dung vào màn quản lý Lite hay màn ghép cặp.
- Không thêm chuỗi hiển thị mới: dùng khoá `lite_autoPairSuccess`, `lite_autoPairSuccessOdd`, `lite_bracketCreated`, `lite_pairGenerateError` đã có trong `lib/l10n/app_vi.arb` và `app_en.arb`.

## Repo khác bị ảnh hưởng

- Backend (chỉ đọc hợp đồng, không đổi):
  - `POST /tournaments/lite/:id/pairs/generate`, body `{strategy, divisionId?}`. Response có `paired[]` (mỗi phần tử có `memberNames`), `unpairedParticipantIds`, `unpairedNames`. Giải nhiều nội dung thiếu `divisionId` trả 400 "Vui lòng chọn nội dung để ghép đôi.".
  - `POST /tournaments/lite/:id/bracket`, body `{divisionId?, ...}`. Response có `autoPaired[]` và `unpairedNames[]`. Giải nhiều nội dung thiếu `divisionId` trả 400 "Vui lòng chọn nội dung để tạo sơ đồ.".
- Ghi chú: Backend trả khoá `paired`, không phải `pairs`. Đã đối chiếu `tournament-lite.repository.ts` (`generateLitePairsTx`) và `tournaments-lite-pairing.spec.ts`.
