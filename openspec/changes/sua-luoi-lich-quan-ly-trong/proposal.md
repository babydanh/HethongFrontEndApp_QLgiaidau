# Proposal

## Why

Lưới lịch trong màn quản lý giải trên App trống và không thao tác được. Có hai nguyên nhân:

- Màn quản lý lấy trận bằng nguồn công khai: `GET /matches?tournamentId&divisionId&publicOnly=true` (`lib/data/repositories/api/api_match_repository.dart:1358-1362`). Backend bỏ hết trận của giải riêng tư hoặc đang `DRAFT`/`PENDING_APPROVAL`/`SUSPENDED`/`CANCELLED`, nên ban tổ chức (BTC) thấy 0 trận đúng lúc cần xếp lịch.
- Khi có 0 trận, màn Vận hành thay cả lưới bằng một dòng thông báo (`lib/features/organizer_ops/screens/organizer_ops_screen.dart:1836-1843`). Ở chế độ lưới, ô chọn nội dung phía trên bị ẩn (`:263-265`) vì lưới tự có ô chọn riêng, nên mất luôn ô chọn nội dung, nút xếp lịch tự động và nút toàn màn hình. Ngoài ra, khi người dùng bấm chuyển từ danh sách sang lưới (`:744`), bộ lọc vẫn là `'ongoing'` (`:62`, `:275`), nên lưới chỉ có trận đang đấu và thường cũng trống (`:1983-1990`).

## What Changes

- Màn quản lý lấy trận từ route quản lý mới có đăng nhập `GET /tournaments/:id/manage/matches` (do change Backend cùng đợt thêm), thay cho nguồn công khai. Các màn bị đổi: màn Vận hành, lịch toàn màn hình, phần camera trong quản lý. Màn công khai (bracket công khai, bảng chéo, trang chủ, xem giải) giữ nguồn cũ.
- Ghi lịch, đổi trận, thao tác bracket hoặc live từ màn quản lý phải làm mới cả nguồn trận quản lý, để lưới không giữ dữ liệu cũ.
- Ở chế độ lưới, lưới luôn hiện kể cả khi có 0 trận hoặc bộ lọc làm danh sách rỗng, kèm ô chọn nội dung và các nút thao tác.
- Bấm chuyển từ danh sách sang lưới thì bộ lọc về "Tất cả".
- Không có sẵn khóa ứng dụng (`APP_API_KEY`) hoặc không có quyền BTC (403) thì màn hiện lỗi có nút thử lại, không hiện như "chưa có trận".
- Chuẩn hóa cổng xem giải ở màn giới thiệu giải (`lib/features/tournament/screens/tournament_intro_screen.dart:155-230`, `:502-585`) theo luật chung của đợt này: chỉ `visibility = PRIVATE` mới chặn người ngoài. Giải CLB để `PUBLIC` thì ai cũng xem được, giống Backend sau change `tran-quan-ly-khoa-matches`. Hiện App chặn mọi giải có `communityId` hoặc là CLB lite, bất kể công tắc công khai.

## Capabilities

### New Capabilities

- `organizer-schedule-workspace`: không gian xếp lịch của BTC trên App, gồm nguồn trận quản lý, lưới lịch theo sân và bộ lọc trận trong màn Vận hành.
- `tournament-view-access`: luật App dùng để quyết định người dùng có được xem trang giới thiệu của một giải hay không.

### Modified Capabilities

(không có)

## Out of scope

- Không đổi màn công khai và nguồn trận công khai (`GET /matches?...&publicOnly=true`).
- Không thêm hay đổi API Backend trong repo này. Route quản lý và việc khóa `GET /matches` nằm ở change `tran-quan-ly-khoa-matches` của repo Backend.
- Không sửa lỗ `GET /matches?userId=X`; sẽ tách change riêng.
- Không đổi luật phân quyền BTC; App chỉ hiển thị kết quả Backend trả về.
- Không đổi luật đăng ký: giải CLB vẫn chỉ cho thành viên CLB đăng ký. Không đổi hay xóa luồng mã mời cũ.
- Không đổi cấu hình `.env`.

## Impact

- Backend: phụ thuộc route `GET /tournaments/:id/manage/matches` (JWT + `x-app-key`, quyền `isManager`), response `{ data, meta: { nextCursor, hasMore, ... } }`, nhận `divisionId`, `activeStageOnly`, `cursor`, `limit`. Backend phải deploy trước bản App này.
- Web: change `tran-quan-ly-khoa-matches` chuyển trang quản lý Web sang cùng route. Không phụ thuộc thứ tự giữa Web và App.
- Code App bị ảnh hưởng: `lib/domain/repositories/match_repository.dart`, `lib/data/repositories/api/api_match_repository.dart`, `lib/providers/query_providers.dart`, `lib/features/organizer_ops/screens/organizer_ops_screen.dart`, `lib/features/tournament/screens/schedule_fullscreen_screen.dart`, `lib/features/tournament/screens/tournament_management_camera_section.dart`, `lib/providers/match_control_notifier.dart`, `lib/features/bracket/screens/bracket_view_screen.dart`, `lib/features/bracket/screens/bracket_diagram_screen.dart`, `lib/features/live/screens/live_match_screen.dart`, `lib/features/tournament/screens/tournament_intro_screen.dart`.
- Backend chuẩn hóa luật xem giải theo `visibility` (trang chi tiết, danh sách khám phá `GET /tournaments/public`, phòng live, feed trận). App sẽ thấy giải CLB `PUBLIC` trong danh sách khám phá mà không cần đổi code danh sách.
- Test bị ảnh hưởng: `test/features/ops_matches_view_toggle_test.dart`, `test/features/ops_schedule_drop_test.dart` (class `_MatchRepository implements IMatchRepository`), `test/organizer_ops/add_athlete_entry_test.dart`.
