## Why

Màn quản lý Lite lấy `divisions.first` khi tạo sơ đồ, reset, ghép ngẫu nhiên và thêm/xoá VĐV ảo. Giải có từ hai nội dung trở lên thì các thao tác này ghi vào nội dung đầu tiên dù BTC không chọn nó, nên sơ đồ và VĐV ảo có thể nằm sai nội dung.

## What Changes

- Màn quản lý Lite: khi giải có từ hai nội dung dùng được và chưa có nội dung đang chọn, hỏi BTC chọn nội dung trước khi tạo sơ đồ, ghép ngẫu nhiên, reset, thêm hoặc xoá VĐV ảo. BTC huỷ thì không gọi API.
- Notifier lưu nội dung đang chọn (`selectedDivisionId`). Thao tác ghi dùng nội dung đó, hoặc nội dung duy nhất khi giải chỉ có một nội dung. Giải nhiều nội dung chưa chọn thì ném lỗi trước khi gửi request.
- Đọc và hiển thị sơ đồ dùng nội dung đang chọn; chưa chọn thì dùng nội dung đầu tiên (chỉ đọc).
- Màn ghép cặp Lite giữ nguyên: vẫn không gửi `divisionId` khi giải có nhiều nội dung.
- Thêm test notifier: nhiều nội dung chưa chọn không gửi `divisions.first`; đã chọn thì gửi đúng id; một nội dung giữ nguyên.

## Ngoài phạm vi

- Không đổi Backend và Web.
- `updateMaxParticipants` vẫn PATCH cấu hình nội dung đầu tiên và lỗi vẫn bị nuốt. Cần quyết định riêng.
- Format control vẫn đọc `divisions.first` cho loại thi đấu.
- Chưa có widget test cho bộ chọn nội dung; kiểm bằng analyze và test notifier.
- Không thêm chuỗi mới: dùng `registerSelectDivision`, `commonCancel`, `lite_confirmButton` đã có.
