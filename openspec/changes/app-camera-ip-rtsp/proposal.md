## Why
Sân thi đấu thường có camera IP (Dahua...) chỉ có địa chỉ nội bộ `192.168.x.x`. Server (AQP, Backend) nằm ngoài internet nên không kéo được luồng RTSP đó. Hiện BTC phải dùng điện thoại + app phát bên thứ ba (Larix) hoặc nhờ nhà cung cấp app ngoài. Mục tiêu: App của mình, chạy ngay tại sân chung wifi với camera, nhận IP/user/pass camera, kéo RTSP trong LAN và đẩy RTMP lên stream key AQP của camera PUSH; Web/App xem qua link công khai sẵn có.

## What Changes
1. Màn "Camera IP" (mở từ bảng camera của giải): chọn camera PUSH, nhập IP, hãng, username, mật khẩu, cổng RTSP, luồng chính/phụ; nút Bắt đầu/Dừng; hiện trạng thái (đang kết nối, đang phát, lỗi).
2. Bộ chuyển luồng: dựng URL RTSP theo hãng, chạy FFmpeg chuyển gói (`-c copy`) RTSP→RTMP lên `rtmpServer` + `rtmpStreamKey` lấy từ route stream-key AQP đã có (`ICameraAdminRepository.createStreamKey/getStreamKey`).
3. Giữ phát khi tắt màn hình (dịch vụ nền Android) và tự nối lại khi rớt mạng.

## Out of scope
- Backend và Web: không sửa, không thêm endpoint (route camera PUSH + stream key đã có).
- Camera cần mã hoá lại H.265 → H.264 (chỉ báo lỗi rõ, hướng dẫn đổi luồng phụ H.264).
- iOS (tablet sân là Android); lưu mật khẩu camera lâu dài (chỉ giữ trong bộ nhớ phiên).
- Tab camera đang sửa ở worktree `camera-san-gon-app`: chỉ thêm một điểm vào, không đổi bố cục tab.

## Capabilities
### New Capabilities
- `camera-ip-bridge`: kéo RTSP trong LAN, đẩy RTMP lên AQP từ App.

### Modified Capabilities
- (không)

## Impact
- Thêm `lib/features/camera_bridge/**` (màn, notifier, dịch vụ chuyển luồng), `lib/domain/services/camera_rtsp_url.dart` (dựng URL theo hãng), l10n ARB vi/en.
- Thêm package `ffmpeg_kit_flutter_new` (bản nhánh; bản chính đã ngừng) và quyền Android foreground service. Rủi ro: dung lượng app, giấy phép gói FFmpeg, chưa thử trên tablet thật → task 1.1 là cổng quyết định.
