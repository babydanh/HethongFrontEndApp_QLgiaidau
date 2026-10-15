## ADDED Requirements

### Requirement: Lấy dữ liệu overlay có kiểm soát
App SHALL chỉ gọi `GET /matches/:id/overlay` khi có cờ overlay bật, gọi lúc bật, lúc socket nối lại, khi nhận `score:update` (debounce 1 giây) và mỗi 30 giây, và MUST bỏ phản hồi cũ hơn yêu cầu mới nhất. App MUST NOT tự ghép tên bên, nhãn vòng hay điểm từ `MatchModel` cho hai overlay này.

#### Scenario: Overlay tắt
- **WHEN** cả `h2hOverlayVisible` và `bracketOverlayVisible` đều false
- **THEN** không có yêu cầu nào tới `/matches/:id/overlay` và không có timer chạy

#### Scenario: Hai phản hồi đảo thứ tự
- **WHEN** phản hồi của yêu cầu cũ đến sau phản hồi của yêu cầu mới
- **THEN** nội dung đang hiện giữ nguyên bản mới

#### Scenario: Lỗi mạng hoặc 404
- **WHEN** yêu cầu lỗi hoặc trả 404
- **THEN** giữ khung đang hiện (nếu có), thử lại có backoff, không hiện khung rỗng và không báo lỗi lên màn hình

#### Scenario: Rời màn hình
- **WHEN** người dùng rời màn xem trận
- **THEN** yêu cầu đang bay bị bỏ và timer bị huỷ

### Requirement: Khối H2H đơn và đôi
H2H SHALL hiện đúng `h2h` của phản hồi: logo, tiêu đề `title`, nhãn vòng `round` (ẩn khi null), bên 1 viền xanh và bên 2 viền đỏ, "VS" ở giữa; mỗi bên một hoặc hai avatar chồng nhau theo `avatars`, thiếu ảnh thì chữ cái đầu. H2H MUST NOT hiện seed, ELO hay thành tích.

#### Scenario: Đơn
- **WHEN** `h2h.left.avatars` có một phần tử và `name` "Danh"
- **THEN** hiện một avatar tròn viền xanh và khung tên "Danh"

#### Scenario: Đôi và ghi chú
- **WHEN** một bên có hai avatar và tên "Danh - Luân", hoặc có `note` "(chờ đồng đội)"
- **THEN** hai avatar chồng nhau, tên đúng như server trả, ghi chú hiện cạnh tên

#### Scenario: Ảnh lỗi hoặc thiếu
- **WHEN** `url` null hoặc tải ảnh thất bại
- **THEN** hiện chữ cái đầu `initial` thay ảnh, không văng lỗi

#### Scenario: Không có H2H
- **WHEN** `h2h` là null
- **THEN** không hiện gì

### Requirement: Khối Bracket tối đa bốn cột
Bracket SHALL hiện đúng `columns` của phản hồi (tối đa 4 cột, không cuộn), mỗi thẻ chỉ có tên bên 1, tên bên 2 và ô điểm; ô của bên `won` MUST được tô sáng. Thẻ `live` MUST nổi bật kèm nhãn "ĐANG DIỄN RA", thẻ khác mờ, đường nối của thẻ `litNext` sáng; cột chung kết có cúp. Bracket MUST NOT hiện seed hoặc mã trận.

#### Scenario: Giải 16 cặp đôi, đang xem tứ kết
- **WHEN** phản hồi có 4 cột và một thẻ `live`
- **THEN** hiện đủ 4 cột, thẻ `live` nổi bật, đường tới bán kết và chung kết sáng, tên đôi đúng như server trả

#### Scenario: Chờ kết quả và BYE
- **WHEN** một dòng có `name` null, hoặc "BYE"
- **THEN** hiện "Chờ kết quả" (mờ) hoặc "BYE" và ô điểm trống

#### Scenario: Bracket không hỗ trợ
- **WHEN** `bracket` là null kèm `bracketReason`
- **THEN** nút Bracket trong điều khiển tắt kèm lý do, không hiện gì trên video

### Requirement: Khung cố định co đều
Mỗi overlay SHALL được vẽ trên khung thiết kế cố định (H2H 1320×225, Bracket 1568×882) và co đều theo bề rộng khung chứa video bằng `FittedBox`; MUST NOT reflow chữ theo cỡ màn hình và MUST NOT gây RenderFlex overflow.

#### Scenario: Ba cỡ màn hình
- **WHEN** khung video rộng 320, 390 và 768 logical px
- **THEN** bố cục giữ đúng tỉ lệ, không tràn, không có lỗi layout trong log

#### Scenario: Player đổi tỉ lệ sau khi đọc metadata
- **WHEN** player báo tỉ lệ khác 16/9 sau khi đã hiện overlay
- **THEN** overlay không nhảy hay méo; co theo bề rộng khung chứa

### Requirement: Chuỗi hiển thị có khoá i18n
Chuỗi cố định của App ("ĐANG DIỄN RA", "Chờ kết quả", "VS", lý do tắt nút) SHALL có khoá cùng tên ở `app_vi.arb` và `app_en.arb`; tiêu đề, nhãn vòng và tên bên do server trả MUST giữ nguyên tiếng Việt ở cả hai ngôn ngữ.

#### Scenario: Đổi ngôn ngữ sang English
- **WHEN** App chạy locale `en`
- **THEN** chuỗi cố định theo `app_en.arb` còn tiêu đề "ĐỐI ĐẦU" và nhãn vòng giữ như server trả

#### Scenario: Khoá thiếu một ngôn ngữ
- **WHEN** thêm khoá ở `app_vi.arb` mà thiếu ở `app_en.arb`
- **THEN** `flutter gen-l10n` hoặc kiểm tra khoá báo lỗi trước khi hoàn tất task
