## 0. Chuỗi hiển thị (chủ chung hai file arb)

- [x] 0.1 Thêm toàn bộ chuỗi vi/en cho tab Kết quả và popup tiến trình: `tournamentManagementTabResults`, nhóm `resultsBoard_*` (3 chip mới, "Chưa có trận nào."), nhóm `stepPopup_*` (tiêu đề, trạng thái Đủ/Cần chú ý/Thiếu/Đang chạy/Chưa tới/Đang tải/Chưa mở, "Đi tới", "Mở", "Tải lại", "Tìm nội dung...", "Chỉ hiện thiếu", các câu rỗng) và nhóm `stepSummary_*` (các dòng số liệu từng bước). Tên và nội dung lấy từ Web `messages/vi.json` (`OrganizerManage.resultsBoard.*`, `OrganizerTournamentStepper.*`). Tiêu chí: `flutter gen-l10n` → exit 0, không có cảnh báo thiếu bản dịch en
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; sinh lại `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_vi.dart` (file sinh có trong git, commit cùng)
  - Giao: các key trên cho 1.2, 2.2 · Nhận: không
  - Chủ file chung: 0.1 giữ hai file arb; các task sau KHÔNG sửa arb, thiếu key thì quay lại 0.1
  - Phụ thuộc: không

## 1. Tab Kết quả

- [x] 1.1 Mở rộng bộ lọc của bảng trận lên bảy chip và cho mở sẵn một chip. Luật "Chưa xong", "Trễ giờ", "Tranh chấp" đối chiếu Web `src/features/organizer/operations/results.ts` (đọc từ `origin/main`). Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_match_board_test.dart` → exit 0 (thêm TC-RESULTS-01..04: số trận trên chip, lọc Tranh chấp, lọc Trễ giờ, `initialFilter`)
  - Files: sửa `lib/features/tournament/widgets/results_match_board.dart` (enum `_BoardFilter` dòng 22, `_passes` dòng 37, constructor dòng 49-60), `lib/features/tournament/utils/results_rounds.dart` (thêm hàm thuần); test `test/features/tournament/widgets/results_match_board_test.dart`
  - Giao: `enum ResultsBoardFilter { all, live, upcoming, finished, unfinished, late, disputed }` (công khai, thay `_BoardFilter`); `ResultsMatchBoard({super.key, required String tournamentId, required bool isLite, required bool canManage, String? divisionId, ResultsBoardFilter initialFilter = ResultsBoardFilter.all})`; `bool isLateMatch(MatchModel match, DateTime now)`; `bool isDisputedMatch(MatchModel match)` · Nhận: 0.1 (chuỗi chip)
  - Chủ file chung: 1.1 giữ `results_match_board.dart` và `results_rounds.dart`
  - Phụ thuộc: sau 0.1

- [x] 1.2 Thêm tab "Kết quả" vào hub: dải chọn hạng mục (dùng lại dải đang có ở màn công khai, tìm trong `tournament_intro_screen.dart`, hàm `_buildResultsDivisionStrip`) và `ResultsMatchBoard(canManage: true)`. Xác nhận trong task này nguồn dữ liệu của `matchesProvider` đúng là `/manage/matches` khi người dùng có quyền quản lý. Thêm hàm `_goToResults({ResultsBoardFilter? filter, String? divisionId})` để task 2.3 gọi. Tiêu chí: `flutter test --no-pub test/features/tournament/management_results_tab_test.dart` → exit 0 (TC-RESULTS-05: có 7 tab và tab thứ 7 là Kết quả; TC-RESULTS-06: mở tab hiện bảng trận; TC-RESULTS-07: giải không trận hiện "Chưa có trận nào."); chạy lại `flutter test --no-pub test/features/tournament/overview_edit_test.dart` → exit 0 để chắc tab cũ không lệch
  - Files: sửa `lib/features/tournament/screens/tournament_management_hub_screen.dart` (enum `_HubTab` dòng 1070, danh sách `Tab` dòng 399-404, `TabBarView` dòng 418-500; thêm vào CUỐI enum để các `animateTo(_HubTab.xxx.index)` ở dòng 130 và 138 không lệch); tạo test `test/features/tournament/management_results_tab_test.dart`
  - Giao: `void _goToResults({ResultsBoardFilter? filter, String? divisionId})` (trong state của hub; tạo lại bảng bằng `ValueKey` có bộ đếm yêu cầu để `initialFilter` có hiệu lực khi tab đang mở) · Nhận: 1.1, 0.1
  - Kết quả xác nhận nguồn dữ liệu: `matchesProvider` đọc feed công khai, không phải `/manage/matches`; đã đổi `ResultsMatchBoard` đọc `managedMatchesWithDivisionProvider` khi `canManage` (như Web), kèm cập nhật `live_tab_test.dart`, `results_match_board_test.dart` và dòng danh sách tab trong `tournament_management_hub_screen_test.dart`
  - Chủ file chung: 1.2 giữ `tournament_management_hub_screen.dart` cho tới khi 2.3 xong
  - Phụ thuộc: sau 1.1

## 2. Popup thanh tiến trình

- [x] 2.1 Viết `buildStepSummary` thuần Dart, port rút gọn Web `tournament-step-summary.ts`, `-play.ts`, `-types.ts` (4 bước: rows, todos, percent, state; danh sách nội dung với cờ thiếu). Mỗi luật có test với bộ số liệu lấy từ test của Web (tìm file test cùng tên bên Web). Tiêu chí: `flutter test --no-pub test/features/tournament/utils/tournament_step_summary_test.dart` → exit 0 (TC-STEP-01..08: nội dung chưa có VĐV, chưa thanh toán, hạn đăng ký, trận chưa có sân/giờ, đang đánh/trễ/tranh chấp, bước chưa tới, trạng thái đang tải/lỗi, danh sách rỗng không ném lỗi)
  - Files: tạo `lib/features/tournament/utils/tournament_step_summary.dart`; test `test/features/tournament/utils/tournament_step_summary_test.dart`
  - Giao: `enum StepKey { registration, schedule, inProgress, completed }`; `enum StepStatus { done, attention, missing, current, upcoming, loading, disabled }`; `enum SummaryLoad { loading, ready, error }`; `enum StepHubTab { overview, divisions, athletes, bracket, schedule, settings, results }`; `class StepTarget { final StepHubTab tab; final ResultsBoardFilter? resultsFilter; final String? divisionId; }`; `class StepTodo { final String key; final String labelKey; final Map<String, Object> params; final int? count; final bool retry; final StepTarget target; }`; `class StepProgress { final StepKey key; final StepStatus state; final int percent; final List<StepTodo> todos; }`; `class StepDivisionRow { final String id; final String name; final bool missing; final StepTarget target; }`; `class StepSummary { final List<StepProgress> steps; final List<StepDivisionRow> divisions; }`; `StepSummary buildStepSummary({required Tournament tournament, required List<TournamentDivision> divisions, required List<OrganizerOpsParticipant> participants, required SummaryLoad participantsLoad, required List<MatchModel> matches, required SummaryLoad matchesLoad, required DateTime now})` cho 2.2, 2.3 · Nhận: 1.1 (`ResultsBoardFilter`, `isLateMatch`, `isDisputedMatch`)
  - Đổi tên `StepState` thành `StepProgress` vì trùng `StepState` của `Stepper` trong Flutter.
  - Phạm vi port thực tế: bỏ việc "tạo vòng Swiss tiếp" và các việc công bố của giải nháp (giải nháp mọi bước đều "Chưa mở"); hạn đăng ký tính theo giải vì `TournamentDivision` của App không có hạn riêng; "Cần chú ý" (không phải "Thiếu") khi có nội dung chưa VĐV, như Web
  - Chủ file chung: 2.1 giữ `tournament_step_summary.dart`
  - Phụ thuộc: sau 1.1

- [x] 2.2 Viết popup chi tiết một bước trong `TournamentEditSheet`: tiêu đề, trạng thái, vòng phần trăm, hộp việc cần làm (nút "Đi tới", "Tải lại" khi lỗi), phần "Theo từng nội dung" (ô tìm, lọc "Chỉ hiện thiếu"/"Tất cả (n)", nút "Mở"). Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/step_detail_popup_test.dart` → exit 0 (TC-STEP-09..13: hiện việc cần làm, "Đi tới" trả đúng `StepTarget`, bước đủ hiện câu "Đã đủ", bước chưa tới không có nút ghi, lọc "Chỉ hiện thiếu")
  - Files: tạo `lib/features/tournament/widgets/step_detail_popup.dart`; test `test/features/tournament/widgets/step_detail_popup_test.dart`
  - Giao: `Future<void> showStepDetailPopup(BuildContext context, {required StepKey step, required StepSummary summary, required ValueChanged<StepTarget> onGo, VoidCallback? onRetry})` cho 2.3 · Nhận: 2.1, 0.1 (khung `TournamentEditSheet` đã có sẵn ở `lib/features/tournament/widgets/tournament_edit_sheet.dart`)
  - Chủ file chung: 2.2 giữ `step_detail_popup.dart`
  - Phụ thuộc: sau 2.1

- [x] 2.3 Cho thanh tiến trình bấm được và nối vào hub: thêm `onStepTap` cho `LifecycleStepBar` và `TournamentLifecycleCard`; hub dựng `StepSummary` từ giải, nội dung, `getOrganizerParticipants` (tạo provider tự hủy cho danh sách này) và `matchesProvider`, mở popup, và xử lý `StepTarget` bằng cách đổi tab hub (gọi `_goToResults` cho tab Kết quả). Tiêu chí: `flutter test --no-pub test/features/tournament/overview_step_popup_test.dart` → exit 0 (TC-STEP-14: bấm bước mở popup; TC-STEP-15: "Đi tới" dòng trễ giờ đóng popup và hub sang tab Kết quả với chip "Trễ giờ"; TC-STEP-16: bấm đúp một bước chỉ mở một popup); chạy lại `flutter test --no-pub test/features/tournament/overview_date_direct_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/lifecycle_stepper.dart` (`LifecycleStepBar` dòng 79, `_Step` dòng 171), `lib/features/tournament/screens/tournament_management_section_screen.dart` (`TournamentLifecycleCard` dòng 1200, chỗ dựng `LifecycleStepBar` dòng 1313), `lib/features/tournament/screens/tournament_management_hub_screen.dart`; tạo `lib/providers/step_summary_provider.dart`, test `test/features/tournament/overview_step_popup_test.dart`
  - Giao: `LifecycleStepBar({super.key, required String status, ValueChanged<int>? onStepTap})` (chỉ số bước 0..3 theo `lifecycleStepIndex`); `final organizerParticipantsProvider = FutureProvider.autoDispose.family<List<OrganizerOpsParticipant>, String>` · Nhận: 1.2, 2.1, 2.2
  - Thực tế: `loadStepSummary(ref, tournament)` nằm trong `step_summary_provider.dart` (đọc VĐV + trận quản lý, chờ tối đa 3 giây rồi mở popup ở trạng thái "Đang tải"); "Tải lại" đóng popup, đọc lại rồi mở lại. TC-STEP-15 dùng chip "Tranh chấp" (không phụ thuộc giờ máy); chip "Trễ giờ" đã được TC-STEP-05 và TC-STEP-10 phủ
  - Chủ file chung: 2.3 giữ `lifecycle_stepper.dart` và `tournament_management_section_screen.dart`; hub chuyển sang 2.3 sau khi 1.2 xong
  - Phụ thuộc: sau 1.2, 2.2

## 3. Kiểm tra cuối

- [ ] 3.1 Phân tích tĩnh trên đúng các file đã sửa/tạo của change này và chạy test thư mục liên quan. Tiêu chí: `flutter analyze --no-pub` trên các file ở Files của 0.1 đến 2.3 → exit 0; `flutter test --no-pub test/features/tournament` → exit 0; `python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py` → exit 0; xem màn thật trên điện thoại qua app chung (`app-run.py status`) và chụp ảnh tab Kết quả cùng popup một bước
  - Files: không
  - Phụ thuộc: sau 2.3
