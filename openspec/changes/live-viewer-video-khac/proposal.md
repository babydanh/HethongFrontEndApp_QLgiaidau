## Why

Trên màn xem trực tiếp của App, bảng điểm đè lên chữ "Chưa phát trực tiếp" (góc dưới trái), còn tab "Video khác" là các hộp gradient trống, khi có khi không (chỉ trận đang live mới có điểm/nhãn) nên nhìn lệch và xấu. Web hiển thị danh sách trận theo thẻ có tên hai bên và bộ lọc Đang diễn ra / Sắp diễn ra.

## What Changes

- Bảng điểm đè video của người xem chuyển lên góc trên trái, ngay dưới thanh header (thanh header đè lên đầu video), vẫn nằm trong khung video.
- Tab "Video khác": mỗi trận là một hàng đồng nhất gồm thumbnail vẽ từ logo hai bên + điểm/"VS" + giờ, cạnh đó tên hai bên và "vòng · sân"; thêm bộ lọc Tất cả / Đang diễn ra / Sắp diễn ra.
- Nút nhập điểm giữ nguyên là icon trên header, không thêm nút mới.

## Out of scope

- Không thêm API hay trường thumbnail ở Backend (Backend không có endpoint gợi ý video hay ảnh khung hình trận).
- Không đổi luật chọn trận gợi ý (`pickLiveSuggestions`) và bố cục màn điều khiển của trọng tài.

## Capabilities

### New Capabilities

### Modified Capabilities
- `live-viewer`: vị trí bảng điểm của người xem và danh sách "Video khác".

## Impact

- `lib/features/match/screens/live_score_screen.dart`, `lib/features/match/widgets/viewer/live_viewer_suggestions.dart`.
- Test: `test/match/live_score_header_scoring_test.dart`, `test/features/match/live_viewer_suggestions_test.dart`.
