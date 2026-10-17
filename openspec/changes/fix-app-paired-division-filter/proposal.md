## Why

Change `fix-app-pairing-division-select` lọc danh sách chờ ghép và danh sách đơn theo nội dung đang chọn, nhưng mục "Đã ghép" của màn ghép cặp Lite vẫn dựng từ toàn bộ VĐV của giải (`lite_pairing_screen.dart`, `allPaired`). Giải nhiều nội dung vì vậy vẫn hiện cặp của nội dung khác dưới nội dung đang chọn, và nút tạo sơ đồ có thể hiện ra chỉ vì nội dung khác đã có cặp.

## What Changes

- Mục "Đã ghép" chỉ hiện cặp của nội dung đang chọn (giải một nội dung giữ như cũ).
- Nút tạo sơ đồ hiện khi nội dung đang chọn có cặp; giải nhiều nội dung chưa chọn vẫn hiện nút để mở hộp chọn nội dung.

## Capabilities

### Modified Capabilities

- `lite-pairing-visibility`: requirement "Màn ghép cặp chọn nội dung bằng bộ chọn dùng chung" thêm mục "Đã ghép".

## Impact

- `lib/features/lite/screens/lite_pairing_screen.dart`
- `test/features/lite/lite_pairing_screen_request_test.dart`
