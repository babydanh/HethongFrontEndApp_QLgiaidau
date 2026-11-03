## 1. Bảng điểm người xem

- [x] 1.1 Đặt bảng điểm người xem ở góc trên trái dưới header. Tiêu chí: `flutter test --no-pub test/match/live_score_header_scoring_test.dart` → exit 0
  - Files: sửa `lib/features/match/screens/live_score_screen.dart:58-61,2314-2319`; test `test/match/live_score_header_scoring_test.dart` (TC-LIVEVIEW-11)
  - Giao: không · Nhận: không
  - Chủ file chung: 1.1 giữ `live_score_screen.dart`
  - Phụ thuộc: không

## 2. Video khác

- [x] 2.1 Thay hộp gradient bằng hàng thumbnail + tên, thêm bộ lọc. Tiêu chí: `flutter test --no-pub test/features/match/live_viewer_suggestions_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/viewer/live_viewer_suggestions.dart`; test `test/features/match/live_viewer_suggestions_test.dart` (TC-LIVEVIEW-12..14)
  - Giao: `bool isLiveSuggestion(MatchModel)` · Nhận: không
  - Chủ file chung: 2.1 giữ `live_viewer_suggestions.dart`
  - Phụ thuộc: không

## 3. Kiểm tra cuối

- [x] 3.1 Phân tích tĩnh và chạy test thư mục liên quan. Tiêu chí: `flutter analyze --no-pub lib/features/match` → exit 0; `flutter test --no-pub test/match test/features/match` → exit 0
  - Files: không
  - Phụ thuộc: sau 1.1, 2.1
