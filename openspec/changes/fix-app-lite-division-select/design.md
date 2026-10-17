## Thiết kế

- **Trạng thái chọn**: `LiteManagementState.selectedDivisionId` (có trong constructor và `copyWith`). `selectedDivision` chỉ trả nội dung còn dùng được (không `CANCELLED`, id lưu được trên server), nếu không thì null. `displayDivision` trả nội dung đang chọn, chưa chọn thì nội dung đầu tiên, và chỉ dùng để đọc.
- **Ghi có điều kiện**: `_writeDivisionId()` theo thứ tự: nội dung đang chọn, nội dung duy nhất, giải không có nội dung nào (trả null, giữ như cũ), còn lại ném `StateError`. Không có nhánh nào lấy nội dung đầu tiên khi giải có nhiều nội dung.
- **Thứ tự trong notifier**: `_writeDivisionId()` chạy trước khi đặt `creatingBracket` hoặc `mockLoading`, nên lỗi không làm cờ bị kẹt.
- **Hỏi chọn ở màn**: `_ensureDivisionChosen` chạy đầu các luồng tạo sơ đồ, ghép ngẫu nhiên, reset, thêm và xoá VĐV ảo. Chọn xong thì gọi `selectDivision`, tải lại sơ đồ và trận của nội dung đó. Huỷ thì dừng, không gọi API, không hiện lỗi.
- **Màn ghép cặp**: không đổi. Màn này vẫn không gửi `divisionId` khi có nhiều nội dung và để Backend trả 400.
