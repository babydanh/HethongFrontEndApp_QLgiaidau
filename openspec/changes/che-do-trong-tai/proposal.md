## Why

Trọng tài đã nhận lời (bảng `tournamentReferees`, `ACCEPTED`) hiện không vào được màn quản lý giải trên App: guard thăm dò `GET /manage/participants` và bị 403. Khi Backend mở endpoint đó cho trọng tài (che email/sđt), guard cũ sẽ cho trọng tài vào nguyên màn BTC với đủ 8 tab và mọi nút ghi. Người dùng đã duyệt "Chế độ Trọng tài" (hợp đồng chung 2026-11-26): dùng chung route quản lý, giao diện lọc theo vai do Backend trả về.

## What Changes

- Đọc vai quản lý từ `GET /tournaments/:id?manage=true` → `data.manageRole` (`MANAGER` | `REFEREE`); thiếu trường thì coi là `MANAGER` (Backend cũ), giá trị lạ thì coi là `REFEREE` (đóng chặt). 401/403/404 = không có quyền (404: giải DRAFT/PENDING với trọng tài).
- Gom luật quyền vào một chỗ thuần ở `lib/domain/services/manage_role_access.dart` (vai, tab được thấy, hành động được làm).
- Guard nhận vai: trọng tài vào được `/organizer/tournaments/:id/manage`; route `/ops`, các route con ghi của `/manage` (`teams`, `draw`, `bracket`, `swiss-pairing`) và `/ops/bracket` chỉ dành cho BTC, kể cả vào bằng deep link.
- Hub quản lý: trọng tài thấy 6 tab (Tổng quan, Nội dung, VĐV, Bảng đấu, Lịch thi đấu, Kết quả); ẩn Camera, Cài đặt, menu ba chấm, nút vòng đời giải, banner xác nhận lại kết quả, mọi nút sửa thông tin. Đầu trang có nhãn "Trọng tài" và một dải thông báo quyền.
- Trong tab: Nội dung, VĐV chỉ xem (không thêm/sửa/xoá, không duyệt, không check-in, không mở hồ sơ sửa được); Bảng đấu không sửa sơ đồ nhưng vẫn chấm điểm trận theo luồng cũ; Kết quả chỉ nhập điểm trận chưa chốt (hộp sửa giờ/sân/thời lượng vẫn mở); Lịch thi đấu kéo thả đổi giờ/sân/thời lượng/hoán đổi đầy đủ, nhưng ẩn tạo sân, giờ sân, xếp lịch tự động/AI, bản nháp, gán trọng tài, thao tác đặc biệt. Ghi lịch của trọng tài chỉ gửi `courtId`, `courtName`, `courtAddress`, `scheduledAt`, `matchConfig.durationMinutes`, không bao giờ có khoá `refereeId`.
- Lối vào: tab Hoạt động của dashboard thêm nhóm "Giải làm trọng tài" mở thẳng trang quản lý.
- Không đổi: luật chấm điểm `canControlTournamentLive` / `score-access`, luồng mã `REF-…` (`/referee`, `isTokenReferee`).

## Capabilities

### New Capabilities

- `tournament-referee-mode`: màn quản lý giải theo vai (BTC / trọng tài) trên App: ai vào được, thấy tab nào, làm được thao tác ghi nào.

### Modified Capabilities

(không)

## Impact

- Code: `lib/domain/services/`, `lib/domain/repositories/tournament_repository.dart`, `lib/data/repositories/api/api_tournament_repository.dart`, `lib/providers/tournament_manage_access_provider.dart`, `lib/features/tournament/widgets/tournament_manager_guard.dart`, `tournament_management_dispatcher.dart`, `lib/core/router/app_router.dart`, hub quản lý và các tab con, `organizer_ops_screen.dart`, `tournament_schedule_court_grid.dart`, `dashboard_screen.dart`, `lib/l10n/app_vi.arb` + `app_en.arb`.
- API: dùng thêm `GET /tournaments/:id?manage=true` (đã có, Backend thêm `manageRole`). Không thêm endpoint.
- Phụ thuộc Backend: endpoint đọc (`?manage=true`, `/manage/participants`, `/courts`, `/venues`, `/manage/matches`) phải cho trọng tài `ACCEPTED`; `PATCH /matches/:id/schedule` nhận trường giờ/sân và `matchConfig.durationMinutes` của trọng tài (Backend commit 5381bd11, nhánh `che-do-trong-tai`). Trước khi Backend lên, trọng tài vẫn bị 403 như cũ (không vỡ).
