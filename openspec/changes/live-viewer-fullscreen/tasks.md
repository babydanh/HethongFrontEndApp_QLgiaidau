## 1. Chat

- [x] 1.1 `isChatContinuation` + `compact` cho `MatchDiscussionMessage`. Tiêu chí: `flutter test --no-pub test/features/match/live_chat_grouping_test.dart` → exit 0
  - Files: tạo `lib/features/match/widgets/viewer/live_chat_grouping.dart`; sửa `lib/features/match/widgets/match_discussion_message.dart`; test `test/features/match/live_chat_grouping_test.dart`
  - Giao: `bool isChatContinuation({required String userId, required DateTime at, String? olderUserId, DateTime? olderAt})` · Nhận: (không)
  - Phụ thuộc: không
- [x] 1.2 `LiveNewMessagesPill`. Tiêu chí: `flutter test --no-pub test/features/match/live_new_messages_pill_test.dart` → exit 0
  - Files: tạo `lib/features/match/widgets/viewer/live_new_messages_pill.dart`; test `test/features/match/live_new_messages_pill_test.dart`
  - Giao: `LiveNewMessagesPill({required int count, required VoidCallback onTap})` · Nhận: (không)

## 2. Trình phát

- [x] 2.1 Về live + toàn màn hình + chế độ fill. Tiêu chí: `flutter test --no-pub test/features/match/live_video_player_live_edge_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/live_video_player.dart`, `live_video_box.dart`; test `test/features/match/live_video_player_live_edge_test.dart`
  - Giao: `bool isBehindLive({required Duration position, required Duration duration, Duration threshold})`; `LiveVideoPlayer(fill, fullscreen, onToggleFullscreen)`; `LiveVideoBox(fill, fullscreen, onToggleFullscreen)` · Nhận: (không)

## 3. Màn ngang

- [x] 3.1 `LiveLandscapeChat`. Tiêu chí: `flutter test --no-pub test/features/match/live_landscape_chat_test.dart` → exit 0
  - Files: tạo `lib/features/match/widgets/viewer/live_landscape_chat.dart`; test `test/features/match/live_landscape_chat_test.dart`
  - Giao: `LiveLandscapeChat({required List<LiveChatLine> lines, required bool canPost, required TextEditingController controller, required bool sending, required VoidCallback onSend, required VoidCallback onCheer, required VoidCallback onLogin})` · Nhận: (không)

## 4. i18n, báo cáo, ráp màn

- [x] 4.1 Khoá i18n vi/en + gen-l10n; chip Báo cáo ở `LiveViewerHeader`. Tiêu chí: `flutter test --no-pub test/features/match/live_viewer_header_test.dart` → exit 0
  - Files: sửa `lib/l10n/app_vi.arb`, `app_en.arb`, `lib/features/match/widgets/viewer/live_viewer_header.dart`, `test/features/match/live_viewer_header_test.dart`
  - Chủ file chung: 4.1 giữ hai file `.arb`
  - Phụ thuộc: sau 1.2, 3.1
- [x] 4.2 Ráp vào `live_score_screen.dart` (màn ngang, toàn màn hình, chat bám đáy, nhóm tin, báo cáo, trả lại xoay màn hình). Tiêu chí: `flutter test --no-pub test/match/live_score_team_athletes_test.dart` → exit 0
  - Files: sửa `lib/features/match/screens/live_score_screen.dart`
  - Phụ thuộc: sau 1.1, 1.2, 2.1, 3.1, 4.1

## 5. Kiểm

- [x] 5.1 `flutter analyze --no-pub lib/features/match test/features/match` và test thư mục match. Tiêu chí: exit 0
