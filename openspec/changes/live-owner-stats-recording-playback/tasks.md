## 1. Huy hiệu chủ giải/admin

- [x] 1.1 Model `MatchStreamInfoModel` (`matchId`, `available`, `video {codec, width, height, fps}`) và `getMatchStreamInfo` trên `IMatchPlaybackRepository` / `ApiMatchPlaybackRepository` (GET `stream-info`, qua `DioClient` có token, `noCache`).
- [x] 1.2 Hàm thuần `formatLiveStreamStats` (ping, trễ, FPS → chuỗi, `—` khi thiếu) và widget `LiveStreamStatsBadge`: Ping GET manifest mỗi 5s bằng `Dio` riêng không token, timeout 4s; Trễ từ `buffered`/`position` mỗi 1s; FPS mỗi 10s; huỷ timer và `Dio` khi dispose, đổi URL, tắt cờ.
- [x] 1.3 `LiveVideoPlayer`: tham số `showStreamStats` (mặc định false) và `matchId`; badge góc trên trái, key `live-stream-stats`.
- [x] 1.4 `LiveVideoBox` nhận và chuyển `showStreamStats`; `live_score_screen.dart` tính cờ = admin || `tournament.creatorId == userProfile.id` (KHÔNG dùng `auth.canScore`).
- [x] 1.5 l10n `liveStreamStatsBadge` (vi/en).

## 2. Phát lại bản ghi

- [x] 2.1 Model `MatchRecordingPlaylist` / `MatchRecordingSegment` + repository `getPlaylist(matchId, period:)` (lọc URL https, tên tệp an toàn, giữ thứ tự).
- [x] 2.2 Bộ điều phối thuần (chọn đoạn kế, bỏ đoạn lỗi, biết khi tất cả lỗi) tách khỏi widget để test.
- [x] 2.3 Widget `MatchRecordingPlayerSheet`: 2 controller luân phiên, danh sách đoạn, chạm chuyển đoạn, trạng thái tải/lỗi/tất cả lỗi.
- [x] 2.4 Nút "Phát lại ngày này" trong `match_recording_catalog_sheet.dart`; l10n.

## 3. Kiểm tra

- [x] 3.1 Test: formatter huy hiệu; repository stream-info; repository playlist; bộ điều phối; widget huy hiệu (chủ giải thấy, người xem không); widget trình phát bản ghi. Đã viết: 7 file test mới, 2 file test cũ có sửa (`live_score_video_panel_test.dart`, `tournament_management_camera_catalog_test.dart`). CHƯA chạy được, xem 3.2.
- [ ] 3.2 `flutter analyze --no-pub` các thư mục đã sửa; `flutter test --no-pub` các test mới và 3 test cũ. Đã chạy `flutter analyze --no-pub` trên 23 file đã sửa: No issues found (exit 0). CHƯA chạy `flutter test`: worktree thiếu `.env` (asset khai báo trong pubspec), không tạo `.env` theo quy tắc.
- [x] 3.3 `openspec validate live-owner-stats-recording-playback --strict`: valid (exit 0).
