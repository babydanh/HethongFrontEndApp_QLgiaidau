## Chỗ đặt UI
Tái dùng nút/menu "Cấu hình từng vòng" sẵn có của thẻ hạng mục và `StageRoundConfigSheet` (thêm cờ `draft`), thay vì nhét vào `DivisionEditorSheet` (đã 1800+ dòng, và bị khóa kết cấu khi có sơ đồ). Ít đụng code nhất, không có form thứ hai.

## Lưu
Chế độ draft dùng một stage ảo mang `roundConfig` của hạng mục, nên `_save` dùng chung đường ghép khóa với stage thật; chỉ khác đích ghi: `updateDivisionConfig(..., {isConfigOverride: true, roundConfig})` (cùng payload với `bracket_management_bar`). Knockout → `rounds['<n>']` (n từ 1), Lượt → `rounds['leg_N']`, vòng 0 → khóa luật ghi lên gốc; mọi khóa khác giữ nguyên.
