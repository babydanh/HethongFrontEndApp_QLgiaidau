## Why
Web đã có "tường camera" ở tab Camera của BTC (change Web `camera-tuong-xem-giai`, E2E 5/5 pass run 43265705027): BTC xem nhiều camera cùng lúc theo lưới 1×1, 2×2, 3×3, 4×4. App chưa có, BTC cầm điện thoại ở sân không xem được các camera cùng lúc và không biết camera nào đang chiếu trận nào.

## What Changes
- Tab Camera (`TournamentManagementCameraSection`) thêm nút "Xem camera" cạnh nút tải lại, chỉ hiện khi giải có ít nhất một camera.
- Bấm nút mở màn toàn màn hình "Tường camera" có thanh chọn lưới 1×1, 2×2 (mặc định), 3×3, 4×4; tối đa `n×n` ô một trang, nhiều hơn thì chia trang (nút trang trước/sau và "trang x/y").
- Mỗi ô: tên camera, `CameraStatusBadge` theo `TournamentCameraModel.status`, một dòng trận đang chiếu (mã trận + tên hai bên, không tỉ số), công tắc bật/tắt xem thử.
- Chỉ camera `LIVE` có `playbackUrl` và công tắc đang bật mới mở `LiveVideoPlayer` (`showStreamStats: true`); ô khác hiện nền xám kèm trạng thái.
- Chạm đúp một ô: chuyển sang lưới 1×1 ở đúng camera đó.
- Logic thuần (chia trang, điều kiện mở trình phát, chọn trận) giống `src/features/tournaments/camera-wall.ts` của Web.

## Out of scope
- Bật/tắt phát live thật cho khán giả (công tắc chỉ ngắt/nối khung hình trên máy BTC, không gọi Backend).
- Lưới 8×8. Nút "?" hướng dẫn và video hướng dẫn của Web.
- Backend, Web: không đổi endpoint, DTO hay route.

## Capabilities
### New Capabilities
- `camera-wall-app`: tường camera trên tab Camera của BTC trong App.

### Modified Capabilities
(không có)

## Impact
- Tạo `lib/features/tournament/utils/camera_wall.dart`, `lib/features/tournament/widgets/camera_wall_screen.dart`.
- Sửa `lib/features/tournament/screens/tournament_management_camera_section.dart` (một nút + điều hướng), `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (sinh lại `app_localizations*.dart` bằng `flutter gen-l10n`).
- Dùng lại: `tournamentCamerasProvider`, `tournamentMatchLivestreamsProvider`, `managedMatchesWithDivisionProvider`, `CameraStatusBadge`, `LiveVideoPlayer`.
- Tải máy: lưới 4×4 có thể mở tới 16 trình phát; công tắc xem thử để BTC tắt bớt.
