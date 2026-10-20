# participant-display Specification

## Purpose
Tên hiển thị của một đội/cặp/VĐV dùng chung một quy tắc với Backend: có tên đội thật thì hiện tên đội; không có thì hiện avatar + tên từng VĐV (chỗ hẹp viết tắt kiểu N. V. An), không tách chuỗi tên đội và không bịa tên đội từ tên người.

## Requirements

### Requirement: Hiển thị TEAM hoặc PLAYERS theo tên đội và VĐV

Hệ thống SHALL hiển thị tên đội khi `teamName` sau khi trim và gộp khoảng trắng không rỗng và không trùng tên của bất kỳ VĐV nào (không phân biệt hoa thường). Trong các trường hợp còn lại hệ thống MUST hiển thị từng VĐV kèm avatar và MUST NOT hiển thị tên đội. Tên đội bóng đá MUST luôn là TEAM khi có tên.

#### Scenario: Đội có tên riêng khác tên VĐV

- **WHEN** `teamName` là `Đội Ánh Dương` và VĐV là `Nguyễn Văn An`
- **THEN** nhãn hiển thị là `Đội Ánh Dương`

#### Scenario: Tên đội trùng tên VĐV

- **WHEN** `teamName` là `nguyễn văn an` và một VĐV có `fullName` là `Nguyễn Văn An`
- **THEN** hệ thống hiển thị PLAYERS và không hiển thị tên đội

#### Scenario: Đội không có tên

- **WHEN** `teamName` là `null` hoặc chỉ có khoảng trắng và đội có hai VĐV
- **THEN** hệ thống hiển thị hai VĐV kèm avatar và không hiển thị tên đội

### Requirement: Viết tắt tên người theo một quy tắc

Hệ thống SHALL viết tắt tên người bằng `abbreviateName`: mỗi chữ trước chữ cuối lấy chữ cái đầu viết hoa kèm ".", chữ cuối giữ nguyên, các phần nối bằng dấu cách. Tên một chữ MUST giữ nguyên. Chuỗi rỗng MUST trả về chuỗi rỗng.

#### Scenario: Viết tắt tên ba chữ

- **WHEN** `abbreviateName` nhận `Nguyễn Thị Minh Khai`
- **THEN** kết quả là `N. T. M. Khai`

#### Scenario: Tên một chữ và tên rỗng

- **WHEN** `abbreviateName` nhận `An` hoặc chuỗi chỉ có khoảng trắng
- **THEN** kết quả là `An` hoặc chuỗi rỗng, không thêm dấu chấm

### Requirement: Chỗ hẹp viết tắt, chỗ rộng hiển thị đầy đủ

Hệ thống SHALL dùng `ParticipantLabel` với `compact` cho sơ đồ nhánh, thẻ trận, lịch sân công khai và BTC, overlay và điều khiển tỉ số. Ở chế độ compact, mỗi VĐV MUST nằm trên một dòng kèm avatar, tên viết tắt, và tên đầy đủ hiện qua Tooltip hoặc nhấn giữ. Danh sách, bảng xếp hạng, kết quả, roster và Excel MUST hiển thị tên đầy đủ. Tên đội MUST NOT bị viết tắt ở mọi chế độ; tên dài MUST được cắt bằng dấu "…" và hiện đầy đủ qua Tooltip.

#### Scenario: Thẻ trận compact hiển thị hai VĐV

- **WHEN** một đội không có tên và có hai VĐV `Nguyễn Văn An`, `Trần Văn Bình` ở chế độ compact
- **THEN** hiển thị hai dòng `N. V. An` và `T. V. Bình` theo `abbreviateName`, mỗi dòng có avatar và Tooltip tên đầy đủ, không tràn khung

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
