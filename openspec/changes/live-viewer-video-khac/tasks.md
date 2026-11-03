## 1. Bảng điểm người xem

- [x] 1.1 Header người xem (dọc) nằm trên hình video, bảng điểm bám góc trên trái của hình. Tiêu chí: `flutter test --no-pub test/match/live_score_header_scoring_test.dart` → exit 0
  - Files: sửa `lib/features/match/screens/live_score_screen.dart` (`_buildViewerState`); test `test/match/live_score_header_scoring_test.dart` (TC-LIVEVIEW-11)
  - Giao: không · Nhận: không
  - Chủ file chung: 1.1 giữ phần header/overlay trong `live_score_screen.dart`
  - Phụ thuộc: không

## 2. Video khác theo API suggestions

- [x] 2.1 Thêm model và repository `suggestions`. Tiêu chí: `flutter test --no-pub test/features/match/live_viewer_suggestions_test.dart` → exit 0 (TC-LIVEVIEW-15)
  - Files: tạo `lib/data/models/match_suggestion_model.dart`; sửa `lib/domain/repositories/match_playback_repository.dart`, `lib/data/repositories/api/api_match_playback_repository.dart`; test fake `test/match/match_replay_live_video_box_test.dart`
  - Giao: `MatchSuggestion`, `MatchSuggestionsPage`, `Future<MatchSuggestionsPage> getMatchSuggestions(String matchId, {String? cursor})` cho 2.2 · Nhận: không
  - Chủ file chung: 2.1 giữ `match_playback_repository.dart`
  - Phụ thuộc: không

- [x] 2.2 Viết lại tab "Video khác": bộ lọc 4 viên thuốc, thẻ thumbnail như Web, tải thêm theo cursor. Tiêu chí: `flutter test --no-pub test/features/match/live_viewer_suggestions_test.dart` → exit 0 (TC-LIVEVIEW-04..16)
  - Files: sửa `lib/features/match/widgets/viewer/live_viewer_suggestions.dart`, `lib/features/match/screens/live_score_screen.dart` (chỗ gọi `LiveViewerSuggestions`), `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/match/live_viewer_suggestions_test.dart`
  - Giao: `LiveViewerSuggestions(currentMatchId, onOpen(MatchSuggestion))` · Nhận: 2.1
  - Chủ file chung: 2.2 giữ `live_viewer_suggestions.dart` và hai file arb
  - Phụ thuộc: sau 2.1

## 3. Kiểm tra cuối

- [x] 3.1 Phân tích tĩnh và chạy test thư mục liên quan. Tiêu chí: `flutter analyze --no-pub` trên đúng các file đã sửa của change này → exit 0 (code cũ ở `lib/data`, `lib/domain` có cảnh báo sẵn, ngoài phạm vi); `flutter test --no-pub test/match test/features/match` → exit 0
  - Files: không
  - Phụ thuộc: sau 1.1, 2.2
