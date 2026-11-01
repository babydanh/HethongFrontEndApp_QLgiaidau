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
`homeMatchFeedProvider` là `Notifier` (Riverpod 3) có tham số `({String status, String query})`, giữ:
- `tournaments`: các giải đã quét (`Tournament`), theo thứ tự đầu vào.
- `pages`: `Map<tournamentId, FeedPage>` với `FeedPage { List<MatchModel> items, String? nextCursor, FeedPageStatus status(loading|ready|empty|error) }`.
- `phase`: `loading` (chưa có giải nào xong) | `ready` | `exhausted` (đã quét hết, không có trận) | `error`.
Hành vi:
- `loadMore()` mở thêm tối đa 6 giải. Mỗi giải gọi `getTournamentMatchesPaged(limit: 4, status: <ánh xạ>)` qua `fetchCursorPageWhere` (đã có, `lib/core/utils/cursor_pagination.dart`) với `accept: isRenderablePublicMatch`.
- Chạy tối đa 3 request cùng lúc (hàng đợi trong notifier). Một giải đang bay thì không gọi lại.
- Giải có trang đầu rỗng sau khi lọc: đánh dấu `empty`, KHÔNG hiện card.
- Tự quét tiếp chỉ khi `phase == loading` hoặc (chưa có card nào và còn giải), và tối đa 4 bước liên tiếp không có thao tác người dùng; sau đó dừng ở trạng thái `ready` với nút "Tải thêm". Cuộn gần cuối danh sách thì gọi `loadMore()` (một lần mỗi lần chạm sentinel, có cờ chặn).
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
`lib/core/widgets/skeleton/`:
- `SkeletonScope`: bọc `Shimmer.fromColors` MỘT lần cho cả vùng (màu `colors.bgSurface`/`colors.bgCard`, đã có ở `ShimmerBody`). Khi `MediaQuery.disableAnimationsOf(context)` thì hiển thị khối tĩnh (không shimmer).
- Khối nguyên tử: `SkeletonBox({width,height,radius})`, `SkeletonLine`, `SkeletonCircle`.
- Khối ghép theo trang: `HomeBannerSkeleton` (cao bằng `_bannerSlotHeight`), `HomeStatusTabsSkeleton`, `TournamentMatchesCardSkeleton` (đầu giải + 3 hàng trận, theo biến thể live ngang / lịch / kết quả), `TournamentListItemSkeleton`, `LeaderboardRowSkeleton`, `SocialPostSkeleton`, `MatchRowSkeleton`.
- Mỗi khối ghép dùng `RepaintBoundary`, `const` tối đa, số phần tử cố định (3 card, 6 hàng) để không tính toán theo dữ liệu.
- Chỉ phần nội dung chờ dữ liệu là skeleton; thanh lọc, tiêu đề ghim, thanh điều hướng vẫn là thật (người dùng đổi bộ lọc được ngay).
Phương án đã cân nhắc: dùng `ShimmerPlaceholder` hiện có nguyên trạng. Giữ lại và dùng làm cơ sở, nhưng nó chưa có scope một nhịp, chưa có chế độ giảm chuyển động. Mở rộng thay vì viết lại; `ShimmerBody` của màn chi tiết giải giữ nguyên.

### D5. `/matches`
Tải qua `getPublicMatchesPaged(limit: 20, status, search, startDate, endDate)` theo cursor, "tải thêm" khi cuộn gần cuối; skeleton `MatchRowSkeleton` lần đầu, và dải mỏng khi làm mới nền; không bật lại skeleton khi danh sách đang có dữ liệu. Pill trạng thái dùng `MatchStatusFilter` (D3): "Vừa kết thúc" và "Đã kết thúc" gộp về một giá trị `completed`; pill "Đăng ký" không áp cho trận nên bỏ khỏi `/matches` (trạng thái đăng ký thuộc giải, đã có ở tab Giải đấu).

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
