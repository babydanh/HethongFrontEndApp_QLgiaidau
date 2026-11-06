## ADDED Requirements

### Requirement: Một bracket cho mọi màn
App SHALL vẽ sơ đồ loại trực tiếp và nhánh thắng-thua bằng `PlayoffDoubleElimView` ở trang công khai và cả hai màn quản lý; App MUST NOT còn dùng `SingleElimDiagram`, `DoubleElimDiagram` hay `BracketMatchCard`.

#### Scenario: Màn quản lý dùng bracket mới
- **WHEN** người có quyền mở sơ đồ của một nội dung ở hub quản lý hoặc màn sơ đồ toàn màn hình
- **THEN** sơ đồ hiện bằng `PlayoffDoubleElimView`, mỗi trang hai vòng, và khay chờ VĐV (nếu có) nằm phía trên sơ đồ

#### Scenario: Chưa có trận
- **WHEN** nội dung chưa có trận nào
- **THEN** hiện dòng "chưa có sơ đồ" như hiện tại và không ném lỗi

### Requirement: Kéo thả đổi VĐV giữa các ô
Khi bật chế độ sửa, giữ một hàng VĐV 140ms SHALL nhấc hàng đó lên để kéo; thả lên hàng khác SHALL gọi `onSlotDrop(source, target)` đúng một lần với phép toán do `bracketSlotOperation` quyết định (SWAP khi ô đích có người, MOVE khi ô đích trống, ASSIGN/REPLACE khi nguồn là khay chờ). Hàng của trận đang đấu hoặc đã kết thúc (trừ BYE) MUST NOT kéo được và MUST NOT nhận thả; hàng BYE MUST NOT nhận thả.

#### Scenario: Đổi chỗ hai VĐV
- **WHEN** người dùng giữ VĐV A ở trận chưa đấu rồi thả lên VĐV B ở trận chưa đấu
- **THEN** `onSlotDrop` được gọi với nguồn là ô của A và đích là ô của B, và ô đích sáng lên trong lúc rê qua

#### Scenario: Ô bị khóa hoặc BYE
- **WHEN** người dùng giữ VĐV của trận đã kết thúc, hoặc thả lên hàng BYE
- **THEN** không có thao tác nào được gửi và `onSlotDrop` không được gọi

#### Scenario: Thả lỗi
- **WHEN** `onSlotDrop` ném lỗi
- **THEN** hiện thông báo lỗi, sơ đồ mở khóa lại và có thể thao tác tiếp

### Requirement: Chạm-chạm để đổi chỗ
Ở chế độ sửa, chạm một hàng có VĐV SHALL chọn hàng đó (viền nhấn); chạm hàng thứ hai hợp lệ SHALL gọi `onSlotDrop`; chạm lại hàng đã chọn SHALL bỏ chọn. Trong lúc đang cập nhật, App MUST NOT nhận thêm thao tác.

#### Scenario: Chọn rồi đổi
- **WHEN** người dùng chạm VĐV A rồi chạm VĐV B
- **THEN** `onSlotDrop` được gọi một lần và lựa chọn được xóa

#### Scenario: Bấm đúp hai lần liên tiếp
- **WHEN** người dùng chạm B hai lần rất nhanh sau khi chọn A
- **THEN** `onSlotDrop` chỉ được gọi một lần

### Requirement: Kéo tới mép thì lật trang
Khi đang kéo một VĐV và con trỏ ở trong vùng mép trái hoặc phải của sơ đồ liên tục 450ms, bracket SHALL lật sang vòng trước hoặc vòng sau; rời mép SHALL hủy việc đếm. Ở vòng đầu hoặc vòng cuối, mép tương ứng MUST NOT lật.

#### Scenario: Lật sang vòng sau
- **WHEN** người dùng kéo VĐV tới mép phải và giữ 450ms khi chưa ở vòng cuối
- **THEN** cửa sổ chuyển sang vòng kế và VĐV vẫn đang được kéo

#### Scenario: Ở vòng cuối hoặc rời mép sớm
- **WHEN** đang ở vòng cuối, hoặc người dùng rời mép trước 450ms
- **THEN** không lật trang

### Requirement: Thẻ trận ở chế độ sửa
Thẻ SHALL giữ bố cục mẫu C và thêm: hàng BYE ghi "BYE" và không kéo được; viền vàng cho trận chung kết đã xong; chênh ELO nhỏ cạnh điểm khi `eloStatus` là APPLIED; chip "Chấm điểm" ở dòng đầu khi người xem có quyền chấm hoặc là trọng tài của trận đang live. Chạm vào thẻ ở màn quản lý SHALL chạy đúng luồng cũ (chọn kiểu chấm điểm, vào trang live, hoặc popup chi tiết), không mở popup công khai.

#### Scenario: Có quyền chấm điểm
- **WHEN** người có quyền chấm điểm chạm vào trận đã đủ hai bên và không phải BYE
- **THEN** hiện bộ chọn kiểu chấm điểm

#### Scenario: Không có quyền, trận đã xong
- **WHEN** người xem không có quyền chạm vào trận đã kết thúc
- **THEN** hiện popup chi tiết trận và không có chip "Chấm điểm"

### Requirement: Chuyển động và giảm chuyển động
Mọi chuyển động của bracket SHALL kéo dài tối đa 260ms (trừ nhịp lặp của chấm live) và chỉ dùng transform hoặc opacity. Khi `MediaQuery.disableAnimationsOf` là true, bracket MUST hiện thẳng trạng thái cuối và chấm live MUST đứng yên. Trạng thái nghiệp vụ MUST NOT phụ thuộc việc animation đã xong.

#### Scenario: Bình thường
- **WHEN** hai VĐV vừa được đổi chỗ
- **THEN** tên mới trượt vào thay tên cũ trong 200ms và ô không bị khóa sau khi xong

#### Scenario: Giảm chuyển động
- **WHEN** hệ thống bật giảm chuyển động và người dùng lật vòng hoặc đổi chỗ
- **THEN** nội dung đổi ngay lập tức, không có hiệu ứng trượt, mờ hay nhấp nháy

### Requirement: Trang công khai vẫn chỉ xem
Khi không truyền `editing`, bracket MUST NOT dựng `DragTarget` hay `LongPressDraggable`, và chạm vào thẻ SHALL mở popup chi tiết như hiện tại.

#### Scenario: Khách xem bracket
- **WHEN** khách mở tab Bảng đấu của một giải
- **THEN** không hàng nào kéo được, chạm thẻ mở popup chi tiết trận

#### Scenario: Dữ liệu rỗng
- **WHEN** danh sách trận rỗng
- **THEN** không ném lỗi và hiện trạng thái rỗng
