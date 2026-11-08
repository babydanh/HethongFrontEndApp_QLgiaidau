## ADDED Requirements

### Requirement: Model trận đọc cờ trận bị bỏ quên từ Backend
Hệ thống SHALL đọc `isStaleLive` và `lastActivityAt` từ JSON trận, không tự tính ngưỡng thời gian, và giữ `isLive` nguyên vẹn.

#### Scenario: Backend gửi cờ
- **WHEN** JSON trận ONGOING có `isStaleLive: true` và `lastActivityAt` là ISO string
- **THEN** `MatchModel.isStaleLive` là `true`, `lastActivityAt` là thời điểm đó và `isLive` vẫn là `true`

#### Scenario: Backend cũ thiếu key
- **WHEN** JSON trận không có `isStaleLive` và `lastActivityAt`
- **THEN** `isStaleLive` là `false` và `lastActivityAt` là `null`

### Requirement: Người xem thấy Tạm dừng thay vì LIVE cho trận bị bỏ quên
Hệ thống SHALL không hiện nhãn LIVE và không đếm vào bộ lọc live cho trận có `isStaleLive`, mà hiện nhãn "Tạm dừng" trung tính.

#### Scenario: Bộ lọc live
- **WHEN** danh sách có một trận ONGOING bình thường và một trận ONGOING `isStaleLive`
- **THEN** `MatchStatusFilter.live` chỉ nhận trận bình thường

#### Scenario: Thẻ trận
- **WHEN** thẻ trận được dựng cho trận live có `isStaleLive`
- **THEN** thẻ hiện "Tạm dừng" và không hiện "LIVE"; trận live bình thường vẫn hiện "LIVE"

#### Scenario: Màn live theo giải
- **WHEN** giải có trận live bình thường và trận stale
- **THEN** trận stale nằm ở nhóm "Tạm dừng", không vào nhóm và số đếm LIVE

### Requirement: BTC được nhắc chốt hoặc hủy trận bị bỏ quên
Hệ thống SHALL hiện lời nhắc cho BTC trên trận `isStaleLive`, nêu số giờ chưa cập nhật khi có `lastActivityAt`, và không thêm nút mới.

#### Scenario: Có lastActivityAt
- **WHEN** trận stale có `lastActivityAt` cách hiện tại 14 giờ
- **THEN** lời nhắc nêu 14 giờ và gợi ý kết thúc hoặc hủy trận

#### Scenario: Trận không stale
- **WHEN** trận live bình thường
- **THEN** không có lời nhắc

#### Scenario: Thông báo MATCH_STALE_LIVE
- **WHEN** BTC bấm thông báo `MATCH_STALE_LIVE` có `matchId`
- **THEN** App mở màn xem trận đó
