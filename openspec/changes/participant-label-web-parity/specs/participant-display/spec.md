## MODIFIED Requirements

### Requirement: Hiển thị TEAM hoặc PLAYERS theo tên đội và VĐV

Hệ thống SHALL hiển thị tên đội khi `teamName` sau khi trim và gộp khoảng trắng không rỗng, không trùng tên của bất kỳ VĐV nào (không phân biệt hoa thường) và không phải tên ghép các VĐV bằng " / " theo đúng thứ tự (dạng `A / B`, khi có từ hai VĐV). Trong các trường hợp còn lại hệ thống MUST hiển thị từng VĐV kèm avatar và MUST NOT hiển thị tên đội. Tên đội bóng đá MUST luôn là TEAM khi có tên.

#### Scenario: Đội có tên riêng khác tên VĐV

- **WHEN** `teamName` là `Đội Ánh Dương` và VĐV là `Nguyễn Văn An`
- **THEN** nhãn hiển thị là `Đội Ánh Dương`

#### Scenario: Tên đội trùng tên VĐV

- **WHEN** `teamName` là `nguyễn văn an` và một VĐV có `fullName` là `Nguyễn Văn An`
- **THEN** hệ thống hiển thị PLAYERS và không hiển thị tên đội

#### Scenario: Tên đội là tên ghép các VĐV

- **WHEN** `teamName` là `Minh Khang / Hoang Linh` và hai VĐV có `fullName` lần lượt là `Minh Khang`, `Hoang Linh`
- **THEN** hệ thống hiển thị PLAYERS (hai VĐV kèm avatar) và không hiển thị chuỗi `Minh Khang / Hoang Linh` như tên đội

#### Scenario: Đội không có tên

- **WHEN** `teamName` là `null` hoặc chỉ có khoảng trắng và đội có hai VĐV
- **THEN** hệ thống hiển thị hai VĐV kèm avatar và không hiển thị tên đội

#### Scenario: Bóng đá giữ tên đội

- **WHEN** là bóng đá, `teamName` là `FC A / B` và không trùng tên VĐV nào
- **THEN** hệ thống hiển thị TEAM `FC A / B`

### Requirement: Chỗ hẹp viết tắt, chỗ rộng hiển thị đầy đủ

Hệ thống SHALL dùng `ParticipantLabel` với `compact` cho sơ đồ nhánh, thẻ trận, lịch sân công khai và BTC, overlay và điều khiển tỉ số. Ở chế độ PLAYERS, `ParticipantLabel` MUST vẽ một dòng cho mỗi bên: tối đa 2 avatar chồng nhau (avatar không có ảnh hiện đúng 1 chữ cái đầu của tên, in hoa) và một dòng chữ gồm tên các VĐV nối bằng " / "; ở chế độ compact tên MUST viết tắt bằng `abbreviateName`, tên đầy đủ hiện qua Tooltip hoặc nhấn giữ. Danh sách, bảng xếp hạng, kết quả, roster và Excel MUST hiển thị tên đầy đủ. Tên đội MUST NOT bị viết tắt ở mọi chế độ; tên dài MUST được cắt bằng dấu "…" và hiện đầy đủ qua Tooltip.

#### Scenario: Thẻ trận compact hiển thị hai VĐV

- **WHEN** một đội không có tên và có hai VĐV `Nguyễn Văn An`, `Trần Văn Bình` ở chế độ compact
- **THEN** hiển thị đúng một dòng `N. V. An / T. V. Bình` kèm hai avatar chồng nhau, Tooltip là tên đầy đủ, không tràn khung

#### Scenario: Avatar không có ảnh

- **WHEN** VĐV `Nguyễn Văn An` không có `avatarUrl`
- **THEN** avatar hiện chữ `N`, không hiện `NA`

#### Scenario: Tên đội dài ở danh sách

- **WHEN** tên đội dài hơn chiều rộng khung ở chế độ đầy đủ
- **THEN** tên được cắt bằng "…" và Tooltip hiển thị tên đầy đủ, không hiển thị viết tắt

## ADDED Requirements

### Requirement: Loại trùng VĐV khi dựng danh sách

Các adapter dựng VĐV (`toParticipantPlayers`, `participantPlayersFromMemberInfos`, `participantPlayersFromNames`) SHALL chỉ giữ một lần mỗi VĐV: trùng `userId` (khác rỗng), hoặc khách trùng tên sau khi trim, gộp khoảng trắng và không phân biệt hoa thường. Phần tử xuất hiện đầu tiên MUST được giữ và thứ tự các phần tử còn lại MUST không đổi.

#### Scenario: API trả cùng một VĐV nhiều lần

- **WHEN** `players` có 5 phần tử cùng `userId` `u1`
- **THEN** danh sách VĐV có đúng 1 phần tử và thẻ trận hiện một VĐV, không lặp dòng

#### Scenario: Hai VĐV khác nhau cùng tên khác userId

- **WHEN** `players` có hai phần tử `userId` `u1` và `u2` cùng `fullName` `Nguyễn Văn An`
- **THEN** cả hai được giữ (khác tài khoản là hai người)

#### Scenario: Danh sách rỗng

- **WHEN** `players` là `[]`
- **THEN** kết quả là `[]`, không lỗi
