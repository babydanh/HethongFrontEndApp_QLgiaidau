## Why
Trọng tài được mời ở cấp giải và đồng BTC được mời không thấy nút bấm điểm trên App:
- Sơ đồ ở màn giải chỉ cho bấm điểm khi `canManage` (người tạo, danh sách giải tổ chức/đồng tổ chức), nên trọng tài cấp giải không bao giờ có nút.
- Luật khoá ADMIN (`canControlTournamentLive`, `isAdminScoringLocked`) thiếu ngoại lệ đồng BTC mà Web đã thêm (d874bace), nên tài khoản có vai trò ADMIN kiêm đồng BTC hoặc trọng tài của giải bị giấu nút.

## What Changes
- `live_control_access.dart`: hai hàm nhận thêm `isTournamentStaff` (đồng BTC hoặc trọng tài đã nhận lời của giải); `true` thì được bấm điểm và không bị khoá ADMIN.
- `tournament_manage_access.dart`: hàm thuần `scoringStaffTournamentIds(workspace)` gom id giải từ `coOrganizerTournaments` và `refereeTournaments` của workspace.
- Màn live (`live_score_screen.dart`), màn giải (`tournament_intro_screen.dart`) và màn bracket (`bracket_view_screen.dart`) truyền cờ này.

## Out of scope
- Backend (đã cho đồng BTC/trọng tài quyền ghi qua `score-access`).
- Web; luật khoá ADMIN với người ngoài giải giữ nguyên.

## Capabilities
### New Capabilities
- `app-staff-score-button`: nút bấm điểm cho đồng BTC và trọng tài được mời của giải trên App.

### Modified Capabilities
(không)
