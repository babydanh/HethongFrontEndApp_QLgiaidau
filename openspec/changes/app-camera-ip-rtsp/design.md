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

## Giao diện (đối chiếu hướng dẫn ui-ux-pro-max, tra 2026-11-26)

### App: màn "Camera IP" (tablet ngang là chính, điện thoại dọc xếp chồng)
```text
┌────────────────────────────────────────────────────────────┐
│ ‹  Camera IP · <tên giải>                  [Nhớ cho giải này]│
├──────────────────────────────┬─────────────────────────────┤
│ Cam 1              ● Đang phát│ Cam 2         ○ Chưa kết nối │
│ IP        [192.168.1.50     ]│ IP        [                 ]│
│ Hãng      [Dahua          ▾]  │ Hãng      [Dahua          ▾]  │
│ Cổng      [554] Luồng (Chính|Phụ)│ Cổng      [554] Luồng (Chính|Phụ)│
│ Tài khoản [admin           ] │ Tài khoản [                 ]│
│ Mật khẩu  [••••••        👁] │ Mật khẩu  [               👁]│
│            [   Dừng   ]      │            [  Bắt đầu  ]     │
└──────────────────────────────┴─────────────────────────────┘
```
- Mỗi trường có nhãn luôn hiện, không chỉ placeholder (hướng dẫn "Form Labels"); mật khẩu có nút xem/ẩn ("Password Visibility"); dùng `Form` + `GlobalKey`, kiểm tra khi bấm Bắt đầu ("Use Form widget", "Validate on submit").
- Camera 2 là tuỳ chọn: nút "+ Thêm camera 2", có "Gỡ camera 2". Cổng RTSP mặc định 554, vẫn sửa được.
- Bàn phím không che trường đang nhập: màn cuộn được, cuộn tới trường có tiêu điểm (ảnh mẫu bị bàn phím che nửa form là lỗi cần tránh).
- Huy hiệu trạng thái có chấm + chữ, không chỉ màu; đổi trạng thái đọc qua `Semantics(liveRegion)` bằng một câu có ngữ cảnh ("Cam 1: đang phát"), không đọc số trơn. Chữ không xuống dòng trong huy hiệu (`maxLines: 1`, cắt bằng dấu …).
- Bốn trạng thái: Chưa kết nối (xám), Đang kết nối/nối lại (vàng), Đang phát (xanh), Lỗi (đỏ). Khi tablet báo đang phát nhưng `GET /livestream/cameras/{id}/status` trả OFFLINE thì hiện "Mất tín hiệu" (đỏ); hỏi trạng thái 15 giây một lần chỉ khi màn đang mở.
- Lỗi hiện ngay trong thẻ camera, nói rõ cách xử lý: sai mật khẩu; không thấy camera (tablet phải chung wifi với camera); camera phát H.265 (chọn luồng phụ). Không hiện URL hay mật khẩu.
- Vùng bấm tối thiểu 48dp; nút Bắt đầu/Dừng bị khoá khi đang gửi (chống bấm đúp). Màu, cỡ chữ, khoảng cách dùng token sẵn của app (không màu cứng); kiểm sáng và tối.
- Gọn: tối đa một nút chính mỗi thẻ, không icon thừa, không lặp thông tin.

### Web: không đổi trong thay đổi này
- Web đã có `CameraWall.tsx` (huy hiệu LIVE/WAITING/IDLE/OFFLINE/ERROR) và tab Livestream của BTC; trạng thái online/offline của camera đẩy từ tablet hiện ở đó vì dùng cùng bảng camera và cùng route trạng thái.
- Trình duyệt không kéo được RTSP trong LAN nên không có màn nhập IP trên Web. Nếu BTC cần xem trạng thái sau khi tablet ngắt, Web đã hiện OFFLINE; thiếu gì thêm sẽ ghi thành task riêng sau khi thử thật.
