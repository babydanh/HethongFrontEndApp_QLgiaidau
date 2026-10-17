## Why

Màn ghép cặp Lite gửi `pairs/generate` và `bracket` thiếu `divisionId` khi giải có từ hai nội dung. Backend trả 400 ("Vui lòng chọn nội dung để ghép đôi." hoặc "Vui lòng chọn nội dung để tạo sơ đồ."). Danh sách chờ còn hiện VĐV của mọi nội dung, nên BTC không biết đang ghép cho nội dung nào. Màn quản lý đã có hộp chọn nội dung (`fix-app-lite-division-select`), màn ghép cặp chưa dùng.

## What Changes

- Màn ghép cặp Lite dùng chung hộp chọn nội dung `showLiteDivisionPicker` với màn quản lý. Giải nhiều nội dung chưa chọn thì danh sách chờ trống và hiện nút chọn nội dung.
- Danh sách chờ và danh sách đơn chỉ hiện VĐV của nội dung đang chọn khi giải có nhiều nội dung.
- Ghép ngẫu nhiên và tạo sơ đồ hỏi BTC chọn nội dung trước khi gọi API, rồi gửi `divisionId` của nội dung đã chọn. BTC huỷ thì không gọi API.
- Ghép tay không gửi `divisionId` vì Backend không nhận trường đó. Ràng buộc cùng nội dung dựa vào danh sách đã lọc và Backend từ chối ghép khác nội dung.
- `LiteParticipant` đọc `tournamentDivisionId`. Helper `usableTournamentDivisions` dùng chung cho cả hai màn.
- Giải một nội dung không đổi.

## Ngoài phạm vi

- Không đổi Backend và Web.
- Danh sách đã ghép (`allPaired`) không lọc theo nội dung.
- Lựa chọn nội dung trên màn ghép cặp không lưu bền; tải lại màn thì chọn lại.
- Không thêm chuỗi l10n mới: dùng `registerSelectDivision`, `commonCancel`, `lite_confirmButton`.
