# Design

## Context

Xem proposal.md, mục Why. Hiện trạng liên quan:

- `matchesWithDivisionProvider` (`lib/providers/query_providers.dart:188-199`) gọi `IMatchRepository.watchByTournament`. Provider này được cả màn quản lý lẫn màn công khai dùng (cross table, bracket công khai, live).
- `ApiMatchRepository.watchByTournament` (`lib/data/repositories/api/api_match_repository.dart:220-288`) dựng stream: tải lần đầu, tải lại khi socket báo đổi trận/điểm/trạng thái, tải lại định kỳ 15 giây, lỗi thì giữ dữ liệu đã lưu, chưa có dữ liệu thì phát lỗi. Phân trang cursor nằm ở `_getMatchPages` (`:149-186`), hiện cố định đường dẫn `/matches`.
- `DioClient` tự gắn `Authorization: Bearer` khi có token, và gắn `x-app-key` khi `.env` có `APP_API_KEY`.

## Goals / Non-Goals

**Goals:**
- Màn quản lý dùng route quản lý; màn công khai không đổi.
- Không nhân đôi logic stream (socket, tải lại định kỳ, cache, phân trang).
- Lưới lịch không bao giờ bị thay bằng dòng thông báo ở chế độ lưới.

**Non-Goals:**
- Không đổi màn công khai, không đổi `watchByTournament` công khai.
- Không thêm package.

## Decisions

1. **Thêm `watchManagedByTournament` vào `IMatchRepository`**, cùng chữ ký với `watchByTournament`. Phương án khác là thêm cờ `managed` vào `watchByTournament`. Không chọn vì cờ boolean sẽ chạy qua mọi lời gọi công khai, và dễ có chỗ quên truyền.
2. **Trong `ApiMatchRepository`, tách thân stream của `watchByTournament` thành một hàm riêng nhận hàm tải.** Hai stream công khai và quản lý dùng chung socket, tải lại định kỳ và cách xử lý lỗi. Cache dùng khóa có tiền tố khác nhau (`manage:<tournamentId>-<division|all>`), để dữ liệu quản lý không lẫn vào cache công khai. `_getMatchPages` nhận thêm đường dẫn, mặc định vẫn là `/matches`.
3. **Stream quản lý gọi `GET /tournaments/:id/manage/matches`** với `divisionId` (nếu có), `activeStageOnly=true` (giống Web quản lý), phân trang theo `nextCursor` qua `_getMatchPages`. Không dùng snapshot công khai toàn cục.
4. **Thêm `managedMatchesWithDivisionProvider`** cùng kiểu khóa `({String tournamentId, String? divisionId})`. Ba màn quản lý (`organizer_ops_screen.dart`, `schedule_fullscreen_screen.dart`, `tournament_management_camera_section.dart`) đổi mọi chỗ watch/read/invalidate sang provider này.
5. **Chỗ ghi dùng chung giữa màn quản lý và màn công khai** (`match_control_notifier.dart:45-49`, `bracket_view_screen.dart:900`, `bracket_diagram_screen.dart:146-147`, `live_match_screen.dart:975`) invalidate thêm `managedMatchesWithDivisionProvider` bên cạnh provider cũ. Invalidate một provider không có ai nghe thì không gọi mạng, nên rẻ.
6. **Lưới ở chế độ lưới**: trong `_buildMatchesSliver`, nhánh `matches.isEmpty` chỉ trả thông báo khi đang ở dạng danh sách. Ở dạng lưới thì đi tiếp và truyền danh sách rỗng vào `TournamentScheduleCourtGrid`. Bỏ nhánh `visible.isEmpty` che lưới (`:1983-1992`). Lưới đã vẽ được trường hợp 0 trận (sân trống, khay chờ rỗng). Riêng trường hợp chưa có sân (`tournament_schedule_court_grid.dart:261-279`) hiện chỉ trả một thông báo, nên cũng mất ô chọn nội dung. Nhánh này phải vẽ ô chọn nội dung phía trên thông báo khi có `divisions`.
7. **Bấm chuyển sang lưới** (`:744`): khi đổi sang `grid` thì đặt `_opsMatchFilter = 'all'`. Đổi về `list` thì không đụng bộ lọc.

## Risks / Trade-offs

- [Bản App mới chạy với Backend chưa có route quản lý → 404, màn quản lý lỗi] → Deploy Backend trước. App hiện trạng thái lỗi có nút thử lại, không crash.
- [Thiếu `APP_API_KEY` ở môi trường dev → 403 trên route quản lý] → Đúng với hành vi Backend. Lỗi hiện rõ thay vì "0 trận". Bản phát hành có khóa.
- [Thêm method vào `IMatchRepository` làm hỏng class implement thật trong test (`test/features/ops_schedule_drop_test.dart:47`)] → Cập nhật class đó trong cùng change. Các class `extends Fake` không bị ảnh hưởng.
- [Socket báo đổi trận làm cả hai stream cùng tải lại khi cùng mở] → Hai stream dùng hai đường dẫn khác nhau, mỗi stream vẫn có cờ chống tải chồng sẵn có. Chỉ màn quản lý mở stream quản lý.

## Migration Plan

Thứ tự cả đợt: Backend (change `tran-quan-ly-khoa-matches`) deploy trước, rồi Web (change cùng tên), rồi phát hành App. Web và App không phụ thuộc nhau. Sau khi Backend khóa `GET /matches`, App bản cũ vẫn dùng nguồn công khai như trước nên không vỡ thêm. Rollback App: quay về bản trước, màn quản lý dùng lại nguồn công khai (hành vi cũ). Không có dữ liệu cần chuyển.
