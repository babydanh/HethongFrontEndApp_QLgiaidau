## 1. Luật quyền thuần

- [x] 1.1 Thêm `isTournamentStaff` vào luật live/khoá ADMIN và hàm gom id giải nhân sự. Tiêu chí: `flutter test --no-pub test/domain/live_control_access_test.dart test/domain/admin_scoring_lock_test.dart test/domain/tournament_manage_access_test.dart` → exit 0 (TC-APP-STAFF-SCORE-01..05; đỏ trước khi sửa)
  - Files: sửa `lib/domain/services/live_control_access.dart`, `lib/domain/services/tournament_manage_access.dart`, 3 file test trên
  - Giao: `canControlTournamentLive({..., bool isTournamentStaff = false})`, `isAdminScoringLocked({..., bool isTournamentStaff = false})`, `Set<String> scoringStaffTournamentIds(TournamentWorkspace? workspace)` · Nhận: (không)
  - Chủ file chung: 1.1 giữ các file trên
  - Phụ thuộc: (không)

## 2. Nối vào màn hình

- [x] 2.1 Truyền cờ nhân sự ở màn live, màn giải, màn bracket. Tiêu chí: `flutter test --no-pub test/domain` → exit 0
  - Files: sửa `lib/features/match/screens/live_score_screen.dart`, `lib/features/tournament/screens/tournament_intro_screen.dart`, `lib/features/bracket/screens/bracket_view_screen.dart`
  - Giao: (không) · Nhận: chữ ký ở 1.1
  - Chủ file chung: 2.1 giữ ba màn trên
  - Phụ thuộc: sau 1.1

## 3. Kiểm tra

- [x] 3.1 Typecheck và test liên quan. Tiêu chí: `dart analyze` trên các file đã sửa → exit 0; test ở 1.1 → exit 0
