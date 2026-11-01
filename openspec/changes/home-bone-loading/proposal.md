## Why

Trang chủ App (tab Khám phá > Trận đấu) hiện vòng xoay, bắn request liên tục rồi nhiều lúc không hiện card nào, khác hẳn Web. Audit `main` (commit 7ba458d) cho thấy 4 nguyên nhân gốc, không phải lỗi giao diện đơn lẻ:

1. **Ba đường dữ liệu cho cùng một thứ.** `TournamentSectionList` (`lib/features/home/widgets/tournament_section_list.dart:105-106`) `ref.watch(matchesProvider(t.id))` cho từng giải chỉ để biết giải có trận hợp lệ không. `matchesProvider` (`lib/providers/query_providers.dart:146`) kéo TOÀN BỘ trận của giải (100 trận/trang), giữ socket và tự tải lại mỗi 15 giây (`lib/data/repositories/api/api_match_repository.dart:233-244`). Sau đó `LiveTournamentWithMatchesCard` (`lib/features/explore/widgets/live_tournament_with_matches_card.dart:62-103`) lại gọi `getTournamentMatchesPaged` (4 trận, lọc trạng thái ở server) cho cùng giải. Thêm `homeProjectionProvider` cho banner.
2. **Vòng quét không có trần.** Khi bộ lọc không khớp giải nào (ví dụ "Trực tiếp" mà không có trận live), sentinel gọi `_scanNextPage()` mỗi frame (`tournament_section_list.dart:228`) cho tới khi quét hết mọi giải. Mỗi giải quét thêm là một stream mới (socket + timer 15 giây). Đổi bộ lọc thì `_scanLimit` về 6, provider `autoDispose` bị huỷ rồi tải lại.
3. **Lọc client và lọc server lệch nhau.** Danh sách giải quyết định bằng bộ lọc client trên toàn bộ trận, còn card lại hỏi server theo `status`. Giải qua được bộ lọc client nhưng server trả rỗng thì card chỉ còn phần đầu giải, không có trận: đúng triệu chứng "tải xong không hiện".
4. **Chỉ có vòng xoay.** `home_screen.dart:786`, `home_screen.dart:1261`, `tournament_section_list.dart:182`, `live_tournament_with_matches_card.dart:220`, `leaderboard_screen.dart:144,168,187` dùng `CircularProgressIndicator`; người dùng không thấy hình dạng trang sắp hiện. Repo đã có `ShimmerPlaceholder`/`ShimmerBody` (`lib/features/tournament/widgets/tournament_state_views.dart`) và gói `shimmer`, nhưng chỉ vài màn dùng.

Màn `/matches` (`lib/features/match/screens/matches_list_screen.dart`) có cùng gốc: `getMatches` kéo tối đa 50 trang x 100 trận rồi mới hiện (`api_match_repository.dart:128-158`), và hai pill lọc luôn rỗng (`'finished'`, `'registration'` không bao giờ khớp `MatchModel.status`, vì `_mapMatchStatus` chỉ trả `live/completed/walkover/cancelled/scheduled`).

Web làm đúng hướng: tìm 12 giải mỗi lần, 4 trận mỗi giải, lọc trạng thái ở server, chặn request trùng, làm mới 120 giây (`web/src/app/(public)/matches/page.tsx:179-180, 288-330, 403-470`).

## What Changes

- Thêm bộ skeleton ("bone loading") dùng chung, một nhịp shimmer cho cả vùng, kích thước khớp bố cục thật để không giật layout, tôn trọng "giảm chuyển động" của hệ thống.
- Toàn bộ trang chủ dùng skeleton thay vòng xoay: banner nổi bật, thanh tab trạng thái, danh sách card giải kèm trận (tab Khám phá), danh sách giải (tab Giải đấu), bảng xếp hạng, bài viết cộng đồng, thanh "tải thêm".
- Thêm một nguồn dữ liệu duy nhất cho feed trận trang chủ (`homeMatchFeedProvider`): quét giải theo bước, mỗi giải một lần gọi trang đầu 4 trận lọc ở server, chặn request trùng, giới hạn số request chạy cùng lúc, dừng khi hết giải, làm mới 120 giây và khi kéo để làm mới. Card nhận dữ liệu trang đầu từ feed, chỉ tự gọi API khi bấm trang kế.
- Bỏ `ref.watch(matchesProvider)` khỏi `TournamentSectionList`; thống nhất một hàm ánh xạ trạng thái UI sang tham số server.
- Phân biệt rõ 3 trạng thái hiển thị: đang tải (skeleton), rỗng thật (thông báo), lỗi (thông báo + nút thử lại). Không bao giờ để card trống.
- `/matches`: dùng skeleton, tải theo trang bằng `getPublicMatchesPaged` (có "tải thêm"), sửa bộ pill lọc trạng thái.

## Out of scope

- Không đổi Backend và Web. Dùng nguyên endpoint đang có: `GET /matches` (`status`, `cursor`, `limit`, `tournamentId`, `publicOnly`), `GET /tournaments`, `GET /tournaments/home`. Backend đã nhận `status=LIVE` (`matches.repository.ts:572-574`).
- Không làm skeleton cho các màn khác ngoài trang chủ và `/matches`: chi tiết giải, hồ sơ, bracket, live viewer, đăng ký (theo dõi ở change riêng).
- Không đổi thiết kế card trận, bộ lọc, thứ tự tab, màu sắc.
- Không đổi luồng socket của màn chi tiết giải (`watchByTournament` vẫn giữ nguyên cho màn đó).
- Không thêm package (đã có `shimmer`).
- Không xoá `homeProjectionProvider` (banner vẫn dùng cho badge đăng ký).

## Capabilities

### New Capabilities
- `skeleton-loading`: bộ skeleton dùng chung và quy tắc hiển thị đang tải / rỗng / lỗi cho trang chủ và `/matches`.
- `home-match-feed`: nguồn dữ liệu duy nhất, có trần request, cho feed trận ở trang chủ.

### Modified Capabilities
- Không có (repo chưa có spec chung cho trang chủ).

## Impact

- Code: `lib/features/home/screens/home_screen.dart`, `lib/features/home/widgets/tournament_section_list.dart`, `lib/features/explore/widgets/live_tournament_with_matches_card.dart`, `lib/features/rankings/screens/leaderboard_screen.dart`, `lib/features/match/screens/matches_list_screen.dart`, `lib/providers/query_providers.dart`, `lib/data/repositories/api/api_match_repository.dart`, `lib/domain/repositories/match_repository.dart`; tạo mới `lib/core/widgets/skeleton/`, `lib/providers/home_match_feed_provider.dart`.
- Chuỗi hiển thị mới (nếu có) thêm vào cả `app_vi.arb` và `app_en.arb`.
- Test hiện có phải cập nhật: `test/features/home/tournament_section_list_test.dart`, `test/features/live_tournament_with_matches_card_test.dart`, `test/data/api_match_repository_home_feed_test.dart`.
- Số request mở trang chủ giảm từ (6 giải x tối thiểu 2 lần gọi, lặp mỗi 15 giây) xuống (6 giải x 1 lần, làm mới 120 giây). Số liệu thật chưa đo, task 7.2 đo bằng đếm lời gọi trong test.
- Repo khác: không.
