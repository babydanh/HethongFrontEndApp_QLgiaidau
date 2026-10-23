## 1. Cổng quyền chấm điểm theo giải (App Flutter, một chuỗi tuần tự)
- [x] 1.1 Hàm thuần `canControlTournamentLive` (TDD: test đỏ trước), cùng quy tắc Web. Tiêu chí: `flutter test --no-pub test/domain/live_control_access_test.dart` → exit 0
  - Files: tạo `lib/domain/services/live_control_access.dart`; test `test/domain/live_control_access_test.dart`
  - Giao: `bool canControlTournamentLive({String? userId, required bool isAdmin, String? createdBy, String? refereeId, required bool? scoreAccess})` · Nhận: (không)
  - Chủ file chung: 1.1 giữ `live_control_access.dart`
  - Phụ thuộc: không
- [x] 1.2 Provider `matchScoreAccessProvider` (FutureProvider.family<bool?, String>, null khi lỗi) gọi `GET /matches/:id/score-access`; nối vào `live_score_screen.dart` thay `auth.canScore` ở `canOpenScoring` và tiêu đề bàn trọng tài (giữ nhánh Super Lite). Tiêu chí: `flutter test --no-pub test/match/match_score_access_provider_test.dart` → exit 0; `flutter analyze --no-pub lib/features/match lib/providers/match_score_access_provider.dart lib/domain/services/live_control_access.dart` → 0 lỗi mới
  - Files: tạo `lib/providers/match_score_access_provider.dart`; sửa `lib/features/match/screens/live_score_screen.dart:~646-650,~683`; test `test/match/match_score_access_provider_test.dart`
  - Giao: `final matchScoreAccessProvider = FutureProvider.family<bool?, String>` · Nhận: hàm từ 1.1
  - Chủ file chung: 1.2 giữ `live_score_screen.dart`
  - Phụ thuộc: sau 1.1

## 2. Khung video chưa có tín hiệu
- [x] 2.1 `_NoSignalBox` bọc `AspectRatio(16/9)` (TDD: widget test đỏ trước). Tiêu chí: `flutter test --no-pub test/match/live_score_video_panel_test.dart` → exit 0
  - Files: sửa `lib/features/match/widgets/live_video_box.dart:~103-130`; test `test/match/live_score_video_panel_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: 2.1 giữ `live_video_box.dart`
  - Phụ thuộc: không

## 3. Kiểm tra cuối
- [x] 3.1 Analyze thư mục đã sửa và các test liên quan. Tiêu chí: `flutter test --no-pub test/domain/live_control_access_test.dart test/match/match_score_access_provider_test.dart test/match/live_score_video_panel_test.dart` → exit 0; `openspec validate app-chan-nut-cham-diem-theo-giai --strict` → exit 0
  - Phụ thuộc: sau 1.2, 2.1
