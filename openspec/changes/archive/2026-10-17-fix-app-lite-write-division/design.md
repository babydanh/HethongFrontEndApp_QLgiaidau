## Thiết kế

- **Một nguồn cho GHI**: `_writeDivision()` trả nội dung đang chọn, hoặc nội dung duy nhất (`usableTournamentDivisions` đúng một phần tử), hoặc null khi giải không có nội dung nào (giữ như cũ). Giải nhiều nội dung chưa chọn ném `StateError(registerSelectDivision)`. `_writeDivisionId()` = `_writeDivision()?.id`.
- **Thứ tự trong notifier**: `_writeDivision()` / `_writeDivisionId()` chạy trước mọi cờ trạng thái (`formatSaving`, `detailsSaveStatus`, `generating`) và trước mọi request, nên lỗi không làm cờ bị kẹt.
- **updateMatchType**: lấy nội dung ghi bằng `_writeDivision()` thay cho `divisions.first`. Khoá vòng đời và so sánh thể thức đều dùng nội dung đó. PATCH `/divisions/<id>/config` của đúng nội dung.
- **updateMaxParticipants**: `divisionId = _writeDivisionId()` trước khi đặt `saving`. PATCH tổng giữ nguyên; PATCH cấu hình nội dung dùng id này. Không còn `_readDivisionId` trong đường ghi.
- **generatePairs**: `divisionId ?? _writeDivisionId()`. Thay cho `selectedDivision ?? sole` để một quy tắc duy nhất. Ca test cũ "nhiều nội dung: gửi thiếu rồi nhận 400" đổi thành "ném lỗi trước request".
- **Màn quản lý, thể thức**: `_buildFormatSettingCard` đọc `state.displayDivision` cho định dạng hiện tại. Nút lưu gọi `_ensureDivisionChosen(notifier)` trước khi mở hộp xác nhận.
- **Màn quản lý, sức chứa**: callback debounce gọi `_ensureDivisionChosen(notifier)` trước `updateMaxParticipants`. Huỷ thì không gọi API nào.
- **Đọc**: `displayDivision`, `_readDivisionId` ở `init`/`refresh`/`_fetchMatches` vẫn là đường đọc và không đổi.
