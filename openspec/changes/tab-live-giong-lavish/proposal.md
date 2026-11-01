## Why
Bảng trận ở tab "Đang diễn ra" đã đúng cấu trúc Web nhưng nhìn khác mockup Lavish đã duyệt (phương án A): chip không có số đếm, đầu hộp là chữ trơn, avatar xám, không chấm đỏ/dòng "vs", điểm màu đen, trận chưa có đối thủ hiện "Chưa xác định". Cần chép đúng thông số CSS của mockup và màu avatar chuẩn Web.

## What Changes
- Chip lọc 11.5px/700 có số đếm (Đang đấu/Sắp tới/Đã xong); chip chọn nền `#1d4ed8`.
- Hàng công cụ: ô tìm viền bo 8 + nút "Tới vòng" luôn hiện cạnh ô tìm.
- Đầu mỗi hộp: nền xanh nhạt (đỏ nhạt cho "Đang đấu"), pill tên vòng + chip "N trận".
- Hàng trận: lưới mã 44 · hai bên · điểm 56; chấm đỏ cạnh mã trận live; dòng "vs" giữa hai bên; điểm live màu đỏ, điểm bên thua/trống màu nhạt; dòng phụ gồm giờ/sân và huy hiệu (sân hoặc tên vòng).
- Avatar tròn 18px màu theo tên (bảng màu và chữ cái đầu+cuối như Web `avatar-fallback.ts`), tích xanh bên thắng.
- Bên chưa có đối thủ: "Chờ đội thắng V…" khi suy ra được trận nguồn, ngược lại "Chưa xác định".

## Out of scope
Tab "Kết quả", thanh hạng mục "đổi ▾" cho giải một hạng mục, phía quản lý (mục 4 mockup), dữ liệu API.

## Capabilities
### Modified Capabilities
- `live-results-board`: giao diện bảng trận khớp mockup Lavish.

## Impact
`lib/core/participants/participant_display.dart`, `lib/features/tournament/widgets/results_match_board.dart`, `results_match_row.dart`, l10n vi/en, test tương ứng.
