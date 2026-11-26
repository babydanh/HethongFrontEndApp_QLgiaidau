## Why
Trận tennis đôi "test live" (26/11): máy trọng tài hiện 40-40 nhưng Backend dừng ở game 0-1, điểm 30-0 (revision 9, lần ghi cuối 11:25:00Z, chỉ 6 scoreEvents). Backend nhận ghi điểm live kiểu last-write-wins, không throttle, không kiểm `liveState`, nên lần ghi sau 30-0 không tới được Backend. Trong App, một lần ghi điểm live lỗi (timeout, rớt mạng, 5xx) không bao giờ được gửi lại nếu trọng tài không bấm tiếp, và bản server cũ bị bỏ qua nên máy trọng tài lệch Backend mãi. Ngoài ra App xem trận giữ "chưa có bản ghi" (null) suốt đời app, và overlay tennis vẽ như pickleball (chỉ số game set đang đá, không có điểm 0/15/30/40/AD, không có cột set).

## What Changes
- Ghi điểm live (`ScorePanelNotifier._syncLiveScore`) lỗi không phải 409 thì tự gửi lại bản điểm mới nhất, lùi 0,5s → 8s; ghi được thì xoá cảnh báo đồng bộ. Vẫn một request một lúc, luôn gửi bản mới nhất.
- `matchPlaybackProvider` / `matchReplayProvider` thành `autoDispose`; bản ghi lỗi tạm thì ném lỗi để Riverpod tự thử lại thay vì giữ null; `LiveVideoBox(matchStatus:)` hỏi lại live và bản ghi khi trận đổi trạng thái (như Web).
- Overlay tennis (live và replay theo giây video): cột game từng set đã bắt đầu (S1 luôn có, S2/S3 chỉ khi đã bắt đầu, gồm set đang đá), ô điểm 0/15/30/40/AD (40-40 khi deuce, số khi tie-break), đọc cả chỉ số int của App lẫn chuỗi của Web. Môn khác giữ `LiveScoreboardOverlay` cũ.

## Out of scope
- Nhãn chữ "DEUCE" trên overlay (40-40 đã đúng luật; thêm chữ cần key l10n, lane camera giữ file l10n).
- Sửa Web `readTennisLivePointState` (lane Web).
- Log/ghi nhận phía Backend cho lần ghi lỗi.

## Capabilities
### New Capabilities
- `tennis-live-overlay`: điểm tennis từng pha lên Backend, App phát bản ghi, overlay tennis theo luật.

### Modified Capabilities
(không)

## Impact
- `lib/features/match/notifiers/score_panel_notifier.dart`, `lib/features/match/widgets/live_video_box.dart`, `lib/features/match/screens/live_score_screen.dart` (khối `_liveScoreOverlay` + truyền `matchStatus`), mới `lib/features/match/widgets/viewer/tennis_scoreboard_columns.dart`, `tennis_live_scoreboard_overlay.dart`; test `test/match/score_panel_live_sync_retry_test.dart`, `live_video_box_replay_refresh_test.dart`, `tennis_scoreboard_overlay_test.dart`.
