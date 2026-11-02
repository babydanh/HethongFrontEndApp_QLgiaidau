## 1. Lọc gợi ý
- [x] 1.1 `pickLiveSuggestions` dùng luật Web. Tiêu chí: `flutter test --no-pub test/features/match/live_viewer_suggestions_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/viewer/live_viewer_suggestions.dart:9-25`; test `test/features/match/live_viewer_suggestions_test.dart` (TC-LIVEVIEW-08..10)
  - Giao: `pickLiveSuggestions(List<MatchModel>, {required String currentMatchId}) → List<MatchModel>` (không đổi chữ ký) · Nhận: (không)
  - Chủ file chung: 1.1 giữ cả hai file
  - Phụ thuộc: không
