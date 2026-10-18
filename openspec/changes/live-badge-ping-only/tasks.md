# Tasks

## 1. Huy hiệu chỉ còn Ping

- [x] 1.1 `LiveStreamStatsBadge` chỉ nhận `url`; chỉ đo Ping (GET manifest mỗi 5 giây, 64 KB, timeout 4 giây, không gọi mạng với URL không phải `.m3u8`); bỏ timer Trễ, timer FPS, `controller`, `matchId`. Kiểm chứng: `grep -rn -E "stream-info|StreamInfo" lib test` rỗng; `live_stream_stats_badge_test.dart` pass.
- [x] 1.2 `live_stream_stats_format.dart` chỉ còn `shouldMeasurePingFor` và `formatLivePing`. Kiểm chứng: `live_stream_stats_format_test.dart` pass.
- [x] 1.3 `LiveVideoPlayer` bỏ `matchId` và assert; huy hiệu hiện khi `showStreamStats`; `LiveVideoBox` không truyền `matchId` xuống player. Kiểm chứng: `live_score_video_panel_test.dart` pass (chủ giải thấy, admin thấy, trọng tài không thấy).

## 2. Gỡ stream-info

- [x] 2.1 Xoá `getMatchStreamInfo` trên `IMatchPlaybackRepository` và `ApiMatchPlaybackRepository`; xoá `lib/data/models/match_stream_info_model.dart` và `test/match_stream_info_repository_api_test.dart`. Kiểm chứng: `grep -rn -E "stream-info|StreamInfo|liveStreamLatency|liveStreamFps" lib test` rỗng.

## 3. Chuỗi hiển thị

- [x] 3.1 `liveStreamStatsBadge` trong `app_vi.arb` và `app_en.arb` chỉ còn placeholder `ping` (`Ping {ping}`); chạy `flutter gen-l10n`. Kiểm chứng: `flutter gen-l10n` chạy xong; file sinh có `liveStreamStatsBadge(String ping)`.

## 4. Test và kiểm chứng

- [x] 4.1 Cập nhật test: badge (HTTP-FLV không gọi mạng và hiện `Ping —`; HLS hiện `Ping 42 ms`; lỗi hiện `Ping —`), formatter, panel (chủ giải và admin thấy, trọng tài không thấy). Kiểm chứng: `flutter test --no-pub` 7 file liên quan → All tests passed, 27 test.
- [x] 4.2 `openspec validate live-badge-ping-only --strict` hợp lệ.
- [x] 4.3 Chạy cuối cùng: `flutter analyze --no-pub` các file đã sửa → No issues found; `flutter test --no-pub` các test liên quan (badge, format, panel, manifest probe, `match_recording_playback_plan_test.dart`, `match_recording_player_sheet_test.dart`, `match_recording_playlist_repository_api_test.dart`) → All tests passed.
