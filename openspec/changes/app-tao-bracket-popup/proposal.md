## Why
Trong App, nút "Tạo bracket" của nội dung Round Robin / Vòng bảng tạo thẳng, không cho chỉnh số bảng hay cách xếp. Web có bước cài đặt này. BTC cần chỉnh rồi mới tạo, và kéo thả sắp xếp sau khi tạo trên sơ đồ.

## What Changes
- Bấm "Tạo bracket" ở Round Robin / Vòng bảng mở popup cài đặt: số bảng, đội mỗi bảng, đội đi tiếp, số lượt, playoff, xếp theo (ELO / ngẫu nhiên), kèm gợi ý theo số đội đăng ký.
- Xác nhận: lưu cấu hình (`updateDivisionConfig`) rồi tạo bracket. Không có bước xếp bảng tay.
- Thể thức khác (loại trực tiếp, Swiss) giữ nguyên: tạo thẳng.

## Impact
- App: `bracket_management_bar.dart`, `bracket_view_screen.dart`, widget mới `bracket_create_sheet.dart`, hàm thuần `bracket_quick_suggestion.dart`, l10n vi/en.
- Backend/Web: không đổi.
