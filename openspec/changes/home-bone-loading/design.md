## Context

Feed trận trang chủ hiện có ba lớp dữ liệu chồng nhau cho mỗi giải (xem proposal, mục Why). Web chỉ có một lớp: lấy trang giải, lấy 4 trận mỗi giải với `status` ở server, có cờ chặn request đang bay. Mục tiêu: App dùng đúng mô hình đó, và mọi trạng thái tải hiển thị bằng skeleton.

Skill áp dụng khi apply: `flutter-architect` (cấu trúc provider/widget), `pixel-perfect-responsive` (skeleton khớp kích thước thật từ điện thoại tới tablet), `fluid-animations` (shimmer một controller, `RepaintBoundary`, không animation theo từng phần tử), `flutter-add-widget-test`.

## Goals / Non-Goals

**Goals**
- Mỗi giải trong feed có đúng 1 lần gọi API để mở trang; không timer 15 giây theo giải; request trùng bị chặn.
- Có trần cứng: số giải quét mỗi bước, số request chạy cùng lúc, số bước tự động khi không có kết quả.
- Skeleton đúng hình dạng, không giật layout khi dữ liệu về.
- Cùng một bộ quy tắc lọc trạng thái cho danh sách giải, card và `/matches`.

**Non-Goals**
- Realtime điểm số trên card trang chủ. Hiện card trang chủ không cần điểm cập nhật từng giây; trận live cập nhật theo chu kỳ 120 giây hoặc kéo làm mới (giống Web). Socket vẫn dùng ở màn live/chi tiết giải.

## Decisions

### D1. Một provider feed thay cho `matchesProvider` theo giải
`homeMatchFeedProvider` là `Notifier` (Riverpod 3) có khóa `HomeMatchFeedQuery({MatchStatusFilter status, List<String> tournamentIds})`. Không có `query` tìm kiếm: `_searchQueries[0]` của trang chủ không bao giờ được gán nên ô tìm theo giải ở tab Khám phá luôn rỗng; tìm kiếm thật nằm ở màn tìm kiếm toàn cục. Feed giữ:
- `opened`: id giải đã mở theo thứ tự.
- `pages`: `Map<tournamentId, FeedPage>` với `FeedPage { List<MatchModel> items, String? nextCursor, FeedPageStatus status(loading|ready|empty|error) }`.
- `isScanning`: có một bước quét đang chạy; `hasMore` (còn giải chưa mở); `visibleIds` (giải đã có trang đầu hợp lệ); `hasError`.
Hành vi:
- `loadMore()` mở thêm tối đa 6 giải. Mỗi giải gọi `getTournamentMatchesPaged(limit: 4, status: <ánh xạ>)` qua `fetchCursorPageWhere` (đã có, `lib/core/utils/cursor_pagination.dart`) với `accept: isRenderablePublicMatch`.
- Chạy tối đa 3 request cùng lúc (hàng đợi trong notifier). Một giải đang bay thì không gọi lại.
- Giải có trang đầu rỗng sau khi lọc: đánh dấu `empty`, KHÔNG hiện card.
- Tự quét tiếp chỉ khi chưa có card nào và còn giải, tối đa 4 bước liên tiếp không có thao tác người dùng; sau đó dừng với nút "Tải thêm" (dùng key `homeGlobalSearchLoadMore` có sẵn). Cuộn gần cuối danh sách thì gọi `loadMore()` (một lần mỗi lần chạm sentinel, có cờ chặn).
- Làm mới: `Timer` 120 giây và khi app resume (gộp thành một lần, bỏ qua nếu chưa quá 1,5 giây, như Web `matches/page.tsx:306-320`), giữ dữ liệu cũ hiển thị trong lúc tải (stale-while-revalidate), lỗi thì giữ dữ liệu cũ.
- Đổi `status`/`query` tạo key mới; dữ liệu cũ của key trước giữ trong cache sống (keepAlive 60 giây) để chuyển qua lại không tải lại.
Phương án đã cân nhắc:
- *Giữ `matchesProvider`, chỉ thêm trần quét*: vẫn tải toàn bộ trận mỗi giải và poll 15 giây, vẫn lệch lọc client/server. Bỏ.
- *Dùng `getPublicMatchesPaged` toàn cục (như tìm kiếm)*: trả trận rời, mất nhóm theo giải mà card hiện có. Bỏ cho trang chủ; dùng cho `/matches` (D5), nơi đã là danh sách phẳng nhóm theo tên giải ở client.
- *Thêm endpoint Backend gộp giải + trận*: đúng về lâu dài nhưng đổi Backend/Web, ngoài phạm vi. Ghi lại làm đề xuất riêng.

### D2. Card nhận dữ liệu, không tự mở trang đầu
`LiveTournamentWithMatchesCard` thêm tham số `initialPage` (từ feed). Trang đầu hiển thị ngay; chỉ khi bấm "trang sau" mới tự gọi API. Giữ `fetchCursorPageWhere` cho trang sau. Khi `didUpdateWidget` đổi giải/status thì nhận `initialPage` mới, không tự gọi.

### D3. Một hàm ánh xạ trạng thái
`lib/core/utils/match_status_filter.dart`: `MatchStatusFilter` (enum `live/scheduled/completed/all`) với `toServerParam()` (`ONGOING`/`SCHEDULED`/`COMPLETED`/null) và `accepts(MatchModel)` dùng đúng ngữ nghĩa với `_mapMatchStatus`. Danh sách giải, card và `/matches` đều dùng; xoá bản sao `if` trong `tournament_section_list.dart:133-146` và `matches_list_screen.dart:148`.

### D4. Skeleton dùng chung
`lib/core/widgets/skeleton/` (thêm `TournamentBannerCardSkeleton` cho tab Giải đấu và `TournamentMatchRowsSkeleton` dùng trong card khi tải trang kế):
- `SkeletonScope`: bọc `Shimmer.fromColors` MỘT lần cho cả vùng (màu `colors.bgSurface`/`colors.bgCard`, đã có ở `ShimmerBody`). Khi `MediaQuery.disableAnimationsOf(context)` thì hiển thị khối tĩnh (không shimmer).
- Khối nguyên tử: `SkeletonBox({width,height,radius})`, `SkeletonLine`, `SkeletonCircle`.
- Khối ghép theo trang: `HomeBannerSkeleton` (cao bằng `_bannerSlotHeight`), `HomeStatusTabsSkeleton`, `TournamentMatchesCardSkeleton` (đầu giải + 3 hàng trận, theo biến thể live ngang / lịch / kết quả), `TournamentListItemSkeleton`, `LeaderboardRowSkeleton`, `SocialPostSkeleton`, `MatchRowSkeleton`.
- Mỗi khối ghép dùng `RepaintBoundary`, `const` tối đa, số phần tử cố định (3 card, 6 hàng) để không tính toán theo dữ liệu.
- Chỉ phần nội dung chờ dữ liệu là skeleton; thanh lọc, tiêu đề ghim, thanh điều hướng vẫn là thật (người dùng đổi bộ lọc được ngay).
Phương án đã cân nhắc: dùng `ShimmerPlaceholder` hiện có nguyên trạng. Giữ lại và dùng làm cơ sở, nhưng nó chưa có scope một nhịp, chưa có chế độ giảm chuyển động. Mở rộng thay vì viết lại; `ShimmerBody` của màn chi tiết giải giữ nguyên.

### D5. `/matches`
Tải qua `getPublicMatchesPaged(limit: 20, status, search, categoryId, startDate, endDate)` theo cursor (tìm kiếm debounce 400 ms), "tải thêm" khi cuộn gần cuối; skeleton `MatchRowSkeleton` lần đầu và ở chân danh sách; làm mới nền (2 phút, chỉ khi chưa cuộn qua trang đầu) không bật lại skeleton khi danh sách đang có dữ liệu. Lọc sân/môn vẫn ở client. Pill trạng thái dùng `MatchStatusFilter` (D3): còn ba pill Đang diễn ra / Sắp diễn ra / Đã kết thúc; "Vừa kết thúc" (trùng nghĩa) và "Đăng ký" (không áp cho trận) bỏ khỏi `/matches`.

### D6. Ba trạng thái hiển thị
Quy ước chung `AsyncSection`: `loading` -> skeleton; `empty` -> thông báo (có sẵn `l10n.noLiveMatches`/`noUpcomingMatches`/`homeNoCompletedMatches`); `error` -> thông báo + nút thử lại (`l10n.homeMatchesLoadError`, `homeGlobalSearchRetry` đã có). Loại bỏ nhánh render card không có trận.

## Risks / Trade-offs

- Mất cập nhật điểm tức thời trên card trang chủ (15 giây -> 120 giây). Giảm nhẹ: kéo để làm mới; mục "Trực tiếp" làm mới 30 giây khi tab đang mở và có card live (hằng số đặt tên, có thể chỉnh).
- Đổi hợp đồng `LiveTournamentWithMatchesCard` (thêm `initialPage`): cập nhật test hiện có và các chỗ dùng card (tìm bằng `ripwire uses` trước khi sửa).
- Thiếu `.env` trên máy cloud nên không chạy app thật được: kiểm chứng bằng widget test + đếm lời gọi bằng repository giả; xem trên điện thoại khi người dùng chạy.
- Chưa đo được số request thật trước/sau; task 7.2 ghi số đếm trong test làm bằng chứng.

## Migration Plan

Không có dữ liệu cần migrate. Thay thế một lần trong cùng nhánh; không dùng cờ tính năng.

## Open Questions

- "Trực tiếp" làm mới 30 giây hay giữ 120 giây? Mặc định kế hoạch: 30 giây khi có card live.
- Banner nổi bật có cần skeleton riêng khi `tournamentsProvider` đang tải, hay dùng chung `HomeBannerSkeleton`? Mặc định: dùng chung.

## Khác biệt Web và App (đã đối chiếu code, 2026-11-01)

Hai bên dùng chung Backend nhưng ba tab Trực tiếp / Sắp diễn ra / Đã kết thúc ở trang chủ ra nội dung khác nhau vì frontend khác nhau, không phải do dữ liệu:

| | Web (`web/src/app/home/page.tsx`) | App (`lib/features/home`) |
|---|---|---|
| Nguồn trận | MỘT lần `GET /matches?status=ONGOING,SCHEDULED,COMPLETED,FINISHED,DONE,ENDED&publicOnly=true&limit=1000`, rồi chia ba tab theo `status` ở client | Quét từng giải trong `tournamentsProvider`, mỗi giải gọi trang đầu 4 trận theo `status` của tab |
| Giải nào hiện | Chỉ 3 giải đầu (`HOME_TOURNAMENTS_LIMIT = 3`), mỗi giải 4 trận (`HOME_MATCHES_PER_TOURNAMENT = 4`), theo thứ tự nhóm của 1000 trận mới cập nhật nhất | Mọi giải có trận khớp, mở dần 6 giải mỗi bước, theo thứ tự danh sách giải |
| Lọc trận giả/chưa rõ đội | Tab Sắp diễn ra: bỏ BYE và yêu cầu đủ hai đội có tên. Tab Trực tiếp: chỉ bỏ BYE và trận đã kết thúc. Tab Đã kết thúc: chỉ bỏ BYE. KHÔNG lọc `isMock` | `isRenderablePublicMatch` ở cả ba tab: bỏ BYE, đội mock (`team1IsMock`/`team2IsMock`/VĐV `isMock`), nhãn TBD/CHỜ XÁC ĐỊNH/ĐANG CHỜ và đội không có id |
| Tải thêm | Không có trên trang chủ (xem đủ ở `/matches`) | Cuộn gần cuối thì mở thêm giải |

Backend: `GET /matches` công khai chỉ giới hạn theo giải công khai (`publicTournamentSql`); nó chỉ loại trận mock khi truy vấn theo `userId` (`matches.repository.ts` khoảng dòng 640-700). Vì vậy việc "chặn mock" nằm ở App (`lib/core/utils/match_visibility.dart`), Web không chặn: trận có đội mock hoặc TBD ở tab Trực tiếp / Đã kết thúc hiện trên Web nhưng không hiện trên App. Hai chỗ lệch còn lại là giới hạn 3 giải x 4 trận của Web và thứ tự giải.

Change này KHÔNG đổi chính sách chặn mock của App (đó là quyết định sản phẩm, hàm có chủ đích và có test). Nếu muốn App giống Web thì chỉ cần nới `isRenderablePublicMatch` cho tab Trực tiếp / Đã kết thúc, hoặc ngược lại thêm lọc `isMock` cho Web; cần người dùng chốt.
