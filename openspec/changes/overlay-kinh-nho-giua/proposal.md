## Why
Trên màn trực tiếp của App, khung H2H gần bằng bề ngang video, cao ~1/3 video, nền gần đặc nên che hình; sơ đồ giải và bảng điểm cũng dùng cỡ dp cố định. Cần khung gọn theo cỡ video, canh giữa, nền kính mờ như truyền hình.

## What Changes
- Ba overlay (H2H, sơ đồ giải, bảng điểm) co theo bề rộng video: hệ số `s = (videoWidth / 400).clamp(0.55, 1.0) * 0.7`, chữ tối thiểu 8sp.
- H2H: canh giữa, rộng ~70% video (220-420dp), sát đáy trong video trên thanh điều khiển; tiêu đề có logo Sporto SVG.
- Sơ đồ: canh giữa hai chiều, ~80% rộng x ~72% cao vùng cho phép. Bảng điểm: giữ góc trên trái, chỉ co nhỏ.
- Nền kính: bỏ lớp mờ cả khung, dùng nền navy alpha ~0.55 + `BackdropFilter` blur 10; chữ, avatar, viền, nút đóng giữ đậm 100%.
- Nút X: chấm tròn 24dp, vùng chạm 44dp, treo ở góc phải trên của khung, không còn chừa 48dp trong thẻ.
- Sơ đồ thu vừa khung (`FittedBox`), véo để phóng; H2H/sơ đồ cách đáy video 8dp, lên trên thanh điều khiển khi thanh hiện; video mở lên có tiếng; trang xem lại có lớp lùi/tiến 3s khi chạm.

- Cửa sổ nhỏ (PiP) chỉ Android: nút trên thanh điều khiển, trong PiP chỉ còn video đang phát.

## Impact
`lib/features/match/widgets/viewer/live_h2h_overlay.dart`, `live_scoreboard_overlay.dart`, `lib/features/match/widgets/live_overlay_controls.dart`, `lib/features/match/screens/live_score_screen.dart` (vị trí overlay, `_buildH2hOverlay`, `_buildBracketOverlay`).
