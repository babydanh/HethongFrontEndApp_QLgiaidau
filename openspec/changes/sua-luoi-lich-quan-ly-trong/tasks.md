# Tasks

## 1. Nguồn trận quản lý

- [x] 1.1 Thêm `watchManagedByTournament(String tournamentId, {String? divisionId})` vào `IMatchRepository`. Trong `ApiMatchRepository`, tách thân stream của `watchByTournament` thành hàm dùng chung, và cho `_getMatchPages` nhận đường dẫn. Stream quản lý gọi `GET /tournaments/:id/manage/matches` với `divisionId`, `activeStageOnly=true` và phân trang theo `nextCursor`; cache dùng khóa riêng. Xong khi: test mới `test/data/api_match_repository_managed_test.dart` (Dio giả) PASS với 3 ca: đúng đường dẫn và query không có `publicOnly`; tải đủ 2 trang theo `nextCursor`; lỗi 403 khi chưa có cache làm stream phát lỗi.
- [x] 1.2 Cập nhật class `_MatchRepository implements IMatchRepository` trong `test/features/ops_schedule_drop_test.dart` cho đủ method mới. Xong khi: `flutter test --no-pub test/features/ops_schedule_drop_test.dart` biên dịch được.
- [x] 1.3 Thêm `managedMatchesWithDivisionProvider` vào `lib/providers/query_providers.dart`. Xong khi: `flutter analyze --no-pub lib/providers` không có lỗi.

## 2. Màn quản lý dùng nguồn quản lý

- [x] 2.1 Đổi mọi chỗ watch/read/invalidate `matchesWithDivisionProvider` trong `organizer_ops_screen.dart`, `schedule_fullscreen_screen.dart`, `tournament_management_camera_section.dart` sang `managedMatchesWithDivisionProvider`. Xong khi: `grep matchesWithDivisionProvider` trong 3 file đó trả 0 dòng.
- [x] 2.2 Bổ sung invalidate `managedMatchesWithDivisionProvider` ở `match_control_notifier.dart:45-49`, `bracket_view_screen.dart:900`, `bracket_diagram_screen.dart:146-147`, `live_match_screen.dart:975`. Xong khi: mỗi chỗ có cả provider cũ lẫn provider quản lý, và `flutter analyze --no-pub` trên 4 thư mục chứa các file đó không có lỗi.
- [x] 2.3 Đổi override trong `test/features/ops_matches_view_toggle_test.dart`, `test/features/ops_schedule_drop_test.dart`, `test/organizer_ops/add_athlete_entry_test.dart` sang provider quản lý. Xong khi: `flutter test --no-pub` 3 file đó PASS.

## 3. Lưới lịch luôn dùng được

- [x] 3.1 `organizer_ops_screen.dart`: ở dạng lưới, không thay lưới bằng thông báo khi 0 trận hoặc khi bộ lọc làm danh sách rỗng; ở dạng danh sách giữ thông báo. Xong khi: test mới trong `test/features/ops_matches_view_toggle_test.dart` PASS: tab Quản lý dạng lưới với 0 trận vẫn tìm thấy `TournamentScheduleCourtGrid` và ô chọn nội dung; dạng danh sách với 0 trận vẫn hiện `opsNoMatches`.
- [x] 3.2 `tournament_schedule_court_grid.dart`: nhánh chưa có sân vẽ ô chọn nội dung phía trên thông báo khi có `divisions`. Xong khi: test mới PASS: 0 sân, 2 nội dung → thấy thông báo chưa có sân và đổi được nội dung.
- [x] 3.3 Bấm chuyển từ danh sách sang lưới đặt bộ lọc về `'all'`; chuyển về danh sách không đổi bộ lọc. Xong khi: test mới PASS: vào màn dạng danh sách (bộ lọc mặc định "Đang đấu") với 1 trận chưa đấu, bấm nút lưới → trận đó hiện trên lưới; bấm về danh sách → bộ lọc vẫn là "Tất cả".

## 4. Cổng xem giải theo visibility

- [x] 4.1 `tournament_intro_screen.dart`: ở cả 2 chỗ tính `isClubRestricted` (`:157-162`, `:503-508`), chỉ chặn khi `visibility == 'PRIVATE'`; bỏ `isClubTournament`, `isClubLite`, `communityId` khỏi điều kiện chặn. Giữ nguyên phần kiểm thành viên CLB, người tạo, admin và mã mời. Xong khi: test mới `test/features/tournament_intro_access_test.dart` PASS với 3 ca: giải CLB `PUBLIC` + khách → hiện nội dung; giải CLB `PRIVATE` + khách → màn chặn; giải CLB `PRIVATE` + thành viên `JOINED` → hiện nội dung.

## 5. Kiểm chứng tổng

- [x] 5.1 `flutter analyze --no-pub` trên `lib/data/repositories/api`, `lib/domain/repositories`, `lib/providers`, `lib/features/organizer_ops`, `lib/features/tournament`, `lib/features/bracket`, `lib/features/live` không có lỗi mới; `flutter test --no-pub` các file test ở 1.1, 1.2, 2.3, 3.1, 3.2, 3.3, 4.1 và `test/features/public_bracket_view_test.dart` đều PASS.
- [ ] 5.2 Smoke trên máy thật (sau khi Backend có route quản lý và `.env` có `APP_API_KEY`): đăng nhập BTC, mở tab Quản lý của một giải nháp, lưới hiện đủ trận như Web; đăng xuất, mở một giải CLB `PUBLIC`, xem được nội dung. Xong khi: có ảnh chụp màn hình qua `adb exec-out screencap -p` cho cả 2 bước.
