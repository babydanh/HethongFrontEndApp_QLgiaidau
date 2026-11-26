## Why

Tạo camera và sân trên App còn vướng: ô tên camera trống (Web cũng sẽ điền sẵn "Cam N"), số sân ban đầu phải gõ tay vào ô trống, tab Camera ẩn nút "+" khi chưa có sân nên người dùng không biết vì sao, và danh sách camera nằm dưới danh sách sân dài. Nhãn sân chỉ có số ("1") khó hiểu.

## What Changes

- Tạo camera mới: tên điền sẵn "Cam N" (N = số camera hiện có + 1), vẫn sửa được. Sửa camera giữ nguyên.
- Số sân ban đầu khi tạo cơ sở: stepper − [1] + (mặc định 1, bấm số để gõ, kẹp 1..50).
- Tab Camera: nút "+" luôn hiện (trừ chế độ chỉ xem); chưa có sân thì bấm báo "Thêm sân trước khi tạo camera", không mở form; đang tải thì vô hiệu.
- Tab Camera: khối camera lên ngay sau tiêu đề, sân/trận xuống dưới.
- Nhãn sân hiển thị "Sân <số>" khi tên chỉ là số (chỉ hiển thị, `courtName` gửi API giữ nguyên).

## Impact

- Chỉ App Flutter (tournament camera tab, venue dialog, l10n). Không đổi API, không đổi dữ liệu gốc.
