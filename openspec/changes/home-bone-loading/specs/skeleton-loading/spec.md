## ADDED Requirements

### Requirement: Trang chủ SHALL hiển thị skeleton khi đang tải thay vì vòng xoay
Khi dữ liệu của một vùng trang chủ chưa về lần đầu, App MUST hiển thị skeleton có hình dạng và kích thước khớp nội dung thật của vùng đó (banner, thanh tab trạng thái, card giải kèm trận, danh sách giải, bảng xếp hạng, bài viết cộng đồng). App MUST NOT dùng `CircularProgressIndicator` làm trạng thái tải chính của các vùng này. Thanh lọc, tiêu đề ghim và thanh điều hướng SHALL vẫn là thành phần thật và dùng được trong lúc tải.

#### Scenario: Mở tab Khám phá lần đầu
- **WHEN** người dùng mở trang chủ và `tournamentsProvider` chưa có dữ liệu
- **THEN** vùng banner hiển thị `HomeBannerSkeleton` cao bằng ô banner thật, thanh tab trạng thái và thanh lọc môn hiển thị thật, phần danh sách hiển thị 3 `TournamentMatchesCardSkeleton`

#### Scenario: Dữ liệu về, không giật layout
- **WHEN** dữ liệu về và skeleton được thay bằng nội dung thật
- **THEN** vị trí cuộn và chiều cao của thanh lọc không đổi, chỉ vùng nội dung được thay

#### Scenario: Lỗi tải lần đầu
- **WHEN** lần tải đầu của một vùng thất bại và chưa có dữ liệu cũ
- **THEN** skeleton biến mất, vùng đó hiển thị thông báo lỗi kèm nút thử lại; skeleton không quay vô hạn

### Requirement: Skeleton SHALL dùng một nhịp shimmer và tôn trọng giảm chuyển động
Mỗi vùng skeleton MUST dùng đúng một `SkeletonScope` (một animation chung). Khi hệ thống bật giảm chuyển động (`MediaQuery.disableAnimationsOf`), skeleton MUST hiển thị tĩnh, không shimmer.

#### Scenario: Một nhịp cho cả vùng
- **WHEN** một vùng skeleton có nhiều khối con
- **THEN** cây widget của vùng đó chứa đúng một `Shimmer` và các khối con không tự tạo animation

#### Scenario: Bật giảm chuyển động
- **WHEN** `disableAnimations` là true
- **THEN** skeleton hiển thị khối màu tĩnh và không có animation chạy

### Requirement: Trạng thái rỗng, lỗi và tải SHALL tách biệt
Một vùng danh sách MUST ở đúng một trong ba trạng thái: đang tải (skeleton), rỗng thật (thông báo rỗng), lỗi (thông báo kèm nút thử lại). Vùng đã có dữ liệu mà làm mới nền MUST giữ dữ liệu cũ, không quay lại skeleton.

#### Scenario: Rỗng thật sau khi tải xong
- **WHEN** feed đã quét hết giải và không giải nào có trận khớp bộ lọc
- **THEN** hiển thị thông báo rỗng của bộ lọc đó, không có skeleton và không có card trống

#### Scenario: Làm mới nền khi đã có dữ liệu
- **WHEN** chu kỳ làm mới chạy và danh sách đang hiển thị card
- **THEN** các card vẫn hiển thị, không xuất hiện skeleton toàn danh sách

#### Scenario: Làm mới nền thất bại
- **WHEN** lần làm mới nền thất bại và đã có dữ liệu
- **THEN** dữ liệu cũ vẫn hiển thị và không hiện thông báo lỗi chiếm chỗ

### Requirement: Màn danh sách trận `/matches` SHALL hiển thị skeleton và tải theo trang
`/matches` MUST hiển thị `MatchRowSkeleton` ở lần tải đầu, tải trang kế khi cuộn gần cuối, và MUST NOT tải toàn bộ trận trước khi hiển thị. Các pill lọc trạng thái MUST chỉ gồm giá trị mà `MatchModel.status` có thể nhận.

#### Scenario: Mở danh sách trận
- **WHEN** người dùng mở `/matches`
- **THEN** hiển thị skeleton, sau đó 20 trận đầu; mỗi lần cuộn gần cuối mới gọi trang kế bằng cursor

#### Scenario: Lọc "Đã kết thúc"
- **WHEN** người dùng chọn pill "Đã kết thúc" và có trận `completed`
- **THEN** danh sách hiển thị các trận `completed`; pill không bao giờ cho kết quả rỗng chỉ vì sai giá trị trạng thái

#### Scenario: Không có trận nào
- **WHEN** bộ lọc không khớp trận nào sau khi tải xong
- **THEN** hiển thị thông báo `matchesTryChangeFilter`, không skeleton
