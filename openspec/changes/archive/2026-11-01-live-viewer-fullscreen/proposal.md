## Why

Part A (`live-viewer-youtube`) đã đổi bố cục dọc. Còn thiếu so với thiết kế đã duyệt (Lavish bản 3) và so với Twitch/SOOP: màn ngang toàn màn hình với chat phủ, nút toàn màn hình, nút "về live", chat bám đáy có nhãn tin mới và gộp tin liền nhau, nút báo cáo.

## What Changes

- Người xem (không phải trọng tài/BTC): màn ngang bỏ AppBar, video phủ kín, chat nền trong suốt ở bên phải (ẩn/hiện được), có ô nhập và nút cổ vũ.
- Nút toàn màn hình trên video (dọc → ngang immersive, ngang → về dọc); rời màn thì trả lại xoay màn hình và thanh hệ thống.
- Trình phát: nút "Về live" khi đang chậm hơn mép live.
- Chat: khi người dùng cuộn lên, tin mới không kéo danh sách và hiện nhãn "N tin mới" bấm để về đáy; tin liền nhau của cùng một người gộp (ẩn avatar/tên lặp).
- Chip "Báo cáo" dưới video mở `ReportSheet` có sẵn (`POST /reports`, target `match`).

## Out of scope

- PiP: cần plugin native mới, repo cấm thêm package khi chưa được yêu cầu.
- Đa camera: Backend chỉ trả một luồng cho mỗi trận (`GET /livestream/matches/:id/playback`), chưa có API liệt kê camera cho người xem.
- Tài trợ: lane `o-live-tai-tro-xacnhan` đang làm.
- Thanh trượt âm lượng: đã bỏ có chủ đích từ trước (chú thích trong `live_video_player.dart`), giữ nút tắt/bật tiếng.
- Không đổi Backend/Web.

## Capabilities

### New Capabilities
- `live-viewer-fullscreen`: màn ngang toàn màn hình + chat phủ, về live, chat bám đáy/tin mới/gộp tin, báo cáo trận.

### Modified Capabilities

## Impact

`lib/features/match/screens/live_score_screen.dart`, `lib/features/match/widgets/live_video_player.dart`, `live_video_box.dart`, `match_discussion_message.dart`; mới `lib/features/match/widgets/viewer/live_landscape_chat.dart`, `live_chat_grouping.dart`, `live_new_messages_pill.dart`; `live_viewer_header.dart` (chip Báo cáo); `lib/l10n/app_vi.arb`, `app_en.arb` và code sinh; test mới trong `test/features/match/` và `test/match/`.
