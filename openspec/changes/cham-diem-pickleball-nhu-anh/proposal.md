## Why

Người chấm điểm pickleball cầm máy ngang và đã quen màn chấm điểm kiểu bảng điểm (ảnh người dùng gửi): sân 3 cột, điểm lớn ở giữa, thanh nút cộng/trừ dưới đáy. Màn sân hiện tại của App (điểm nằm trong dải bếp, icon trên lưới) khác hẳn nên khó thao tác.

## What Changes

- Khi cầm ngang, sân pickleball vẽ lại theo ảnh: hàng trên có nút **KẾT THÚC** (đỏ) và **⋯**; sân 3 cột (nửa trái, giữa, nửa phải); mỗi nửa có nút **↕** đổi chỗ phải/trái; giữa sân có lời hô, hai điểm lớn, **⇄** đổi sân, chữ "pickleball · Set n"; thanh dưới có đồng hồ, **+ / −** của đội trái, **ĐỔI GIAO**, **− / +** của đội phải; ô đang giao đổi màu xanh kèm nhãn **GIAO n**.
- **KẾT THÚC** mở hộp thoại có hai lựa chọn: **Chốt set** và **Chọn đội thắng** (dùng lại đúng hai hộp thoại xác nhận hiện có).
- Màu đội đổi theo ảnh: Đội 1 cam, Đội 2 xanh (cả hộp thoại chọn đội thắng và sân cầm dọc).
- Giữ nguyên mọi tính năng cũ: kéo thả đổi chỗ/đổi sân/giao bóng, menu ⋯ (đổi sân, hoàn tác, khôi phục tự động, tự đổi sân, ngoại lệ, xử thắng nhanh), khoá "+" của đội nhận ở side-out, rally, Lite, chế độ chỉ xem, quyền chấm điểm.
- Không làm Timeout và CHECK VAR (người dùng đã bỏ khỏi thiết kế).
- Sân cầm dọc giữ bố cục hiện tại, chỉ đổi màu đội.

## Impact

- Chỉ App Flutter (`lib/features/match/widgets/`, 2 file `.arb`). Không đổi API, không đổi luật tính điểm (`utils/pickleball_court.dart`), không thêm package.
