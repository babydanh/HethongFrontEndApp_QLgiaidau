# group-stage-assignment Specification

## Purpose
Cho phép BTC xem và quản lý phân bảng vòng bảng theo từng nội dung giải, đồng bộ cấu hình với Backend trước hoặc sau khi sinh sơ đồ.

## Requirements

### Requirement: Đọc cấu hình phân bảng an toàn
App MUST đọc `groupsConfig` từ cấu hình vòng của division đã chọn, chỉ hiển thị participant hợp lệ thuộc division đó, và chịu được cấu hình thiếu hoặc sai dạng. `numGroups` dùng cấu hình division, rồi `tournamentConfig.numberOfGroups`, cuối cùng mặc định 1; `teamsAdvancing` dùng cấu hình division, rồi `tournamentConfig.teamsAdvancingPerGroup`, cuối cùng mặc định 2.

#### Scenario: Mở lại cấu hình đã lưu
- **WHEN** division có bốn nhóm đã lưu và participant hợp lệ được gán vào các nhóm
- **THEN** màn hình hiện đủ bốn nhóm với đúng participant đã lưu và các participant còn lại ở “Chưa xếp”

#### Scenario: Cấu hình thiếu hoặc sai dạng
- **WHEN** cấu hình nhóm không có hoặc không phải object/list hợp lệ
- **THEN** màn hình tạo các nhóm theo số nhóm đã resolve và đưa mọi participant hợp lệ vào “Chưa xếp” mà không crash

### Requirement: Lựa chọn số nhóm bảo toàn phân công
Bộ chọn MUST sinh số nhóm từ 1 đến số nhóm tối đa có ít nhất hai participant hợp lệ mỗi nhóm, đồng thời MUST luôn chứa số nhóm đang cấu hình. Khi giảm số nhóm, participant ở nhóm bị loại MUST chuyển về “Chưa xếp”; các nhóm còn lại MUST giữ nguyên thứ tự và participant.

#### Scenario: Đổi bốn nhóm thành hai
- **WHEN** BTC đổi từ bốn nhóm xuống hai
- **THEN** hai nhóm đầu giữ nguyên thứ tự và participant; participant ở hai nhóm bị loại chuyển về “Chưa xếp”

#### Scenario: Số participant lẻ và cấu hình hiện tại vượt giới hạn
- **WHEN** có bảy participant hợp lệ và số nhóm hiện tại là bốn
- **THEN** các lựa chọn hợp lệ không vượt quá ba nhưng vẫn có lựa chọn bốn để giữ giá trị đang lưu

### Requirement: Sắp xếp participant bằng kéo-thả hoặc menu
Mỗi participant MUST có thể kéo bằng thao tác nhấn giữ giữa “Chưa xếp” và nhóm, giữa các nhóm, và chèn vào vị trí trước participant khác. Bảng MUST tự cuộn khi kéo gần mép; menu chuyển nhóm MUST cung cấp thao tác thay thế không cần kéo.

#### Scenario: Kéo participant vào nhóm và đổi thứ tự
- **WHEN** BTC kéo participant chưa xếp vào vị trí giữa hai participant trong nhóm khác
- **THEN** participant được gán đúng nhóm và thứ tự chèn đó

#### Scenario: Chuyển participant không dùng kéo-thả
- **WHEN** BTC chọn “Chuyển sang bảng…” rồi chọn nhóm đích
- **THEN** participant chuyển sang cuối nhóm đích và không xuất hiện đồng thời ở nhóm cũ

### Requirement: Khóa sửa khi vòng bảng đã bắt đầu
Màn phân bảng MUST ở trạng thái chỉ đọc nếu bất kỳ trận vòng bảng nào đã bắt đầu hoặc có điểm/kết quả, đồng thời MUST nêu lý do khóa và không cho kéo, đổi số nhóm hoặc lưu.

#### Scenario: Trận vòng bảng đang diễn ra
- **WHEN** division có trận vòng bảng đang diễn ra hoặc đã có kết quả
- **THEN** các thao tác sửa bị vô hiệu hóa và lý do khóa được hiển thị

#### Scenario: Chưa có trận bắt đầu
- **WHEN** division chưa có trận vòng bảng hoặc mọi trận đều chưa bắt đầu và chưa có kết quả
- **THEN** BTC có thể sửa và lưu phân bảng

### Requirement: Lưu cấu hình division và đồng bộ sơ đồ
Khi lưu, App MUST PATCH cấu hình division với `isConfigOverride: true` và `roundConfig` hiện tại được giữ nguyên ngoài `groupsConfig` cập nhật. App MUST ngăn lưu trùng và làm mới dữ liệu division, bracket, matches sau khi PATCH thành công. Nếu đã có trận vòng bảng nhưng chưa trận nào bắt đầu, App MUST gọi sinh sơ đồ lại với đúng `divisionId` và `allowReset: true`.

#### Scenario: Lưu phân bảng mới khi sơ đồ chưa đấu
- **WHEN** BTC lưu cấu hình mới cho division đã có các trận vòng bảng chưa bắt đầu
- **THEN** App gửi PATCH đúng payload, sinh lại sơ đồ với `allowReset: true` và làm mới dữ liệu division/bracket/matches

#### Scenario: PATCH thất bại
- **WHEN** Backend từ chối PATCH cấu hình
- **THEN** bản nháp quay về cấu hình cũ, không gọi sinh lại sơ đồ và snackbar hiện thông điệp lỗi từ Backend

#### Scenario: Sinh lại sơ đồ thất bại sau khi lưu cấu hình
- **WHEN** PATCH thành công nhưng Backend từ chối sinh lại sơ đồ
- **THEN** cấu hình đã lưu vẫn được giữ, dữ liệu được làm mới và snackbar hiện lỗi sinh sơ đồ từ Backend
