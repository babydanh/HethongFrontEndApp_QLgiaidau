## 1. Dữ liệu và logic thuần

- [x] 1.1 `MatchReplay` đọc `overlayEvents` (kind H2H/BRACKET, visible bool, offsetSec số thực >= 0), bỏ phần tử sai dạng, giữ thứ tự theo `offsetSec`. Tiêu chí: `flutter test --no-pub test/models/match_replay_overlay_events_test.dart` → exit 0 (TC-REPLAYOV-01..04)
  - Files: sửa `lib/data/models/match_playback_model.dart` (`MatchReplay` ~47-96, thêm lớp `MatchReplayOverlayEvent`); tạo `test/models/match_replay_overlay_events_test.dart`
  - Giao: `class MatchReplayOverlayEvent { const MatchReplayOverlayEvent({required LiveOverlayKind kind, required bool visible, required double offsetSec}); }` và `final List<MatchReplayOverlayEvent> MatchReplay.overlayEvents` (mặc định rỗng, không bắt buộc trong constructor)
  - Phụ thuộc: không
- [x] 1.2 Hàm thuần `matchReplayOverlayAt`. Tiêu chí: `flutter test --no-pub test/match/match_replay_overlay_test.dart` → exit 0 (TC-REPLAYOV-05..09: bật/tắt, tua lùi, rỗng, hai loại độc lập, sự kiện chưa sắp thứ tự)
  - Files: sửa `lib/features/match/widgets/match_replay_timeline.dart` (thêm cuối file); tạo `test/match/match_replay_overlay_test.dart`
  - Giao: `({bool h2h, bool bracket}) matchReplayOverlayAt(List<MatchReplayOverlayEvent> events, num seconds)`
  - Nhận: `MatchReplayOverlayEvent` từ 1.1
  - Phụ thuộc: 1.1

## 2. Player và màn hình

- [x] 2.1 `MatchReplayPlayer` gọi `onPositionChanged(int globalSeconds)` mỗi khi `_displayedSeconds` đổi (kể cả khi tua và đổi đoạn); `LiveVideoBox` chuyển tiếp thành `onReplayPositionChanged(int seconds)`. Màn hình tự suy ra chế độ phát lại từ provider (không có URL live và có bản ghi), không dùng tín hiệu null (báo từ dispose sẽ gây lỗi tree locked). Tiêu chí: `flutter test --no-pub test/match/match_replay_player_controls_test.dart` → exit 0 và thêm TC-REPLAYOV-10 (callback có giá trị sau tua)
  - Files: sửa `lib/features/match/widgets/match_replay_player.dart` (props ~18-31, nơi gán `_displayedSeconds` ~211, ~247); sửa `lib/features/match/widgets/live_video_box.dart` (props ~50-57, dựng player ~118); sửa `test/match/match_replay_player_controls_test.dart`
  - Giao: `ValueChanged<int>? MatchReplayPlayer.onPositionChanged`; `ValueChanged<int>? LiveVideoBox.onReplayPositionChanged`
  - Chủ file chung: 2.1 giữ `match_replay_player.dart` và `live_video_box.dart`
  - Phụ thuộc: không
- [x] 2.2 `live_score_screen.dart`: giữ `ValueNotifier<int> _replaySeconds`; khi provider cho thấy đang phát bản ghi thì overlay = `liveOverlayToShow` trên kết quả `matchReplayOverlayAt(replay.overlayEvents, seconds)` với `matchEnded: false`, còn lại giữ nguyên đường live; chỉ khối overlay bọc `ValueListenableBuilder`; nút đóng ẩn đến khi loại overlay đổi hoặc người xem tua. Tiêu chí: `flutter test --no-pub test/match/live_score_replay_overlay_test.dart` → exit 0 (TC-REPLAYOV-11..14: hiện H2H giữa mốc, ẩn sau mốc tắt, Sơ đồ thắng khi cả hai bật, không mốc thì không hiện) và `test/match/live_score_header_scoring_test.dart` vẫn exit 0
  - Files: sửa `lib/features/match/screens/live_score_screen.dart` (`_buildViewerState` ~2283-2475, thêm field và dispose); tạo `test/match/live_score_replay_overlay_test.dart` (theo mẫu `pumpWith` của `live_score_header_scoring_test.dart` và `fake_video_player_platform.dart`)
  - Nhận: `matchReplayOverlayAt` từ 1.2; `onReplayPositionChanged` từ 2.1; `MatchReplay.overlayEvents` từ 1.1
  - Chủ file chung: 2.2 giữ `live_score_screen.dart`
  - Phụ thuộc: 1.1, 1.2, 2.1

## 3. Kiểm và bàn giao

- [x] 3.1 Review (`flutter-reviewer`, `pr-test-analyzer`), `dart analyze` các file đã sửa, `affected` rồi chạy đúng các test nó chọn. Tiêu chí: `dart analyze <file đã sửa và file test mới>` → exit 0 và các test liên quan exit 0
  - Files: không sửa thêm trừ khi review yêu cầu
  - Phụ thuộc: 2.2
- [ ] 3.2 Thử thực tế một trận có mốc trên staging (trận sau `d0445b04`, BTC bật/tắt H2H lúc live) qua App chung trên máy thật (`app-run.py`). Tiêu chí: người xem thấy H2H/Sơ đồ đúng giây khi phát lại và khi tua; ghi kết quả vào `handoff.md`
  - Files: `openspec/changes/replay-overlay-app/handoff.md`
  - Phụ thuộc: 3.1
