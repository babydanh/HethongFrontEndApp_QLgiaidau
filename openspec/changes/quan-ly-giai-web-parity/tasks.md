## 0. Khung sheet chung

- [x] 0.1 Widget `TournamentManageSheet`: tiêu đề + thân cuộn + thanh thao tác sticky + cờ busy (spinner trong nút, chống double-tap) + `PopScope(canPop: !busy)` + padding bàn phím. Tiêu chí: `flutter test --no-pub test/features/tournament_manage_sheet_test.dart` exit 0 (TC-WP-00-01: busy chặn đóng sheet, nút disabled).
  - Files: tạo `lib/features/tournament/widgets/tournament_manage_sheet.dart`, `test/features/tournament_manage_sheet_test.dart`
  - Giao: `TournamentManageSheet({title, child, actions, busy})` · Nhận: mọi sheet của change này
  - Chủ file chung: không
  - Phụ thuộc: không

## 1. Vòng đời & đăng ký

- [x] 1.1 Sheet khai mạc checklist: liệt kê hạng mục đang mở kèm toggle đóng từng hạng mục (mặc định đóng hết) + cảnh báo (chưa có sơ đồ, VĐV chờ duyệt); gửi `close-registration` (divisionIds chọn đóng) rồi `POST /start`. Tiêu chí: TC-WP-01-01/02 xanh trên cloud.
  - Files: `lib/features/tournament/screens/tournament_management_section_screen.dart:836-989`, `lib/data/repositories/api/api_tournament_management_repository.dart`, ARB vi/en, `test/features/tournament_management_hub_screen_test.dart`
  - Giao: `closeDivisionRegistrations(String tournamentId, List<String> divisionIds)` · Nhận: card vòng đời
  - Chủ file chung: `tournament_management_section_screen.dart` (cùng task 1.2, 1.4)
  - Phụ thuộc: 0.1
- [x] 1.2 Sheet kết thúc: checklist "trận đã xong X/Y", danh sách trận LIVE chặn nút, hạng mục còn trận; bỏ `_canFinalizeTournament` admin-only cho organizer cũng kết thúc (Backend chốt quyền). Tiêu chí: TC-WP-01-03/04 + test API complete qua cloud.
  - Files: `lib/features/tournament/screens/tournament_management_hub_screen.dart:530-633,790-834`, repository, ARB, test hub + `test/tournament_management_repository_api_test.dart`
  - Chủ file chung: hub screen (cùng task 3.9 menu export)
  - Phụ thuộc: 0.1
- [ ] 1.3 Prompt hạng mục đủ chỗ tự đề nghị đóng (ghi nhớ đã hỏi theo phiên màn). Tiêu chí: TC-WP-01-05.
  - Files: `tournament_management_hub_screen.dart` (state), `tournament_management_divisions_section.dart` (helper đếm), ARB, test hub
  - Chủ file chung: divisions_section (cùng 2.1)
  - Phụ thuộc: 1.1
- [ ] 1.4 Sheet đóng/mở đăng ký hàng loạt: checkbox nhiều hạng mục + chọn hết, chế độ close/open, hạn mới bắt buộc khi mở lại hạng mục quá hạn. Tiêu chí: TC-WP-01-06/07.
  - Files: `tournament_management_divisions_section.dart`, `tournament_management_section_screen.dart` (nút vào), repository (body `divisionIds`), ARB, test
  - Chủ file chung: divisions_section, section_screen
  - Phụ thuộc: 1.1
- [ ] 1.5 Sửa lệ phí nhanh: nút mức phí nhanh (0/+20/+50/+100/+200k) + bảng phân tích phí sàn (port `getPlatformFeeBreakdown` thành Dart util). Tiêu chí: TC-WP-01-08 + util test riêng.
  - Files: `lib/features/tournament/screens/tournament_management_finance_section.dart:397-584`, tạo `lib/features/tournament/utils/platform_fee.dart`, `test/features/platform_fee_test.dart`, ARB
  - Chủ file chung: finance_section
  - Phụ thuộc: 0.1

## 2. Hạng mục & vòng đấu

- [ ] 2.1 Sheet hạng mục đầy đủ (tạo/sửa): nhận dạng, thể thức, chuẩn/Lite, sức chứa + ELO min/max + phí riêng, luật theo môn (sets/points/winBy2/maxDeuce/superTiebreak), số lượt vòng tròn, vòng bảng + playoff + seeding, giữ SwissConfigEditor, preset theo môn (port `getSportRulePresets`); khoá kết cấu khi có bracket. Tiêu chí: TC-WP-02-01/02/03 + test API create/update division qua cloud.
  - Files: `lib/features/tournament/screens/tournament_management_divisions_section.dart:151-335,385-723`, tạo `lib/features/tournament/widgets/division_editor_sheet.dart`, tạo `lib/features/tournament/utils/sport_rule_presets.dart`, repository, ARB, `test/features/division_editor_sheet_test.dart`
  - Giao: `createDivision/updateDivision` mở rộng payload · Nhận: thay dialog thêm/sửa/cấu hình hiện có
  - Chủ file chung: divisions_section (cùng 1.3, 1.4)
  - Phụ thuộc: 0.1
- [ ] 2.2 Sheet cấu hình từng vòng: chọn vòng của stage, sân + giờ mặc định + luật vòng + ghi chú → `PATCH /tournaments/stages/:stageId`. Tiêu chí: TC-WP-02-04 + test API stages.
  - Files: tạo `lib/features/tournament/widgets/stage_round_config_sheet.dart`, divisions_section (nút mở khi có bracket), repository (`updateStageRoundConfig` đã có — đối chiếu Web `handleSaveStageDetails`), ARB, `test/features/stage_round_config_sheet_test.dart`
  - Chủ file chung: divisions_section
  - Phụ thuộc: 2.1

## 3. VĐV & ghép cặp

- [ ] 3.1 Lọc trạng thái VĐV (chips + số đếm) trong tab VĐV của hub. Tiêu chí: TC-WP-03-01.
  - Files: `lib/features/tournament/widgets/tournament_management_athletes_tab.dart`, `tournament_management_people_section.dart`, ARB, test
  - Chủ file chung: athletes_tab (cùng 3.2, 3.3)
  - Phụ thuộc: không
- [ ] 3.2 Sheet hồ sơ VĐV chi tiết: liên hệ từng thành viên, ghi chú BTC (`PATCH /participants/:id/note`), câu trả lời form tùy chỉnh, seed nhanh, khoá/mở roster bóng đá, xoá VĐV ảo, duyệt/từ chối. Tiêu chí: TC-WP-03-02/03/04 + test API note qua cloud.
  - Files: tạo `lib/features/tournament/widgets/participant_detail_sheet.dart`, `tournament_management_people_section.dart:179-228,686-843`, repository (route note, lock roster), ARB, test
  - Giao: `updateParticipantNote(String id, String note)` · Nhận: thay card mở rộng hiện có
  - Chủ file chung: people_section
  - Phụ thuộc: 0.1, 3.1
- [ ] 3.3 Tách cặp trong menu dòng VĐV (confirm) → `POST /pairing/:pid/unpair`. Tiêu chí: TC-WP-03-05 + test API.
  - Files: `participant_detail_sheet.dart` hoặc people_section (menu dòng), repository (`unpairParticipant`), ARB, test
  - Chủ file chung: people_section
  - Phụ thuộc: 3.2
- [ ] 3.4 Sheet VĐV ảo: chọn hạng mục + chế độ ghép + danh sách tên từng dòng; xoá hết có confirm. Tiêu chí: TC-WP-03-06/07 + test API mock-participants.
  - Files: tạo `lib/features/organizer_ops/screens/mock_participants_sheet.dart`, `tournament_management_athletes_tab.dart:69-107` (nút vào), repository, ARB, test
  - Chủ file chung: athletes_tab
  - Phụ thuộc: 0.1
- [ ] 3.5 Sheet wildcard (reserve-slots): hạng mục, email/SĐT (+ đồng đội), tên đội, validate email + tên đội. Tiêu chí: TC-WP-03-08 + test API.
  - Files: tạo `lib/features/tournament/widgets/wildcard_sheet.dart`, athletes_tab (nút vào), repository (`reserveSlots`), ARB, test
  - Chủ file chung: athletes_tab
  - Phụ thuộc: 0.1
- [ ] 3.6 Sheet ghép cặp thủ công: danh sách chờ + tìm kiếm không dấu, chọn/kéo-thả ghép (LongPressDraggable), xáo trộn, đặt tên cặp, tối đa 24, gửi `POST /pairing/batch`. Tiêu chí: TC-WP-03-09/10/11 + test API.
  - Files: tạo `lib/features/tournament/widgets/pairing_sheet.dart`, `tournament_management_athletes_tab.dart` (nút vào), repository (`pairBatch`), ARB, test
  - Giao: `pairBatch(String tournamentId, List<PairInput> pairs)` · Nhận: nút "Ghép cặp" của tab VĐV
  - Chủ file chung: athletes_tab
  - Phụ thuộc: 0.1
- [ ] 3.7 Ghép cặp tự động 3 chiến lược (RANDOM/ELO_BALANCED/SAME_LEVEL) → `POST /pairing/generate`. Tiêu chí: TC-WP-03-12 + test API.
  - Files: `pairing_sheet.dart` (tab tự động), repository (`pairGenerate`), ARB, test
  - Chủ file chung: pairing_sheet
  - Phụ thuộc: 3.6
- [ ] 3.8 Import Excel: bước "tạo hạng mục còn thiếu" từ tên hạng mục trong file (confirm từng hạng mục rồi `createDivision` trước preview). Tiêu chí: TC-WP-03-13 + giữ nguyên mọi test import hiện có.
  - Files: `lib/features/organizer_ops/screens/roster_import_sheet.dart:59-67,526-578`, ARB, test import thêm ca division mới
  - Chủ file chung: roster_import_sheet
  - Phụ thuộc: không
- [ ] 3.9 Xuất Excel danh sách VĐV (sheet roster: tên, liên hệ, hạng mục, trạng thái, seed, thanh toán). Tiêu chí: TC-WP-03-14.
  - Files: `lib/core/services/excel_export_service.dart` (mở rộng), `tournament_management_hub_screen.dart:835-870` (menu), ARB, test export
  - Chủ file chung: hub screen (cùng 1.2)
  - Phụ thuộc: không

## 4. Lịch sân

- [ ] 4.1 Sheet xếp nhiều trận nối tiếp từ ô: multi-select + thời lượng từng trận (15–240, bội 5) + lọc vòng + tìm tên; cascade util Dart (port `court-schedule-cascade.ts`) có test riêng; ghi tuần tự báo "đã xếp i/N". Tiêu chí: TC-WP-04-01/02/03 + util test.
  - Files: `lib/features/organizer_ops/screens/organizer_ops_screen.dart:1223-1323`, tạo `lib/features/tournament/utils/court_schedule_cascade.dart`, `test/features/court_schedule_cascade_test.dart`, ARB
  - Giao: `cascadeStartTimes(DateTime start, List<int> minutes, {int gapMinutes})` · Nhận: sheet chọn ô và áp bản nháp
  - Chủ file chung: organizer_ops_screen (cùng 4.2–4.5)
  - Phụ thuộc: 0.1
- [ ] 4.2 Khay chưa xếp nâng cấp: checkbox nhiều trận + chọn sân đích + khung giờ bắt đầu → xếp nối tiếp tuần tự, có tiến độ và huỷ giữa chừng. Tiêu chí: TC-WP-04-04.
  - Files: `lib/features/tournament/widgets/tournament_schedule_court_grid.dart:1046-1093`, organizer_ops_screen, ARB
  - Chủ file chung: court_grid, organizer_ops_screen
  - Phụ thuộc: 4.1
- [ ] 4.3 Sheet cài đặt khung giờ sân: giờ mở/đóng + bước ô 5/10/15/30/60, lưu cấu hình giải (đối chiếu route Web trước khi làm), lưới vẽ lại. Tiêu chí: TC-WP-04-05.
  - Files: organizer_ops_screen (`scheduleSettings` chỗ 1340-1347, 2575-2578), tournament_schedule_court_grid.dart, repository, ARB, test
  - Chủ file chung: organizer_ops_screen, court_grid
  - Phụ thuộc: không
- [ ] 4.4 Cảnh báo VĐV trùng giờ: util tính xung đột (port `scheduleConflicts`) + sheet danh sách, hiện sau thao tác ghi khi có xung đột. Tiêu chí: TC-WP-04-06 + util test.
  - Files: tạo `lib/features/tournament/utils/schedule_conflicts.dart`, `test/features/schedule_conflicts_test.dart`, organizer_ops_screen (điểm gọi sau ghi), ARB
  - Chủ file chung: organizer_ops_screen
  - Phụ thuộc: 4.1
- [ ] 4.5 AI xếp lịch bằng lệnh chữ: sheet nhập lệnh → `POST /ai/tournaments/:id/schedule-preview` → bản nháp trên lưới (dùng draft bar hiện có) → áp dụng tuần tự; 404 thì ẩn mục. Tiêu chí: TC-WP-04-07/08 + test API AI qua cloud.
  - Files: tạo `lib/features/organizer_ops/screens/ai_schedule_sheet.dart`, organizer_ops_screen (nút vào), repository (`previewScheduleWithAi`), ARB, test
  - Chủ file chung: organizer_ops_screen
  - Phụ thuộc: 4.1

## 5. Livestream camera

- [ ] 5.1 Camera CRUD: sheet thêm camera (tên, sân, PUSH/PULL + URL khi PULL), sửa/xoá có confirm, đổi sân qua chọn; kéo-thả camera vào thẻ sân. Tiêu chí: TC-WP-05-01/02/03 + test API cameras qua cloud.
  - Files: `lib/features/tournament/screens/tournament_management_livestream_section.dart:18-33` (gỡ chặn), tạo `lib/features/tournament/widgets/camera_editor_sheet.dart`, repository (listCameras/createCamera/deleteCamera/assignCameraCourt), ARB, test
  - Giao: `listCameras/createCamera/deleteCamera/assignCameraCourt` · Nhận: khu camera trong màn Livestream
  - Chủ file chung: livestream_section (cùng 5.2)
  - Phụ thuộc: 0.1
- [ ] 5.2 Stream key QR: hiện QR + key che/hiện, issue tự động/thủ công, đổi tên stream, rotate key có confirm; không log key. Tiêu chí: TC-WP-05-04/05/06 + test API stream key.
  - Files: tạo `lib/features/tournament/widgets/stream_key_qr_sheet.dart`, livestream_section (nút QR trên thẻ camera), repository (createAqpStreamKey/rename/rotate — đối chiếu `livestreamApi` Web api.ts:776-876), ARB, test
  - Chủ file chung: livestream_section
  - Phụ thuộc: 5.1
