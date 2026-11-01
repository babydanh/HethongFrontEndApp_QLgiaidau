## ADDED Requirements

### Requirement: Feed trận trang chủ SHALL có một nguồn dữ liệu và mỗi giải tối đa một lần gọi để mở trang
`homeMatchFeedProvider` MUST là nguồn duy nhất cho tab Trận đấu ở trang chủ. Với mỗi giải được quét, feed MUST gọi `getTournamentMatchesPaged` đúng một lần cho trang đầu (4 trận, `status` ánh xạ từ bộ lọc) và MUST NOT tải toàn bộ trận của giải, MUST NOT mở socket hay timer 15 giây theo từng giải. `TournamentSectionList` MUST NOT `ref.watch(matchesProvider)`.

#### Scenario: Mở tab lần đầu
- **WHEN** tab Trận đấu mở với bộ lọc `scheduled` và có 20 giải
- **THEN** feed gọi trang đầu cho 6 giải đầu (tối đa 3 request cùng lúc), tổng 6 lời gọi `getTournamentMatchesPaged`, và 0 lời gọi `getMatches`/`watchByTournament`

#### Scenario: Chặn request trùng
- **WHEN** cùng một giải đang có request trang đầu bay và có thêm yêu cầu `loadMore()`
- **THEN** không phát sinh request thứ hai cho giải đó

#### Scenario: Lỗi một giải
- **WHEN** request của một giải thất bại
- **THEN** giải đó ở trạng thái `error` và có nút thử lại riêng; các giải khác vẫn hiển thị bình thường

### Requirement: Feed SHALL có trần quét và dừng khi hết giải
Feed MUST mở tối đa 6 giải mỗi bước, tối đa 3 request đồng thời, và tối đa 4 bước tự động liên tiếp khi chưa có card nào. Hết giải hoặc hết trần thì feed MUST dừng, không gọi thêm cho đến khi người dùng cuộn hoặc bấm "Tải thêm".

#### Scenario: Bộ lọc không khớp giải nào
- **WHEN** bộ lọc `live` và không giải nào có trận live trong 30 giải
- **THEN** feed dừng sau tối đa 4 bước (24 giải), hiển thị thông báo `noLiveMatches` kèm "Tải thêm"; không còn request nào chạy ngầm

#### Scenario: Hết giải
- **WHEN** feed đã quét hết danh sách giải
- **THEN** `phase` là `exhausted` hoặc `ready` không còn giải chưa quét và không gọi thêm

#### Scenario: Đổi bộ lọc liên tục
- **WHEN** người dùng đổi bộ lọc 3 lần trong 1 giây
- **THEN** chỉ bộ lọc cuối được quét; kết quả đã có của bộ lọc trước được giữ trong cache 60 giây, quay lại thì không gọi lại

### Requirement: Feed SHALL làm mới theo chu kỳ và giữ dữ liệu cũ khi lỗi
Feed MUST làm mới trang đầu của các giải đang hiển thị mỗi 120 giây khi tab đang mở (30 giây khi bộ lọc `live` có ít nhất một card), khi app resume và khi người dùng kéo để làm mới; các kích hoạt cách nhau dưới 1,5 giây MUST gộp thành một lần. Làm mới nền thất bại MUST giữ dữ liệu đang hiển thị.

#### Scenario: Quay lại app
- **WHEN** app resume và `visibilitychange`-tương đương phát hai tín hiệu trong 1 giây
- **THEN** chỉ một lượt làm mới chạy

#### Scenario: Làm mới lỗi
- **WHEN** lượt làm mới thất bại và feed đang có card
- **THEN** các card cũ vẫn hiển thị, không hiện lỗi chiếm chỗ

### Requirement: Một hàm ánh xạ trạng thái SHALL dùng chung cho feed, card và `/matches`
`MatchStatusFilter` MUST là nơi duy nhất ánh xạ bộ lọc UI sang tham số server và sang điều kiện lọc client. Một trận MUST NOT qua bộ lọc client nhưng bị server loại cho cùng bộ lọc, hoặc ngược lại.

#### Scenario: Bộ lọc `completed`
- **WHEN** bộ lọc là `completed` và trận có `status` server `FINISHED`/`ENDED`/`DONE`/`COMPLETED`
- **THEN** tham số gửi server là `COMPLETED` và `accepts` trả true cho trận có `status == 'completed'`

#### Scenario: Bộ lọc `live`
- **WHEN** bộ lọc là `live`
- **THEN** tham số gửi server là `ONGOING` và `accepts` trả true chỉ cho trận `isLive`

#### Scenario: Bộ lọc `all`
- **WHEN** bộ lọc là `all`
- **THEN** không gửi tham số `status` và `accepts` trả true cho mọi trận hiển thị công khai

### Requirement: Card giải SHALL hiển thị ngay trang đầu do feed cấp
`LiveTournamentWithMatchesCard` MUST nhận trang đầu từ feed và hiển thị ngay, không tự gọi API cho trang đầu. Card MUST chỉ tự gọi API khi người dùng chuyển sang trang kế.

#### Scenario: Hiển thị không thêm request
- **WHEN** card được dựng với `initialPage` có 4 trận
- **THEN** 4 trận hiển thị ngay và repository nhận 0 lời gọi

#### Scenario: Bấm trang sau
- **WHEN** người dùng bấm trang sau và `nextCursor` có giá trị
- **THEN** repository nhận đúng 1 lời gọi với cursor đó, trong lúc chờ card hiển thị skeleton hàng trận (không vòng xoay)

#### Scenario: Trang sau rỗng hoặc lỗi
- **WHEN** trang sau không có trận hợp lệ hoặc request lỗi
- **THEN** card giữ trang hiện tại và hiển thị thông báo/nút thử lại, không để vùng trận trống
