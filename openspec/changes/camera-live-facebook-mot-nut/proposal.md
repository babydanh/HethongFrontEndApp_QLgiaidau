## Why

Trên App, tạo camera live Facebook là nhiều bước rời: bấm "Tạo live", đọc khoá phát, tự đặt tên camera rồi bấm lưu. Người dùng muốn một nút: bấm xong là có camera và có luôn thứ cần để phát (giống Web, change cùng tên).

## What Changes

- Trong sheet "Thêm camera" (tab link live), nút của `FacebookLivePanel` đổi thành **"Tạo camera live Facebook"**: tạo live → tự `createCamera` PULL với `watchUrl` (tên mặc định `Live Facebook HH:mm` nếu để trống, giữ sân đã chọn) → đóng sheet → mở sheet **"Camera đã sẵn sàng"** (máy chủ RTMP, khoá phát che sẵn + sao chép, Mở trong Larix, QR, Xong).
- Lỗi `FACEBOOK_PAGE_NOT_ELIGIBLE` (Backend, change cùng tên) hiện thông báo rõ: fanpage cần ≥ 100 người theo dõi, liên hệ quản trị viên.
- Dán link live thủ công vẫn dùng ô link + nút lưu như cũ.

## Out of scope

- Không đổi Backend, `IFacebookCameraLiveRepository`, `ICameraAdminRepository`, luồng PUSH/AQP.
- Không đổi nhánh/worktree của phiên khác (`cam-live-app`, `fb-page-chung-app`, `app-tuong-camera*`).

## Capabilities

### New Capabilities
- `facebook-camera-one-tap`: một nút tạo live + camera + sheet "Camera đã sẵn sàng", kèm thông báo riêng cho `FACEBOOK_PAGE_NOT_ELIGIBLE`.

### Modified Capabilities
- (không)

## Impact

- `facebook_live_panel.dart`, `camera_editor_sheet.dart`, `camera_create_flow.dart`, `facebook_live_error.dart`, tạo `facebook_live_ready_sheet.dart`, `app_vi.arb`, `app_en.arb` + sinh lại `app_localizations*.dart`, test widget/unit.
- Hợp đồng nhận từ Backend: HTTP 400 `{ code: "FACEBOOK_PAGE_NOT_ELIGIBLE", message }`.
