# Proposal

## Why

Người dùng đổi ý (18/10): huy hiệu thông số luồng trên video live chỉ cần **Ping (ms)**. Đã kiểm trong code: FPS không bị khoá ở đâu trong App hay Backend, FPS chỉ cần phát đúng theo link HLS; Trễ là phần đệm trên App (`buffered.last.end - position`), không phải độ trễ camera, nên bỏ luôn.

Đã xác minh trong code (worktree `live-badge-ping-only-20261018` từ `origin/main`):
- `lib/features/match/widgets/live_stream_stats_badge.dart`: timer Trễ mỗi 1 giây đọc `controller.value.buffered`; timer FPS mỗi 10 giây gọi `ApiMatchPlaybackRepository.getMatchStreamInfo(matchId)`.
- `lib/data/repositories/api/api_match_playback_repository.dart`, `lib/domain/repositories/match_playback_repository.dart`, `lib/data/models/match_stream_info_model.dart`: method và model của `GET /livestream/matches/{matchId}/stream-info`, chỉ huy hiệu dùng.
- `lib/features/match/widgets/live_video_player.dart`: `matchId` chỉ để truyền cho huy hiệu gọi stream-info.

## What Changes

**Huy hiệu chủ giải/admin trên video live** (`LiveStreamStatsBadge`, góc trên trái) chỉ còn Ping:
- Hiện `Ping <n> ms`, hoặc `Ping —` khi chưa đo được.
- Giữ nguyên cách đo Ping: GET manifest `.m3u8` mỗi 5 giây bằng `Dio` riêng không token, giới hạn 64 KB, timeout 4 giây, huỷ bằng `CancelToken`. URL khác (ví dụ HTTP-FLV) không gọi mạng và hiện `—`.
- Quyền hiển thị không đổi: admin hoặc người tạo giải (`live_score_screen.dart`, `_canSeeStreamStats`). Trọng tài và người xem không thấy.

**Gỡ Trễ và FPS** khỏi App:
- Bỏ timer 1 giây (Trễ), timer 10 giây (FPS), tham số `controller` và `matchId` của huy hiệu; bỏ hàm `liveLatencyMs` và định dạng FPS.
- `LiveVideoPlayer` bỏ tham số `matchId` (chỉ dùng cho stream-info) và assert kèm theo; `LiveVideoBox` không truyền `matchId` xuống player.
- Gỡ `getMatchStreamInfo` trên `IMatchPlaybackRepository` và `ApiMatchPlaybackRepository`, model `MatchStreamInfoModel` (xoá file), test `test/match_stream_info_repository_api_test.dart` (xoá file, chỉ test stream-info). App không còn gọi `GET /livestream/matches/{matchId}/stream-info`.

**Chuỗi hiển thị** `liveStreamStatsBadge` (vi/en): chỉ còn placeholder `ping`, vi `Ping {ping}`, en `Ping {ping}`. Không còn key nào phục vụ Trễ hoặc FPS. Chạy `flutter gen-l10n`, không sửa tay file sinh.

## Không làm trong change này

- Không đổi cách đo Ping, ngưỡng 64 KB, 4 giây, 5 giây, và không đổi quyền hiển thị.
- Không thêm lại FPS hay Trễ, không đo FPS trên App, không thêm package.
- Không sửa Backend hay Web trong change này. Hai repo đó có worktree riêng (Backend `remove-stream-info-20261018`, Web `live-badge-ping-only-20261018`).
- Không sửa spec chính `openspec/specs/live-owner-stream-stats/spec.md` tay; archive sẽ đồng bộ sau khi người dùng chốt.
- Không đụng phần phát lại bản ghi (`match-recording-playback`).

## Capabilities

### New Capabilities

- Không có.

### Modified Capabilities

- `live-owner-stream-stats`: bỏ Trễ và FPS, huy hiệu chỉ còn Ping.

## Impact

- Code App: `live_stream_stats_badge.dart`, `live_stream_stats_format.dart`, `live_video_player.dart`, `live_video_box.dart`, `live_score_screen.dart` (chỉ comment), `match_playback_repository.dart`, `api_match_playback_repository.dart`, xoá `match_stream_info_model.dart`, `app_vi.arb`, `app_en.arb` và file l10n sinh.
- Test: `live_stream_stats_badge_test.dart`, `live_stream_stats_format_test.dart`, `live_score_video_panel_test.dart` (đổi tên test, bỏ comment FPS); xoá `match_stream_info_repository_api_test.dart`.
- Repo khác: không phụ thuộc. App không còn gọi endpoint stream-info, nên Backend có thể gỡ endpoint độc lập. Bản App cũ còn gọi endpoint đã gỡ sẽ nhận lỗi và FPS hiện `—`.
- Rủi ro: thấp. Thay đổi chủ yếu là xoá code; quyền, luồng HLS và cách đo Ping giữ nguyên.
