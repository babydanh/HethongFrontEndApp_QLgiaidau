# participant-display Specification

## Purpose
Tên hiển thị của một đội/cặp/VĐV dùng chung một quy tắc với Backend: có tên đội thật thì hiện tên đội; không có thì hiện avatar + tên từng VĐV (chỗ hẹp viết tắt kiểu N. V. An), không tách chuỗi tên đội và không bịa tên đội từ tên người.

## Requirements

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

### Requirement: Viết tắt tên người theo một quy tắc

Hệ thống SHALL viết tắt tên người bằng `abbreviateName`: mỗi chữ trước chữ cuối lấy chữ cái đầu viết hoa kèm ".", chữ cuối giữ nguyên, các phần nối bằng dấu cách. Tên một chữ MUST giữ nguyên. Chuỗi rỗng MUST trả về chuỗi rỗng.

#### Scenario: Viết tắt tên ba chữ

- **WHEN** `abbreviateName` nhận `Nguyễn Thị Minh Khai`
- **THEN** kết quả là `N. T. M. Khai`

#### Scenario: Tên một chữ và tên rỗng

- **WHEN** `abbreviateName` nhận `An` hoặc chuỗi chỉ có khoảng trắng
- **THEN** kết quả là `An` hoặc chuỗi rỗng, không thêm dấu chấm

### Requirement: Chỗ hẹp viết tắt, chỗ rộng hiển thị đầy đủ

Hệ thống SHALL dùng `ParticipantLabel` với `compact` cho sơ đồ nhánh, thẻ trận, lịch sân, overlay và điều khiển tỉ số. Ở PLAYERS, mỗi bên MUST là một dòng: tối đa 2 avatar chồng nhau và tên các VĐV nối bằng " / "; compact viết tắt bằng `abbreviateName`, tên đầy đủ qua Tooltip hoặc nhấn giữ. Danh sách, bảng xếp hạng, kết quả, roster và Excel MUST hiển thị tên đầy đủ. Tên đội MUST NOT bị viết tắt; tên dài cắt bằng "…" kèm Tooltip.

#### Scenario: Thẻ trận compact hiển thị hai VĐV

- **WHEN** một đội không có tên và có hai VĐV `Nguyễn Văn An`, `Trần Văn Bình` ở chế độ compact
- **THEN** hiển thị đúng một dòng `N. V. An / T. V. Bình` kèm hai avatar chồng nhau, Tooltip là tên đầy đủ, không tràn khung

#### Scenario: Avatar không có ảnh

- **WHEN** VĐV `Nguyễn Văn An` không có `avatarUrl`
- **THEN** avatar hiện chữ `N`, không hiện `NA`

#### Scenario: Tên đội dài ở danh sách

- **WHEN** tên đội dài hơn chiều rộng khung ở chế độ đầy đủ
- **THEN** tên được cắt bằng "…" và Tooltip hiển thị tên đầy đủ, không hiển thị viết tắt

### Requirement: Nguồn VĐV từ API ưu tiên `players`

Adapter `toParticipantPlayers` SHALL đọc `players[]` trước. Khi `players` thiếu hoặc rỗng (endpoint hoặc Backend cũ), adapter MUST dựng VĐV từ `members`/`rosters` (có tài khoản) và `guestNames` (khách, avatar null). Adapter MUST NOT dựng VĐV bằng cách tách `teamName`.

#### Scenario: API trả `players`

- **WHEN** participant có `players` với hai phần tử có `slot` 1 và 2
- **THEN** danh sách VĐV lấy đúng hai phần tử đó theo thứ tự slot

#### Scenario: Backend cũ không có `players`

- **WHEN** participant không có `players`, có `members` một người và `guestNames` một khách
- **THEN** danh sách có hai VĐV, người khách có `isGuest` true và `avatarUrl` null

#### Scenario: Không có VĐV và không có tên đội

- **WHEN** participant không có `players`, `members`, `guestNames` và `teamName` là `null`
- **THEN** nhãn hiển thị `Chưa xác định` (key `matchNotDetermined`) và không sinh tên giả như "Đội {id}" hay "VĐV"

### Requirement: Không tự sinh hoặc gửi tên đội giả

App MUST NOT tách tên đội theo `/`, `&`, `-`, `·` để đoán VĐV, MUST NOT ghép tên đội từ tên người, và MUST NOT gửi tên VĐV vào `teamName` khi đăng ký hoặc nhập roster. Khi không có tên đội, App MUST gửi `teamName` rỗng hoặc bỏ field.

#### Scenario: Ghép cặp ở màn Lite

- **WHEN** Backend trả nhãn cặp từ hai tên VĐV
- **THEN** snackbar hiển thị hai tên đầy đủ nối bằng " / ", và không có tên nào được gửi lên làm `teamName`

#### Scenario: Đăng ký đôi không đặt tên đội

- **WHEN** BTC ghép cặp không nhập tên đội
- **THEN** request gửi `teamName` rỗng hoặc không có field, không chứa tên hai VĐV

### Requirement: Định danh và nhóm không dựa vào chuỗi hiển thị

Bảng xếp hạng, gán sự kiện, nhận diện cặp và điều khiển trận MUST dùng ID đội hoặc ID VĐV. Chuỗi hiển thị MUST NOT được dùng để gom nhóm, so khớp side hay quyết định quyền thao tác.

#### Scenario: Hai đội trùng tên hiển thị

- **WHEN** hai đội trong cùng bảng có cùng chuỗi hiển thị
- **THEN** bảng xếp hạng vẫn tách hai dòng theo ID và không gộp nhóm

#### Scenario: Đội không có tên trong bảng xếp hạng

- **WHEN** một đội không có tên đội nhưng có ID và hai VĐV
- **THEN** đội vẫn được hiển thị đúng dòng theo ID và hiện hai VĐV của đội đó

### Requirement: Chuỗi hiển thị dùng i18n có ở mọi file .arb

Mọi chuỗi hiển thị mới hoặc được dùng lại trong ParticipantLabel MUST có key i18n trong `app_vi.arb` và `app_en.arb` cùng tên key. Change này MUST NOT thêm chuỗi UI hard-code.

#### Scenario: Dùng lại key có sẵn

- **WHEN** ParticipantLabel cần chuỗi fallback khi không có tên và không có VĐV
- **THEN** dùng key `matchNotDetermined` đã có ở cả `app_vi.arb` và `app_en.arb`

#### Scenario: Thiếu key ở một ngôn ngữ

- **WHEN** một key chỉ có ở `app_vi.arb`
- **THEN** change không được coi là hoàn tất cho đến khi key có ở `app_en.arb` và `gen-l10n` chạy thành công

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
