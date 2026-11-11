## ADDED Requirements

### Requirement: Đồng BTC và trọng tài được mời có nút bấm điểm
Hệ thống SHALL hiện nút bấm điểm (màn live, sơ đồ ở màn giải, màn bracket) cho người dùng là đồng BTC hoặc trọng tài đã nhận lời của giải, kể cả khi tài khoản có vai trò ADMIN; ADMIN không thuộc nhân sự giải SHALL vẫn bị khoá như trước.

#### Scenario: ADMIN kiêm đồng BTC
- **WHEN** tài khoản ADMIN không tạo giải nhưng có giải trong `coOrganizerTournaments`
- **THEN** màn live hiện nút bấm điểm và màn bracket không khoá bấm điểm

#### Scenario: Trọng tài cấp giải
- **WHEN** người dùng có giải trong `refereeTournaments` mở sơ đồ ở màn giải
- **THEN** các trận cho phép bấm điểm

#### Scenario: ADMIN ngoài giải
- **WHEN** tài khoản ADMIN không tạo giải và không là nhân sự của giải
- **THEN** nút bấm điểm vẫn ẩn
