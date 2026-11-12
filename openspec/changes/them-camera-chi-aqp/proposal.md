## Why

Hộp "Thêm camera" trong App còn bắt BTC chọn PUSH hay PULL và dán URL phát, những chữ khó hiểu. Chủ dự án chốt: **chỉ đưa hình vào qua AQP của SportO** (không nhận link YouTube/Facebook hay luồng ngoài). Hộp cũng chưa có chỗ hỏi cách dùng. Web đã đổi cùng ý (change cùng tên ở repo Web); App phải khớp.

## What Changes

- Hộp "Thêm camera" bỏ nút PUSH/PULL và ô URL phát. Camera mới luôn là `PUSH`.
- Thêm nút **"?"** nhấp nháy vài lần ở đầu hộp. Bấm mở khung hướng dẫn có hoạt hình luồng (OBS/điện thoại → AQP SportO → người xem) và 3 bước. Tắt hoạt hình khi hệ điều hành bật giảm chuyển động.
- Bỏ 5 chuỗi không còn dùng (`tournamentCameraModeLabel`, `...ModePushHint`, `...ModePullHint`, `...UrlLabel`, `...UrlInvalid`), thêm 8 chuỗi hướng dẫn vi/en. Dòng phụ của panel camera bỏ chữ "PUSH hoặc PULL".
- Nút "Thêm camera" ở panel đã có chữ sẵn, giữ nguyên.
- Backend không đổi: camera PULL cũ vẫn hiện và đổi sân được như trước.
- Không làm video mẫu hướng dẫn.

## Impact

- `lib/features/tournament/widgets/camera_editor_sheet.dart`, file mới `camera_add_help.dart`, `tournament_camera_panel.dart` (bỏ truyền `playbackUrl`), `lib/l10n/app_vi.arb`, `app_en.arb` và file sinh `app_localizations*.dart`.
- Test: `test/features/camera_editor_sheet_test.dart` (bỏ ca PULL, thêm TC-CAM-AQP-APP-01..03).
- Rủi ro: không còn đường tạo camera PULL từ App (đã chốt bỏ).
