## 1. Dữ liệu và logic thuần

- [x] 1.1 `MatchReplay` đọc `scoreEvents` (bỏ phần tử sai dạng, vắng thì rỗng, bất biến, sắp theo `offsetSec`). Tiêu chí: `flutter test --no-pub test/models/match_replay_score_events_test.dart` → exit 0 (TC-SCOREREPLAY-APP-01..04)
  - Files: sửa `lib/data/models/match_playback_model.dart`; tạo `test/models/match_replay_score_events_test.dart`
  - Giao: `class MatchReplayScoreEvent`, `MatchReplay.scoreEvents`
  - Phụ thuộc: không
- [x] 1.2 Hàm thuần `matchReplayScoreAt`. Tiêu chí: `flutter test --no-pub test/match/match_replay_score_test.dart` → exit 0 (TC-SCOREREPLAY-APP-05..11)
  - Files: sửa `lib/features/match/widgets/match_replay_timeline.dart`; tạo `test/match/match_replay_score_test.dart`
  - Giao: `MatchReplayScoreEvent? matchReplayScoreAt(List<MatchReplayScoreEvent>, num)`
  - Phụ thuộc: 1.1

## 2. Màn hình

- [x] 2.1 Bảng điểm trên video đổi theo giây phát lại. Tiêu chí: `flutter test --no-pub test/match/live_score_replay_overlay_test.dart` → exit 0 (TC-SCOREREPLAY-APP-12..13)
  - Files: sửa `lib/features/match/screens/live_score_screen.dart` (quanh `_replayInUse`, `_matchAtReplayScore`, khối `ValueListenableBuilder`); sửa `test/match/live_score_replay_overlay_test.dart`
  - Phụ thuộc: 1.1, 1.2

## 3. Kiểm tra

- [ ] 3.1 Thử trên máy thật với trận có `scoreEvents` (cần Backend đã lên và người cầm máy).
