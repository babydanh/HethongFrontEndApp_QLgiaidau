# Design

## Context

- Hợp đồng chung đã duyệt: `GET /tournaments/:id?manage=true` trả `data.manageRole?: 'MANAGER' | 'REFEREE'`, người khác 403. Xem proposal.md (Why).
- App hiện tại: `tournamentManageAccessProvider` (bool) thăm dò `/manage/participants`; guard bọc route `/manage` và `/ops`. Hub dựng 8 tab cố định theo enum riêng `_HubTab`; `TabController.length = 8`, nhiều chỗ nhảy tab bằng `_HubTab.x.index`.
- Route con của `/manage` (`teams`, `draw`, `bracket`, `swiss-pairing`) và `/ops/bracket` được go_router dựng thành trang riêng, KHÔNG đi qua builder của route cha, nên guard cha không che được deep link.
- Kéo thả lịch gửi `PATCH /matches/:id/schedule`; khay chờ và ô trống gửi kèm `matchConfig.durationMinutes`; sheet sửa nhanh gửi kèm `refereeId` + `matchConfig`. Hợp đồng chốt (Backend 5381bd11): trọng tài chỉ được gửi `courtId`, `courtName`, `courtAddress`, `scheduledAt` (được null) và `matchConfig` có đúng khoá `durationMinutes`; khoá khác, kể cả `refereeId: null`, → 403. Giải DRAFT/PENDING → 404 với trọng tài.

## Goals / Non-Goals

**Goals:** một hàm quyền thuần, test được, là nguồn duy nhất cho tab + hành động theo vai; guard dùng vai từ Backend; trọng tài không thấy, không bấm được, không deep link được vào thao tác BTC.

**Non-Goals:** không đổi luật chấm điểm (`canControlTournamentLive`, `score-access`, `scoringStaffTournamentIds`); không đụng luồng mã `REF-…`; không làm lại Backend; không thêm chế độ cho người chỉ được gán `match.refereeId`.

## Decisions

### 1. Hàm quyền ở `lib/domain/services/manage_role_access.dart`

```dart
enum ManageRole {
  manager,
  referee;

  /// Parses `data.manageRole` of `GET /tournaments/:id?manage=true`.
  /// Missing/empty → manager (older Backend only answered managers);
  /// 'MANAGER' → manager; 'REFEREE' or any unknown value → referee.
  static ManageRole fromApi(Object? raw);
}

enum ManageHubTab { overview, divisions, athletes, bracket, schedule, results, camera, settings }

enum ManageAction {
  editTournament,   // info/branding/contact/fee edits, lifecycle buttons, reconfirm, overflow menu
  editDivisions,
  editParticipants, // add/import/pair/approve/kick/check-in/detail sheet
  editBracket,      // draw, seeds, group moves, stage ops
  manageCourts,     // create court CTA, court hours
  autoSchedule,     // auto/AI schedule and drafts
  assignReferee,    // pick a match's referee (`refereeId`); never sent by a referee
  moveMatchSlot,    // drag/drop/swap time, court and duration
  scoreOpenMatch,   // existing scoring flow for matches not finalized
}

List<ManageHubTab> visibleHubTabs(ManageRole role);
bool canManageAction(ManageRole role, ManageAction action);
```

Trọng tài chỉ có `moveMatchSlot` và `scoreOpenMatch`; BTC có tất cả. Thay vì ma trận lớn, luật là "BTC: mọi thứ; trọng tài: danh sách cho phép" để thêm hành động mới mặc định bị khoá với trọng tài (đóng chặt). Phương án khác: cờ `bool isReferee` rải rác trong từng widget — bỏ, vì không test tập trung được.

### 2. Vai lấy từ repository, không suy ra từ workspace

`ITournamentRepository.getManageRole(String tournamentId) → Future<ManageRole>` (body không có object `data` → `FormatException`, guard hiện "Thử lại" thay vì mặc định BTC) gọi `GET /tournaments/:id?manage=true` với `extra.noCache = true` (quyền không được lấy từ cache khi mạng lỗi). `tournamentManageAccessProvider` đổi thành `FutureProvider.autoDispose.family<ManageRole?, String>`: 401/403/404 → `null`; lỗi khác ném ra để guard hiện "Thử lại". Workspace (`refereeTournaments`) không dùng làm nguồn quyền vì phân trang và có thể chưa tải.

### 3. Guard trả vai qua builder

```dart
TournamentManagerGuard({
  required String tournamentId,
  required Widget Function(BuildContext context, ManageRole role) builder,
  bool managerOnly = false,
})
```

`null` hoặc (`managerOnly` và vai trọng tài) → màn "không có quyền". Route `/ops` và các route con ghi (`/manage/teams|teams/add|teams/edit|draw|bracket|swiss-pairing`, `/ops/bracket`) dùng `managerOnly: true`. Dispatcher bọc hub bằng guard theo vai, và bọc `LiteManagementScreen` (giải CLB Lite, hoặc Super Lite mở workspace Lite) bằng guard `managerOnly` vì giao diện Lite không có chế độ trọng tài; guard để các lối vào chưa có guard (`/admin/tournament/:id`, `/lite-manage/:id`, `/lite/tournaments/:id/manage`) cũng có vai; cùng một provider family nên không gọi API thêm. Hub được key theo vai để `TabController` dựng lại khi vai đổi.

### 4. Hub dựng tab từ `visibleHubTabs(role)`

`_HubTab` thay bằng `ManageHubTab`; mọi chỗ nhảy tab dùng chỉ số trong danh sách đang thấy, tab không có thì bỏ qua (popup bước vòng đời trỏ tới Cài đặt/Camera không làm vỡ chỉ số).

### 5. Ẩn thay vì khoá

Hợp đồng cho "ẩn hoặc khoá". App chọn ẩn mọi nút ngoài quyền (không render), vì màn hình hẹp và dải thông báo đầu trang đã nói rõ trọng tài làm được gì. Không thêm widget khoá riêng.

### 6. Ghi lịch của trọng tài không có `refereeId`

`OrganizerOpsScreen` nhận `manageRole`. Với trọng tài: kéo thả, khay chờ, ô trống, đổi thời lượng hàng loạt giữ nguyên (gửi giờ/sân và `matchConfig.durationMinutes`, Backend cho phép); ô bị khoá không còn "Mở sơ đồ" và "Thao tác đặc biệt" (`editBracket`); hộp sửa nhanh ẩn chọn trọng tài và truyền `refereeId: null`, mà `ApiMatchRepository.updateSchedule` bỏ hẳn khoá null (`'refereeId': ?refereeId`) nên body không có khoá đó; tắt xếp tự động/AI, bản nháp, giờ sân. Tab Kết quả giữ hộp sửa lịch (chỉ gửi giờ/sân/thời lượng). Lưới lịch quyết định CTA "Tạo sân" theo việc chủ màn có trao quyền giờ sân (`onOpenScheduleSettings`) thay vì quyền kéo thả.

## Risks / Trade-offs

- [Backend chưa lên `manageRole`] → thiếu trường coi là BTC, và trọng tài vẫn 403 ở `?manage=true` nên không lọt vào màn BTC.
- [Backend lên nhưng `/courts`/`/venues` chưa mở cho trọng tài] → lưới lịch hiện lỗi tải; không có thao tác sai. Ghi vào báo cáo cho Backend.
- [Trọng tài cũng là đồng tổ chức] → Backend trả `MANAGER` → đủ quyền BTC, đúng Q2.
- [Ẩn nút có thể làm trọng tài không biết vì sao thiếu] → dải thông báo một dòng ở đầu trang.

## Migration Plan

Không có dữ liệu cần chuyển. Gỡ: revert commit; Backend thêm trường không làm App cũ vỡ.
