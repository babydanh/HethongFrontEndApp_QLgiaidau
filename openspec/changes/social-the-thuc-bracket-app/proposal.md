## Why

Hộp thoại "Tạo trận đấu" trên App chỉ ghép được 2v2 (không có lựa chọn Đơn) và chủ kèo không thể chuyển cả nhóm sang đánh theo sơ đồ (bracket). Cần thêm lựa chọn Đơn/Đôi (mặc định Đôi, không có Đôi nam nữ) và bộ chọn "Thể thức" (Một trận / Bracket) nối với endpoint mới của Backend, giống Web.

## What Changes

- `ClubStandaloneMatchDialog`: thêm bộ chọn Đơn/Đôi, mặc định **Đôi**; `matchType` gửi lên lấy từ lựa chọn này thay vì suy từ số người. Không có Đôi nam nữ.
- Thêm bộ chọn **Thể thức** ("Một trận" / "Bracket") trong hộp thoại, chỉ hiện cho chủ kèo của kèo không thuộc CLB. "Một trận" giữ luồng cũ.
- Chế độ Bracket: chọn 1 trong 4 thể thức, chọn người chơi (mặc định chọn hết người đã vào kèo có tài khoản), bấm "Tạo bracket" → `POST /api/v1/social-sessions/:id/bracket` → đóng hộp thoại và mở màn giải vừa tạo.
- Màn Trận đấu của kèo (`SocialMatchTab`): khi kèo đã có `bracketTournamentId` hiện nút "Xem bracket".
- Model kèo đọc thêm `bracketTournamentId`; repository kèo thêm `createBracket`.
- Chuỗi mới có key ở cả `app_vi.arb` và `app_en.arb`, rồi `flutter gen-l10n`.

## Capabilities

### New Capabilities
- `social-session-bracket-app`: chủ kèo cá nhân tạo bracket từ hộp thoại Tạo trận và mở lại bracket đã tạo trên App.

### Modified Capabilities
- `standalone-match-social-session`: hộp thoại có Đơn/Đôi, mặc định Đôi.

## Impact

- App: `lib/features/community/widgets/club_standalone_match_dialog.dart`, `lib/features/social/widgets/match_tab/social_match_tab.dart`, `lib/features/social/screens/social_detail_screen.dart`, `lib/data/models/social_session_model.dart`, `lib/domain/repositories/social_session_repository.dart`, `lib/data/repositories/api/api_social_session_repository.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; file mới `lib/data/models/social_bracket_model.dart`, `lib/features/social/widgets/match_tab/social_bracket_rules.dart`, `lib/features/social/widgets/match_tab/social_bracket_form.dart`.
- **Backend (HethongBackendApi_QuanlyGiaiDau)**: phụ thuộc `POST /api/v1/social-sessions/:id/bracket` (201 `{ tournamentId, bracketType, matchType, participantCount }`; lỗi 400/403/404/409) và field `bracketTournamentId` ở `GET /api/v1/social-sessions/:id` (change `social-the-thuc-bracket-be`). Không làm trước khi Backend task 1.4 xong.
- **Web (HethongFrontEndWeb_QLgiaidau)**: làm song song cùng hợp đồng (change `social-the-thuc-bracket-web`), không dùng chung code.
- Hộp thoại dùng chung với luồng CLB: luồng CLB cũng có thêm lựa chọn Đơn (Backend đã hỗ trợ `SINGLES`), mặc định vẫn là đánh đôi như hiện tại.

## Out of Scope

- Kèo thuộc CLB: không hiện Thể thức, không tạo bracket.
- Khách không có tài khoản: không đưa vào bracket.
- Sửa/huỷ bracket từ màn kèo, Swiss, nhiều bracket cho một kèo.
- Đổi hoặc bỏ 4 chip `playFormat` của kèo (việc riêng).
- Chạy `flutter run`/`flutter install` riêng; kiểm trên máy thật qua app chung `app-run.py`.
