## Why
Trang xem live và popup "Chi tiết trận" trông rối: bảng điểm trên video là hai ô trắng dán rời, khác overlay Web và H2H/Sơ đồ; ba chip ngang hàng; chat trống trơn; popup nhiều màu, hai chữ "Chưa có" xanh to. Bản vẽ Lavish `app-live-viewer-popup.html` đã được anh góp ý.

## What Changes
- Bảng điểm trên video của người xem: kiểu overlay Web (2 hàng chồng, vạch xanh, ô điểm vát), nằm góc trên trái video như Web, tên viết tắt IN HOA không avatar; thanh Quay lại/LIVE/Chia sẻ/Thêm tách thành dải riêng phía trên video (chế độ dọc); tạm ẩn khi Sơ đồ phủ kín khung.
- Hàng nút còn Cổ vũ + Chia sẻ; tên giải thành link ở dòng phụ.
- Chat rỗng có chữ gợi ý; ô nhập một khối tròn, bỏ nút tim thừa.
- Popup Chi tiết trận: đầu popup là bảng điểm hai đội, bỏ thẻ ELO "Chưa có", ẩn dòng chưa có dữ liệu, "Báo cáo" thành nút viền nhỏ.

## Out of scope
- Không đổi API, không sửa Backend/Web, không đổi overlay H2H/Sơ đồ.
- Không sửa dữ liệu sai của trận (ví dụ "Cầu lông · Luật mở" trong giải Pickleball).
- Bảng điểm của người điều khiển giữ góc trên trái.

## Capabilities
### New Capabilities
- `live-viewer-layout`: bố cục trang xem live và popup Chi tiết trận.
### Modified Capabilities
(không)

## Impact
- `lib/features/match/screens/live_score_screen.dart`
- `lib/features/match/widgets/viewer/` (overlay mới, header, popup)
- `lib/l10n/app_vi.arb`, `app_en.arb`
