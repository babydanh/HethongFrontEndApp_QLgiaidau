## 0. Kiểm tra kế hoạch
- [ ] 0.1 Cross-check by a fresh-context reviewer. Tiêu chí: no open P0/P1
  - Kết quả: (chưa chạy)

## 1. Spike (cổng quyết định, không merge code spike)
- [ ] 1.1 Chạy thử trên tablet/điện thoại thật: kéo RTSP một camera Dahua, đẩy RTMP lên key AQP của một camera PUSH thử, đo CPU/nhiệt/độ trễ. Tiêu chí: người dùng xác nhận Web xem được luồng; ghi số đo vào `design.md`; sai thì dừng cả change.
  - Files: sửa `openspec/changes/app-camera-ip-rtsp/design.md` (mục Rủi ro); tạm thêm `pubspec.yaml` ở nhánh spike, không merge
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.1 giữ `pubspec.yaml`
  - Phụ thuộc: người dùng đồng ý thêm package; người dùng cung cấp camera/tablet và `.env` cho worktree

## 2. Logic thuần (đỏ trước)
- [ ] 2.1 Dựng URL RTSP theo hãng, mã hoá phần trăm user/pass, luồng chính/phụ. Tiêu chí: `flutter test --no-pub test/domain/camera_rtsp_url_test.dart` → exit 0
  - Files: tạo `lib/domain/services/camera_rtsp_url.dart`; test `test/domain/camera_rtsp_url_test.dart` (TC-CAMBR-01..)
  - Giao: `String buildCameraRtspUrl({required CameraBrand brand, required String host, required int port, required String user, required String password, required bool mainStream})` và `enum CameraBrand { dahua, hikvision }` · Nhận: (không)
  - Chủ file chung: 2.1 giữ `camera_rtsp_url.dart`
  - Phụ thuộc: (không)

## 3. Dịch vụ chuyển luồng
- [ ] 3.1 Dịch vụ chạy FFmpeg chuyển gói, trạng thái, tự nối lại có backoff, chống bấm đúp, không log URL. Tiêu chí: `flutter test --no-pub test/features/camera_bridge/camera_bridge_notifier_test.dart` → exit 0 (dùng cổng FFmpeg giả)
  - Files: tạo `lib/features/camera_bridge/camera_bridge_notifier.dart`, `lib/features/camera_bridge/ffmpeg_runner.dart`; test `test/features/camera_bridge/camera_bridge_notifier_test.dart` (TC-CAMBR-02..)
  - Giao: `abstract class FfmpegRunner { Stream<BridgeEvent> run(String rtspUrl, String rtmpUrl); Future<void> stop(); }`, `enum BridgeStatus { idle, connecting, live, error }` · Nhận: `buildCameraRtspUrl` (2.1), `CameraStreamKeyModel.rtmpServer/rtmpStreamKey` (đã có)
  - Chủ file chung: 3.1 giữ thư mục `lib/features/camera_bridge/`
  - Phụ thuộc: sau 1.1 và 2.1

## 4. Màn hình
- [ ] 4.1 Màn "Camera IP": chọn camera PUSH, nhập IP/hãng/user/pass/cổng, Bắt đầu/Dừng, trạng thái; l10n vi/en. Tiêu chí: `flutter test --no-pub test/features/camera_bridge/camera_bridge_screen_test.dart` → exit 0
  - Files: tạo `lib/features/camera_bridge/camera_bridge_screen.dart`; sửa `lib/core/router/app_router.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/camera_bridge/camera_bridge_screen_test.dart` (TC-CAMBR-03..)
  - Giao: route `/camera-bridge` · Nhận: `CameraBridgeNotifier` (3.1)
  - Chủ file chung: 4.1 giữ `app_router.dart` và hai file ARB
  - Phụ thuộc: sau 3.1
- [ ] 4.2 Giữ phát khi tắt màn hình (foreground service Android). Tiêu chí: `flutter analyze --no-pub lib/features/camera_bridge` → exit 0; người dùng xác nhận trên tablet khoá màn 5 phút vẫn phát
  - Files: sửa `android/app/src/main/AndroidManifest.xml`; tạo `lib/features/camera_bridge/bridge_foreground_service.dart`
  - Giao: (không) · Nhận: `CameraBridgeNotifier` (3.1)
  - Chủ file chung: 4.2 giữ `AndroidManifest.xml`
  - Phụ thuộc: sau 4.1

## 5. Kiểm tra cuối
- [ ] 5.1 Phân tích tĩnh và test liên quan. Tiêu chí: `flutter analyze --no-pub lib/features/camera_bridge lib/domain/services` → exit 0 và CI nhánh xanh
  - Files: (không sửa)
  - Giao: (không) · Nhận: tất cả task trên
  - Chủ file chung: (không)
  - Phụ thuộc: sau 4.2
