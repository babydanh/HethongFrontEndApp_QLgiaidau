## ADDED Requirements

### Requirement: Bảng điểm khi phát lại theo đúng giây bản ghi
Khi App phát lại bản ghi trận và phản hồi replay có `scoreEvents` không rỗng, bảng điểm trên video MUST lấy `p1SetsWon`, `p2SetsWon` và `scoreDetails` từ sự kiện cuối cùng có `offsetSec` không muộn hơn vị trí hiện tại trên timeline. Trước sự kiện đầu tiên bảng MUST hiện 0-0 không có set nào. App MUST dùng lại widget bảng điểm đang dùng cho phát trực tiếp.

#### Scenario: Phát qua các mốc điểm
- **WHEN** `scoreEvents` có mốc 3s (set 1 đang 5-2) và mốc 6s (set 1 xong 11-7), và vị trí phát lại là 4s
- **THEN** bảng điểm hiện 5-2, chưa ở trạng thái kết thúc

#### Scenario: Trước mốc đầu tiên
- **WHEN** vị trí phát lại là 1s, trước mốc đầu tiên ở 3s
- **THEN** bảng điểm hiện 0-0, không hiện điểm cuối của trận

#### Scenario: Tua lùi
- **WHEN** người xem tua từ 6s về 4s
- **THEN** bảng điểm hiện lại 5-2 ngay

#### Scenario: Từ mốc cuối trở đi
- **WHEN** vị trí phát lại từ mốc cuối trở đi và trận đã kết thúc
- **THEN** bảng điểm hiện điểm cuối ở trạng thái kết thúc

### Requirement: Không có scoreEvents thì giữ hành vi cũ
App MUST giữ nguyên bảng điểm hiện nay khi đang xem trực tiếp, hoặc khi `scoreEvents` vắng mặt hoặc rỗng, và MUST NOT làm phát lại lỗi vì dữ liệu sai dạng.

#### Scenario: Bản ghi cũ chưa có điểm theo thời gian
- **WHEN** phản hồi replay không có `scoreEvents` (hoặc `[]`)
- **THEN** bảng điểm hiện điểm hiện tại của trận như trước

#### Scenario: Một phần tử sai dạng
- **WHEN** `scoreEvents` có phần tử `offsetSec` không phải số hữu hạn không âm, `p1SetsWon`/`p2SetsWon` không phải số nguyên không âm, hoặc `scoreDetails` không phải object, cùng các phần tử hợp lệ
- **THEN** phần tử sai bị bỏ qua, các phần tử hợp lệ vẫn có tác dụng
