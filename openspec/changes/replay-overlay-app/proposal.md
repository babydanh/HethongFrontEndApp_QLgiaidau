## Why

Trận đã đấu xong, App phát lại bản ghi nhưng **không hiện H2H và Sơ đồ** như lúc live. Backend đã ghi mốc bật/tắt hai overlay này và trả `overlayEvents` trên timeline phát lại (`GET /livestream/matches/{matchId}/replay`, đã lên `main`, commit `d0445b04`); Web đã vẽ theo mốc đó (nhánh `replay-overlay-theo-video`, đã lên staging). App chưa đọc `overlayEvents` nên phát lại chỉ có video trần.

Phạm vi: **chỉ App**. Hợp đồng Backend giữ nguyên.

## What Changes

- Model `MatchReplay` đọc thêm `overlayEvents` (`kind`, `visible`, `offsetSec`), bỏ qua phần tử sai dạng, thiếu thì rỗng.
- Hàm thuần `matchReplayOverlayAt(events, seconds)` cho biết H2H/Sơ đồ đang bật ở một giây của timeline: sự kiện cuối cùng không muộn hơn `seconds` quyết định, theo từng loại.
- `MatchReplayPlayer` báo vị trí timeline ra ngoài; `LiveVideoBox` chuyển tiếp.
- Màn live/replay dùng vị trí đó để chọn overlay khi đang phát lại, rồi vẽ bằng đúng widget H2H và Sơ đồ đang dùng cho live (cùng quy tắc "một overlay một lúc").
- Trận cũ hoặc Backend cũ không có `overlayEvents`: không hiện gì, hành vi như hiện nay.

## Impact

- Code: `lib/data/models/match_playback_model.dart`, `lib/features/match/widgets/match_replay_timeline.dart`, `match_replay_player.dart`, `live_video_box.dart`, `lib/features/match/screens/live_score_screen.dart`.
- Test: model, hàm thuần, widget phát lại.
- Không đổi API, không đổi schema, không thêm package.
- Bản ghi video KHÔNG bị chèn overlay vào hình: overlay được vẽ lại lúc xem, nên chỉ trận có mốc đã ghi (sau `d0445b04`) mới có.
