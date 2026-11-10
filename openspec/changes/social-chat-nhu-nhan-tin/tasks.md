## 1. Thực hiện

- [x] 1.1 Mốc một lần của giải: sửa `explore_new_tournaments.dart` + test `TC-EXPLORE-MERGE-02`. Tiêu chí: `flutter test --no-pub test/features/home/explore_new_tournaments_test.dart` → exit 0
  - Files: sửa `lib/features/home/widgets/explore_new_tournaments.dart`, `test/features/home/explore_new_tournaments_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 1.1 giữ cả hai
  - Phụ thuộc: không
- [x] 1.2 Chat nhúng: cờ `embedded` và `SocialChatTab`. Tiêu chí: `flutter test --no-pub test/features/social/social_chat_tab_test.dart` → exit 0
  - Files: sửa `lib/features/chat/screens/chat_detail_screen.dart`, `lib/features/social/widgets/chat_tab/social_chat_tab.dart`, `test/features/social/social_chat_tab_test.dart`
  - Giao: `ChatDetailScreen(embedded: bool)` · Nhận: (không)
  - Chủ file chung: 1.2 giữ ba file
  - Phụ thuộc: không
