## Context
- Server (AQP, Backend) không với tới `192.168.x.x`. Chương trình kéo RTSP phải nằm trong cùng LAN với camera và chủ động đẩy luồng ra ngoài (kết nối đi ra).
- App đã có `ICameraAdminRepository` (`lib/domain/repositories/camera_admin_repository.dart`): `createCamera(mode: 'PUSH')`, `getStreamKey`, `createStreamKey`; `CameraStreamKeyModel` có `rtmpServer`, `rtmpStreamKey`, `hasKey`. Phần server nhận hình và link công khai đã có; thay đổi này chỉ thêm phía sân.

## Approach chọn: FFmpeg trong App, chuyển gói
Kéo RTSP (TCP) rồi `-c copy -f flv` đẩy RTMP. Không giải mã nên nhẹ; camera H.264 là điều kiện. Luồng:

```text
camera (RTSP, LAN) -> App tại sân (FFmpeg copy) -> RTMP -> AQP -> link công khai
```

## Phương án đã cân nhắc
| Phương án | Vì sao không chọn |
|---|---|
| Server kéo thẳng (`cameraRtspUrl`) | Chỉ chạy với IP công khai hoặc cổng đã mở; sân thường là IP nội bộ. |
| VPN/tunnel từ sân tới VPS | Cần cài thiết bị ở từng sân, thêm rủi ro bảo mật. |
| Mini PC chạy ffmpeg | Không cần App nhưng thêm phần cứng và thao tác riêng cho từng sân. |
| Điện thoại đẩy qua Larix (đang có) | Không dùng camera IP; vẫn giữ làm đường song song. |

## Quyết định
- Gói: `ffmpeg_kit_flutter_new` (bản chính `ffmpeg_kit_flutter` đã ngừng, kiểm pub.dev 2026-11-26). Chỉ thêm sau khi task 1.1 (spike) đạt và người dùng đồng ý thêm package (AGENTS.md: không thêm package khi chưa được yêu cầu).
- Mật khẩu camera chỉ giữ trong bộ nhớ phiên, không ghi đĩa, không log; URL RTSP đầy đủ không bao giờ vào log hay thông báo lỗi.
- Android only. Giữ phát khi tắt màn hình bằng foreground service.
- Không đổi Backend, Web; không thêm endpoint.

## Rủi ro
- Dung lượng app tăng, giấy phép gói FFmpeg (bản GPL hay LGPL) cần xác minh trước khi phát hành lên Play.
- H.265 không đi qua RTMP kiểu FLV cũ: chỉ báo lỗi và hướng dẫn đổi luồng, không mã hoá lại ở lần đầu.
- Băng thông tải lên của sân (khoảng 2–4 Mbps mỗi luồng 1080p) có thể không đủ cho 2 camera.
- Chưa thử trên tablet thật: số liệu CPU/nhiệt chỉ có sau task 1.1.
