## 0. Review

- [x] 0.1 Cross-check by a fresh-context reviewer. Tiêu chí: no open P0/P1
  - Kết quả: agent flutter-reviewer 2026-11-26: không P0/P1. P2 đã sửa: body thiếu `data` không còn mặc định BTC (TC-REF-MODE-APP-06c); giải CLB Lite qua dispatcher chỉ cho BTC (TC-REF-MODE-APP-12b). P2 "route con `/admin/tournament/:id/*` không guard" không sửa: `app_router.dart:168` đã đẩy người không phải admin ra khỏi `/admin`, admin luôn là BTC. P3 ghi nhận: TC-15 còn mỏng; 404 hiện "không có quyền" cả với giải không tồn tại.

## 1. Luật quyền thuần

- [x] 1.1 `ManageRole`, `ManageHubTab`, `ManageAction`, `visibleHubTabs`, `canManageAction`. Tiêu chí: `flutter test --no-pub test/domain/manage_role_access_test.dart` → exit 0
  - Files: mới `lib/domain/services/manage_role_access.dart`; test mới `test/domain/manage_role_access_test.dart` (TC-REF-MODE-APP-01..04)
  - Giao: chữ ký trong design.md mục 1 · Nhận: (không)
  - Chủ file chung: 1.1 giữ cả hai file
  - Phụ thuộc: không

## 2. Vai từ Backend + guard

- [x] 2.1 `getManageRole` (repository) + `tournamentManageAccessProvider` trả `ManageRole?` + guard có `builder`/`managerOnly`. Tiêu chí: `flutter test --no-pub test/data/api_tournament_manage_role_test.dart` và `test/features/tournament/tournament_manager_guard_test.dart` → exit 0
  - Files: sửa `lib/domain/repositories/tournament_repository.dart`, `lib/data/repositories/api/api_tournament_repository.dart`, `lib/providers/tournament_manage_access_provider.dart`, `lib/features/tournament/widgets/tournament_manager_guard.dart`; test mới `test/data/api_tournament_manage_role_test.dart` (TC-REF-MODE-APP-05, 06, 06b, 06c), viết lại `test/features/tournament/tournament_manager_guard_test.dart` (TC-REF-MODE-APP-07..10, 10b: 404 của giải DRAFT/PENDING = không có quyền)
  - Giao: `Future<ManageRole> getManageRole(String)`; `tournamentManageAccessProvider: FutureProvider.autoDispose.family<ManageRole?, String>`; `TournamentManagerGuard({tournamentId, builder, managerOnly})` · Nhận: 1.1
  - Chủ file chung: 2.1
  - Phụ thuộc: 1.1

## 3. Route + dispatcher

- [x] 3.1 Route `/ops`, `/ops/bracket`, các route con ghi của `/manage` dùng `managerOnly`; dispatcher bọc hub bằng guard và truyền vai. Tiêu chí: `flutter test --no-pub test/features/tournament/referee_mode_routes_test.dart` → exit 0; test router cũ trong `test/features/tournament_management_hub_screen_test.dart` → exit 0
  - Files: sửa `lib/core/router/app_router.dart`, `lib/features/tournament/widgets/tournament_management_dispatcher.dart`; test mới `test/features/tournament/referee_mode_routes_test.dart` (TC-REF-MODE-APP-11, 12, 12b: giải CLB Lite chỉ BTC); cập nhật override trong `test/features/tournament_management_hub_screen_test.dart`, `test/features/tournament_management_reload_test.dart`
  - Giao: (không đổi chữ ký dispatcher) · Nhận: 2.1
  - Chủ file chung: 3.1 giữ `app_router.dart`
  - Phụ thuộc: 2.1

## 4. Hub theo vai

- [x] 4.1 Hub nhận `role`, dựng tab theo `visibleHubTabs`, ẩn menu ba chấm, nút sửa, nút vòng đời, xác nhận lại kết quả với trọng tài; nhãn "Trọng tài" + dải thông báo (chuỗi mới ở `app_vi.arb` + `app_en.arb`, `flutter gen-l10n`). Tiêu chí: `flutter test --no-pub test/features/tournament/referee_mode_hub_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_hub_screen.dart`, `lib/features/tournament/screens/tournament_management_section_screen.dart` (cờ `readOnly` của `TournamentLifecycleCard`), `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, code sinh `lib/l10n/app_localizations*.dart`; test mới `test/features/tournament/referee_mode_hub_test.dart` (TC-REF-MODE-APP-13..15); thêm `role: ManageRole.manager` vào các test dựng hub trực tiếp
  - Giao: `TournamentManagementHubScreen({..., required ManageRole role})` · Nhận: 1.1
  - Chủ file chung: 4.1 giữ hub + arb
  - Phụ thuộc: 1.1, 3.1

## 5. Nội dung tab chỉ xem / chỉ giờ-sân

- [x] 5.1 Nội dung + VĐV chỉ xem (`readOnly`), Bảng đấu `canEditBracket` theo vai + `isReferee`, Kết quả giữ nhập điểm và hộp sửa giờ/sân/thời lượng (Backend cho phép). Tiêu chí: test 5.1 trong `test/features/tournament/referee_mode_hub_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_divisions_section.dart`, `lib/features/tournament/widgets/tournament_management_athletes_tab.dart`, `lib/features/tournament/screens/tournament_management_people_section.dart`; test TC-REF-MODE-APP-16..17
  - Giao: `readOnly` (mặc định false) ở ba widget · Nhận: 4.1
  - Chủ file chung: 5.1
  - Phụ thuộc: 4.1
- [x] 5.2 Lịch thi đấu với trọng tài: kéo thả giờ/sân/thời lượng, ghi không có khoá `refereeId`, `matchConfig` chỉ `durationMinutes`; ẩn xếp tự động/AI, bản nháp, giờ sân, chọn trọng tài, mở sơ đồ, thao tác đặc biệt; lưới không hiện CTA tạo sân. Tiêu chí: `flutter test --no-pub test/features/tournament/referee_mode_schedule_test.dart` → exit 0
  - Files: sửa `lib/features/organizer_ops/screens/organizer_ops_screen.dart`, `lib/features/tournament/widgets/tournament_schedule_court_grid.dart`; test mới `test/features/tournament/referee_mode_schedule_test.dart` (TC-REF-MODE-APP-18..20, 20b); sửa `test/features/schedule_grid_empty_cta_test.dart` theo luật CTA mới (TC-REF-MODE-APP-22)
  - Giao: `OrganizerOpsScreen.manageRole` (mặc định `ManageRole.manager`) · Nhận: 1.1
  - Chủ file chung: 5.2
  - Phụ thuộc: 1.1

## 6. Lối vào

- [x] 6.1 Dashboard tab Hoạt động: nhóm "Giải làm trọng tài" (mỗi giải một dòng, bỏ DRAFT/PENDING) mở màn quản lý. Tiêu chí: `flutter test --no-pub test/features/dashboard/referee_tournaments_entry_test.dart` → exit 0
  - Files: sửa `lib/features/dashboard/screens/dashboard_screen.dart`, arb (chuỗi tiêu đề nhóm); test mới `test/features/dashboard/referee_tournaments_entry_test.dart` (TC-REF-MODE-APP-21)
  - Giao: (không) · Nhận: 3.1
  - Chủ file chung: arb do 4.1 giữ, 6.1 thêm khoá sau 4.1
  - Phụ thuộc: 4.1

## 7. Kiểm tích hợp

- [x] 7.1 `flutter analyze --no-pub` trên từng thư mục đã sửa và chạy lại các file test cũ bị đụng (guard, hub, results tab, camera tab, step popup, division share, lifecycle end sheet, ops drop, waiting tray, schedule manager bar). Tiêu chí: mọi lệnh exit 0
  - Files: (không sửa)
  - Giao: (không) · Nhận: 1–6
  - Chủ file chung: (không)
  - Phụ thuộc: 1–6
  - Kết quả: chạy 35 file test liên quan, mỗi lần một file: 33 file exit 0. Hai file đỏ vì test còn theo luật cũ: `tournament_management_hub_screen_test.dart` (dựng dispatcher mà không override vai) và `schedule_grid_empty_cta_test.dart` (CTA tạo sân theo `onScheduleDrop`). Đã sửa hai test này và chạy lại: `schedule_grid_empty_cta_test.dart` exit 0. `tournament_management_hub_screen_test.dart` còn 1 ca đỏ (CLB Super Lite); đã thêm override nhưng CHƯA chạy lại được, vì đĩa còn dưới 10 GB và hook chặn `flutter test`, `flutter analyze`, `dart format`. Cần chạy lại file này và `flutter analyze` khi đã có chỗ trống trên đĩa, hoặc để CI của nhánh chạy. Bổ sung 2026-11-26: CI nhánh (run 45763613111, commit d87b5da0) chạy `flutter analyze` toàn repo 0 lỗi (109 info, 78 warning) và `flutter test` đầy đủ, gồm cả `tournament_management_hub_screen_test.dart`: success.
