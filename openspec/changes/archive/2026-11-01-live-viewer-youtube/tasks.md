## 1. Header widgets

- [x] 1.1 Tiêu đề + hàng nút kiểu YouTube. Tiêu chí: `flutter test --no-pub test/features/match/live_viewer_header_test.dart` → exit 0
  - Files: tạo `lib/features/match/widgets/viewer/live_viewer_header.dart`; test `test/features/match/live_viewer_header_test.dart`
  - Giao: `LiveViewerHeader({required String title, required String subtitle, required VoidCallback onMore, required int cheerCount, required VoidCallback onCheer, required VoidCallback onShare, VoidCallback? onOpenTournament, String? tournamentLabel})` · Nhận: (không)
  - Chủ file chung: 1.1 giữ file header
  - Phụ thuộc: không

## 2. Video khác

- [x] 2.1 Danh sách gợi ý trận. Tiêu chí: `flutter test --no-pub test/features/match/live_viewer_suggestions_test.dart` → exit 0
  - Files: tạo `lib/features/match/widgets/viewer/live_viewer_suggestions.dart`; test `test/features/match/live_viewer_suggestions_test.dart`
  - Giao: `pickLiveSuggestions(List<MatchModel> matches, {required String currentMatchId}) → List<MatchModel>`; `LiveViewerSuggestions({required String tournamentId, required String currentMatchId, required void Function(MatchModel) onOpen})` · Nhận: `matchesProvider(tournamentId)` có sẵn
  - Phụ thuộc: không

## 3. Chuỗi hiển thị

- [x] 3.1 Khoá i18n mới ở cả vi và en rồi `flutter gen-l10n`. Tiêu chí: `flutter gen-l10n` → exit 0
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; code sinh `lib/l10n/app_localizations*.dart`
  - Chủ file chung: 3.1 giữ các file l10n
  - Phụ thuộc: sau 1.1, 2.1 (biết đủ khoá cần)

## 4. Ráp vào màn live

- [x] 4.1 `_buildViewerState` dùng header, hai tab, tấm Xem thêm, thanh trên video; số cổ vũ. Tiêu chí: `flutter analyze --no-pub lib/features/match` → không lỗi mới
  - Files: sửa `lib/features/match/screens/live_score_screen.dart` (`build` ~dòng 673-760, `_buildViewerState` 2324-2613, thêm trạng thái cổ vũ gần dòng 186-236)
  - Nhận: `LiveViewerHeader`, `LiveViewerSuggestions`, khoá i18n 3.1
  - Phụ thuộc: sau 1.1, 2.1, 3.1

## 5. Kiểm

- [x] 5.1 `flutter analyze --no-pub lib/features/match test/features/match` và `flutter test --no-pub` các test match liên quan → exit 0; xem trên máy thật qua hot reload
  - Phụ thuộc: sau 4.1
