## 1. Hợp đồng dùng chung (làm trước, trên nhánh phiên)

- [x] 1.1 Thêm hàm dựng/kiểm dữ liệu vào `BackendApi`. Tiêu chí: `flutter analyze --no-pub integration_test/support/backend_api.dart` → exit 0
  - Files: sửa `integration_test/support/backend_api.dart` (thêm sau `playOutSingleElimination` ~dòng 361; tách logic bên thắng từ `_scorePlayerOneWins` ~dòng 363-391, hành vi cũ giữ nguyên)
  - Giao: `Future<void> startTournament({required String token, required String tournamentId})` (POST `/tournaments/:id/start`) · `Future<void> completeTournament({required String token, required String tournamentId})` (POST `/tournaments/:id/complete`; Backend không tự chuyển COMPLETED) · `Future<void> scoreMatch({required String token, required Map<String, dynamic> match, int winnerSide = 1})` · `Future<Map<String, dynamic>> getTournament({required String token, required String tournamentId})` (GET `/tournaments/:id`) · `Future<List<Map<String, dynamic>>> listVenues({required String token, required String tournamentId})` (GET `/tournaments/:id/venues`) · `Future<List<Map<String, dynamic>>> listSponsors({required String token, required String tournamentId})` (GET `/tournaments/:id/sponsors`) · Nhận: (không)
  - Chủ file chung: 1.1 giữ `integration_test/support/backend_api.dart`; task khác chỉ gọi
  - Phụ thuộc: không
- [x] 1.2 Hàm dùng chung cho các file hành trình. Tiêu chí: `flutter analyze --no-pub integration_test/support/organizer_journey.dart` → exit 0
  - Files: tạo `integration_test/support/organizer_journey.dart` (dùng `app_driver.dart:22,46,77,105,135,144,171`)
  - Giao: `Future<void> signInAsOrganizer(WidgetTester tester)` · `Future<SeededTournament> seedTournament(BackendApi api, {int players = 4, String bracketType = 'single_elimination', bool singles = true})` (đăng nhập BTC, `createLiteTournament`, duyệt ADMIN, `importRoster`; trả `token`, `tournamentId`, `divisionId`) · `Future<void> openManageHub(WidgetTester tester, String tournamentId)` (route `/organizer/tournaments/:id/manage`) · `Future<void> openHubTab(WidgetTester tester, String label)` (tìm `Tab` theo chữ, `ensureVisible`, bấm, chờ) · `Future<void> tapKey(WidgetTester tester, String key)` và `Future<void> expectKey(WidgetTester tester, String key, {String? step})` (chờ có hạn rồi `expect`, thông báo nêu `step`) · Nhận: `BackendApi` (1.1)
  - Chủ file chung: 1.2 giữ `integration_test/support/organizer_journey.dart`
  - Phụ thuộc: sau 1.1

## 2. Bốn file hành trình (song song, mỗi file một worktree riêng, `Files:` không trùng)

- [x] 2.1 Hành trình dựng giải, nội dung và VĐV (TC-QLGD-APP-01..19). Tiêu chí: `flutter analyze --no-pub integration_test/organizer_setup_journey_test.dart` → exit 0; cloud `cloud-test-runner.py run --target app-e2e --app-ref <nhánh> --specs integration_test/organizer_setup_journey_test.dart` → các ca xanh
  - Files: tạo `integration_test/organizer_setup_journey_test.dart` (mẫu `organizer_flow_test.dart:26-250`)
  - Giao: (không) · Nhận: `signInAsOrganizer`, `seedTournament`, `openManageHub`, `openHubTab`, `tapKey`, `expectKey` (1.2); `BackendApi.getTournament`, `listDivisions`, `listParticipants` (1.1, `backend_api.dart:213,246`)
  - Chủ file chung: không
  - Phụ thuộc: sau 1.2
  - Phủ (nguồn: `lib/features/tournament/screens/create_public_quick_tournament_screen.dart`, `widgets/overview_tab.dart`, `tournament_management_divisions_section.dart`, `widgets/division_editor_sheet.dart`, `widgets/tournament_management_athletes_tab.dart`, `features/organizer_ops/screens/add_athlete_sheet.dart`, `roster_import_sheet.dart`): tạo giải nhanh (bỏ tick `Đôi tự do`, chữ `Tạo giải đấu`); tổng quan `tournament-overview-name-edit`; nội dung `division-add-tile`, `division-editor-format-*`, `division-editor-bracket-*`, `division-editor-save`, sửa `division-edit-<id>`, menu 3 chấm (`Cấu hình từng vòng`, `Khoá đăng ký`, `Đăng ký`, `Xóa` + xác nhận); VĐV `Thêm VĐV`, `add-athlete-direct-*`, `add-athlete-search`, `athletes-pairing`, `athletes-auto-pair`, `athletes-more` → `athletes-wildcard`, `athletes-mock-data`, `athletes-pair-move`, `athletes-import-excel` (chỉ kiểm `roster-import-sheet` mở/đóng); chi tiết VĐV `participant-detail-approve|reject|checkin|fee-paid|note`, `participant-contact-edit|save`
- [x] 2.2 Hành trình vận hành giải tới kết thúc (TC-QLGD-APP-20..39). Tiêu chí: `flutter analyze --no-pub integration_test/organizer_run_journey_test.dart` → exit 0; cloud `... --specs integration_test/organizer_run_journey_test.dart` → các ca xanh
  - Files: tạo `integration_test/organizer_run_journey_test.dart`
  - Giao: (không) · Nhận: như 2.1 cộng `BackendApi.startTournament`, `completeTournament`, `scoreMatch`, `listMatches`, `generateBracket` (1.1, `backend_api.dart:266-279`)
  - Chủ file chung: không
  - Phụ thuộc: sau 1.2
  - Phủ (nguồn: `lib/features/tournament/screens/tournament_management_section_screen.dart:1166`, `widgets/lifecycle_stepper.dart`, `lifecycle_opening_sheet.dart`, `lifecycle_end_sheet.dart`, `features/bracket/screens/auto_draw_screen.dart`, `bracket_view_screen.dart`, `widgets/bracket_management_bar.dart`, `widgets/results_match_board.dart`, `results_score_dialog.dart`, `features/match/screens/live_score_screen.dart`, `screens/tournament_intro_screen.dart`): nút vòng đời theo trạng thái (`Công bố giải đấu` nếu không bị khóa phí, `Mở đăng ký ngay`, `Đóng đăng ký`, `Mở lại đăng ký`, `Khai mạc giải` + `lifecycle-opening-confirm`); bốc thăm `Bốc thăm từng đội`, `Bốc 1 đội`, `Hiện tất cả`, `Làm lại sơ đồ`, `Lưu & Bắt đầu giải` (`clearSnackBars` trước khi bấm); tab Bảng đấu `bracket-mgmt-create|delete` + xác nhận; tab Kết quả `results-filter-*`, `results-search`, `results-score-<id>` → `results-score-input-*`, `results-score-add-set`, `results-score-tied`, `results-score-save`, `Chốt lại kết quả`; bàn điểm live qua route `/organizer/tournaments/:id/ops/match/:matchId` (`BẮT ĐẦU TRẬN ĐẤU`, `KẾT THÚC` + xác nhận); `lifecycle-end-confirm`; trang công khai `/tournament/:id` đủ các tab và nhà vô địch. Nút bị khóa bởi phí công bố thì dùng API, ghi rõ trong test
- [x] 2.3 Hành trình thể thức thi đấu (TC-QLGD-APP-40..59). Tiêu chí: `flutter analyze --no-pub integration_test/organizer_formats_journey_test.dart` → exit 0; cloud `... --specs integration_test/organizer_formats_journey_test.dart` → các ca xanh
  - Files: tạo `integration_test/organizer_formats_journey_test.dart`
  - Giao: (không) · Nhận: như 2.1 cộng `BackendApi.generateBracket`, `listMatches` (1.1)
  - Chủ file chung: không
  - Phụ thuộc: sau 1.2
  - Phủ (nguồn: `lib/features/bracket/screens/group_stage_assignment_screen.dart`, `swiss_pairing_screen.dart`, `bracket_view_screen.dart`, `widgets/bracket_management_bar.dart`, `lib/features/tournament/widgets/division_editor_sheet.dart`): vòng tròn (`division-editor-bracket-ROUND_ROBIN`, `division-editor-rr-rounds`); loại kép (`DOUBLE_ELIMINATION`); vòng bảng `group-stage-assignment-entry` → `group-count-*` → `save-assignment`, đường thay thế `Chuyển sang bảng` (không kéo-thả); Swiss `swiss-next-round` → `swiss-pairing-screen` (`swiss-auto`, chạm `swiss-chip-*` → `swiss-swap-*`), `swiss-undo-round` + `swiss-undo-round-confirm`; `stage-operations-entry`; hạt giống `division-editor-seeding-*` và `POST /tournaments/:id/auto-seed`
- [x] 2.4 Hành trình lịch thi đấu và cài đặt (TC-QLGD-APP-60..79). Tiêu chí: `flutter analyze --no-pub integration_test/organizer_schedule_settings_journey_test.dart` → exit 0; cloud `... --specs integration_test/organizer_schedule_settings_journey_test.dart` → các ca xanh
  - Files: tạo `integration_test/organizer_schedule_settings_journey_test.dart`
  - Giao: (không) · Nhận: như 2.1 cộng `BackendApi.listVenues`, `listSponsors`, `listMatches` (1.1)
  - Chủ file chung: không
  - Phụ thuộc: sau 1.2
  - Phủ (nguồn: `lib/features/tournament/widgets/schedule_manager_bar.dart:141-153`, `schedule_grid.dart`, `screens/tournament_management_venues_section.dart`, `tournament_management_finance_section.dart`, `features/organizer_ops/screens/organizer_ops_screen.dart:2543`): `schedMgmt-courts`, `venue-add` + `venue-dialog-*`, `venue-add-court`, `court-edit-*`, `schedMgmt-hours` + `schedule-settings-save`, `schedMgmt-arrange`, `ops-matches-view-grid|list`, chạm ô trống `schedule-slot-*`, sheet hành động trận (`Thời gian xếp lịch`, `Mở bảng điểm`, `Mở bracket`, `Xử lý đặc biệt`), `schedule-multi-submit`; cài đặt nhà tài trợ, trọng tài (thêm, `DELETE`), tài chính (chip phí `financeFeeQuickFree`..., `Yêu cầu rút tiền` chỉ kiểm dialog và kiểm ràng buộc, `Lịch sử rút tiền`), `lifecycle-share`, `Xuất dữ liệu giải đấu`, `lifecycle-delete` → `delete-tournament-name` → `delete-tournament-confirm` (làm cuối cùng vì xóa giải)

## 3. Chốt

- [x] 3.1 Cập nhật README, chạy cloud từng file một, báo cáo. Tiêu chí: `flutter analyze --no-pub integration_test` → exit 0; bốn run cloud `app-e2e` xanh (hoặc nêu rõ ca đỏ do bug sản phẩm); `openspec validate app-e2e-quan-ly-giai --strict` → exit 0
  - Files: sửa `integration_test/README.md` (thêm 4 file và lệnh cloud)
  - Giao: (không) · Nhận: bốn file test của 2.1-2.4
  - Chủ file chung: 3.1 giữ `integration_test/README.md`
  - Phụ thuộc: sau 2.1, 2.2, 2.3, 2.4
