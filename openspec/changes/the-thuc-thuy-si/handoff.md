# Bàn giao: the-thuc-thuy-si (App)
Cập nhật: 2026-10-22 · bởi: claude (subagent) · nhánh: thuy-si-20261021 · OpenSpec: the-thuc-thuy-si

## Mục tiêu
App Flutter hỗ trợ thể thức Thụy Sĩ: nhãn và chọn thể thức, cấu hình (số vòng, tiebreak kéo sắp, ghép vòng 1), xem (bảng xếp hạng phẳng theo `rank` Backend, lịch trận theo vòng, BYE), và màn Ghép cặp vòng N cho BTC (máy đề xuất → nhấn giữ kéo hoặc chọn từ bảng chọn → xác nhận, hoàn tác). Backend và Web có change cùng tên, cùng hợp đồng (`design.md`).

## Trạng thái
Cập nhật 2026-10-22 (cuối): xong và đã commit 4.1, 5.1, 5.2, 5.3 (đã đánh dấu) và kiểm cuối 6.1 (chạy kiểm, không sửa mã). Trước đó: xong 1.3, 2.1, 2.2, 3.1 (đã đánh dấu). 3.2 đã code và commit nhưng CHƯA đánh dấu: 8 test cũ trong `test/features/public_bracket_view_test.dart` (dùng `AppTheme.lightTheme`) đỏ sẵn khi chạy `--no-test-assets` (google_fonts không có AssetManifest; baseline 0 pass/8 fail trước khi sửa); 3 ca Swiss mới pass vì dùng `ThemeData` thường. Cần chạy file này có asset (cloud) để chốt tiêu chí 3.2.

Hoàn tất task 1.1–1.2; dừng trước 1.3 vì mâu thuẫn đặc tả ở map thể thức. Task 1.1: 21 test Swiss pass bằng `--no-test-assets` do thiếu asset `.env`; task 1.2: sinh l10n thành công, 70 khóa Swiss đủ và đồng nhất. Checkbox 1.1–1.2 đã đánh dấu; không sửa task 1.3.

## Đã thử: cách → kết quả → vì sao
- Tự tính Buchholz ở client → loại → lệch Backend; tin `rank` do Backend trả.
- Mỗi bàn là một `Card` có avatar → loại → người dùng yêu cầu phẳng, không khung lồng khung, ít icon.
- Dùng `lib/data/api_service.dart` → loại → file sinh, không được app import, bị ghi đè khi sinh lại.
- Nhét `roundConfig` vào `MatchModel` → loại → phình mô hình dùng chung; dùng `swissStageProvider` riêng.
- Kiểm kê 194 test cũ đã hoàn tất từ phiên trước; không lặp lại. Sau khi tiếp tục, task 1.1 đã xác nhận đỏ do ba file sản phẩm chưa tồn tại, rồi xanh với 21 test qua `flutter test --no-pub --no-test-assets ...`; bỏ qua bundling assets vì worktree không có `.env`.
- `app_constants.dart:126-150` định nghĩa các map thể thức; không có caller trong mã nguồn `lib/`. `TournamentCardV2` hiện dùng `l10n.bracketDisplayName` (`tournament_card_v2.dart:26`).
- Đã xác minh điều kiện quản lý trong `bracket_view_screen.dart` và API `updateDivisionConfig`; hai câu hỏi tương ứng ở handoff trước đã được giải quyết bằng code thật.
- Task 1.1: tạo `swiss.dart`, `swiss_round_state.dart`, `swiss_pairing_draft.dart`; bổ sung parser `fromJson` cho các DTO, request và ngoại lệ Swiss theo hợp đồng; test thuần chạy 21/21. `flutter analyze --no-pub lib/domain/entities lib/features/bracket/utils` không báo lỗi trong file mới, nhưng lệnh exit 1 vì info có sẵn tại `lib/domain/entities/tournament.dart:654` (`prefer_if_null_operators`).
- Task 1.2: thêm 70 khóa `swiss*` + tên thể thức Swiss vào hai ARB, chạy `flutter gen-l10n`; script scratchpad xác nhận 70/70 khóa khớp design và hai locale bằng nhau. File script tạm đã xóa.
- Ripwire `quality_delta` (HEAD `c13355c73` + dirty): `api-new-surface=0`, `sa=[]`; 173 `new-symbol` là DTO/hàm/khóa Swiss chưa được nối ở các task sau, 34 `preexisting-worse` là nền có sẵn. 28 finding gating đều thuộc `dead-code`/so trùng cấu trúc; `GroupStageConfig.moveParticipant` là hàm cũ, đã đọc và khác chữ ký/ngữ nghĩa với hàm Swiss. Các so trùng DTO, helper ngắn và chuỗi l10n giữ riêng theo contract; không thấy regression mới cần sửa.

- Task 1.3: `AppConstants` chỉ thêm `bracketSwiss`; `isSwissMatch` đặt ở `bracket_stage_utils.dart` và chặn Swiss khỏi `isKnockoutMatch/isGroupStageMatch/isDoubleEliminationMatch`, `MatchRoundLabel.isGroupOrRoundRobin/formatRound`. Nhãn/icon Swiss dùng l10n (icon thể thức Swiss dùng lại icon vòng tròn). `tournament_card_with_banner.dart` và `tournament_banner.dart` (ngoài danh sách có đường dẫn đúng nhưng số dòng khác plan) thêm nhánh Swiss; thêm import `app_constants.dart`.
- Task 2.1: `_orderByRank` trong `standings_provider.dart` sắp ổn định theo `rank` (dòng không rank xếp cuối); không dòng nào có rank thì giữ nguyên.
- Task 2.2: lỗi Dio của 4 hàm POST Swiss thành `SwissApiException` (status null = không có phản hồi); `getSwissStage`/`updateStageRoundConfig` để DioException nổi lên. Mã lỗi đọc từ `code` (hoặc `data.code`) của body; Backend chưa có code để đối chiếu hình dạng body thật. `updateStageRoundConfig` gọi `PATCH /tournaments/stages/:stageId` (coordinator sửa hợp đồng; `tasks.md`/`design.md` còn ghi đường dẫn cũ, coordinator sẽ sửa).
- Task 3.1/3.2: `SwissStandingsView` tin thứ tự đầu vào (provider đã sắp theo rank). Màn xem Swiss dùng chung `_selectedGroupTab` (0 = Xếp hạng, khác 0 = Lịch); vòng mặc định = vòng hiện tại, đặt một lần bằng `_selectedRound`, bộ chọn vòng là hàng `RoundFilterPill` (chạm lại để xem mọi vòng). `MatchTableRow`: Swiss có nhãn `Vòng N • Trận m`, BYE hiện nhãn `BYE` (`swissBye`) và ẩn bên đối thủ trống. Thêm `SwissBracketView` (public_bracket_view.dart): top 8 xếp hạng + trận vòng hiện tại, dùng ở trang công khai và `BracketDiagramScreen`.
- Test dùng `ThemeData` thường thay `AppTheme.lightTheme` ở file mới (swiss_standings_view_test, ca Swiss mới) vì không có asset trong worktree.

- Task 4.1: `SwissConfigEditor` (phẳng, `ReorderableListView` tay nắm `drag_indicator` + nút Lên/Xuống chữ, `Switch` bật/tắt tiêu chí, `RadioGroup` cho ghép vòng 1). Danh sách luôn đủ 7 tiêu chí: đang bật nằm trước theo thứ tự `tiebreakOrder`, tắt nằm sau; chỉ tiêu chí bật được gửi đi. Số vòng kẹp khi mất focus/submit: dưới = max(1, số vòng đã ghép) (hiện `swissConfigRoundsMinPlayed`), trên = min(30, max(1, số đội - 1)) (số đội 0/không rõ thì chỉ cap 30). Gắn vào hộp thoại cấu hình nội dung trong `tournament_management_divisions_section.dart`: nếu nội dung đang là Swiss thì tải `getSwissStage` + `getBracketMatches` trước khi mở hộp thoại (lỗi tải thì hiện lỗi chung, không mở); chưa có stage → ghi `roundConfig.swiss` vào payload `updateDivisionConfig` (kèm `isConfigOverride: true`, theo mẫu `buildDivisionConfigPatchPayload`); đã có stage → `updateStageRoundConfig(..., {'swiss': ...})` rồi invalidate `swissStageProvider`. Hộp thoại bọc `SizedBox(width: double.maxFinite)` vì danh sách tiebreak là viewport (đã kiểm không lỗi intrinsic).
- Task 5.1: `swissPairingProvider` là `NotifierProvider.autoDispose.family` (tránh nháp cũ khi mở lại màn). `errorKey` = mã API hoặc `NETWORK`/`UNKNOWN`. Sau mỗi `move`/`undo` `valid=false` đến khi `validate` (debounce 250 ms) trả về; lỗi validate (mạng) giữ `valid=false` + `errorKey`, lần chỉnh sau thử lại. Bản đề xuất vừa tải coi là `valid=true` (không gọi validate). Thêm `reload({keepErrorKey})` (dùng cho nút thử lại). Test dùng `fake_async` (phụ thuộc bắc cầu qua flutter_test, có `// ignore: depend_on_referenced_packages`, không đổi pubspec).
- Task 5.2: thêm 3 khóa l10n (CẢ vi/en): `swissApiErrorNetwork`, `swissApiErrorUnknown`, `swissPairingRetry` (design.md chưa có chữ cho lỗi mạng/thử lại). Không dùng animation tự thêm nên không đọc skill flutter-animation; chuyển động còn lại (bảng chọn, SnackBar) là của framework. Ký tự ngăn hai bên cặp là `–` (không dùng chữ "vs" để khỏi hardcode chữ). Tay nắm `Icons.drag_indicator` nằm trong từng tên (trang trí, `Semantics` "Giữ để kéo"); toàn thao tác kéo là nhấn giữ cả tên. Hàm `swissApiErrorText` công khai ở `swiss_pairing_screen.dart`, được dùng lại ở 5.3.
- Task 5.3: route đặt theo quy ước hiện có (không phải `/tournaments/:tournamentId/swiss-pairing` như tasks.md): `.../manage/swiss-pairing/:divisionId` (organizer) và `/admin/tournament/:id/swiss-pairing/:divisionId` (admin), query `stageId`, `round`, `total`; chung một `_swissPairingBuilder`. Widget `SwissRoundActions` (public) nằm cuối `bracket_view_screen.dart` (đúng danh sách Files, không tạo file mới); chỉ hiện khi `canManageGroupAssignment` (cờ có sẵn: `canEditBracket || admin`) và `swissStageProvider` đã có giá trị (không có thì tổng vòng chỉ là đoán). Điều kiện "chỉ người quản lý" nằm ở bracket_view_screen và KHÔNG có test (cần dựng cả `BracketViewScreen`); test chỉ phủ `SwissRoundActions`. Việc làm mới (`bracketMatchesWithDivisionProvider`, `swissStageProvider`) và thông báo `Đã tạo vòng N.` nằm trong `SwissPairingScreen` sau `confirm`, thoát bằng `Navigator.maybePop()` (không dùng `context.pop()` để test không cần GoRouter).
- Task 6.1: `flutter gen-l10n` exit 0, không khác biệt file sinh ngoài các khóa đã định; `flutter analyze --no-pub` các thư mục theo tiêu chí: 0 error, 0 warning, 59 info đều có sẵn (không info nào ở file mới; các info ở `tournament_management_divisions_section.dart` là `curly_braces` ở code cũ); `flutter test --no-pub --no-test-assets` 13 file Swiss/sửa: 115 pass, 0 fail; `public_bracket_view_test.dart` 8 đỏ sẵn (thiếu asset/google_fonts, đã nêu ở 3.2) + 3 ca Swiss pass, `bracket_filter_test.dart` pass. Chưa chạy: E2E/integration, `test/core/utils/elo_tier_test.dart` (đỏ sẵn trên main).

## Ràng buộc đang có
- Agent KHÔNG push `main`; không `git add -A`.
- Worktree không có `.env`: không đọc/in/chép/tạo `.env`; `flutter test` chạy với `--no-test-assets` để không đóng gói asset không cần thiết.
- Mọi chuỗi qua `app_vi.arb` + `app_en.arb` rồi `flutter gen-l10n`; không sửa tay file sinh.
- Không thêm package. Test nặng/E2E chạy trên cloud (skill `cloud-test-runner`), không cục bộ.
- Hợp đồng Backend ở `design.md` KHÔNG đổi tùy tiện; cần đổi thì ghi "Câu hỏi còn mở" và báo người dùng.
- Chỉ đánh `- [x]` sau khi tiêu chí task pass.

## Ràng buộc thay đổi lần này
So với lần trước: không đổi (đã so). Thêm 3 khóa l10n ngoài danh sách 1.2 (xem task 5.2) và dùng `fake_async` bắc cầu trong test (không đổi pubspec).

## Câu hỏi còn mở
- (Mới) Payload lưu cấu hình Swiss trước khi sinh sơ đồ: gửi `{matchType, bracketType, maxParticipants, isConfigOverride: true, roundConfig: {..., swiss}}` qua `PATCH /tournaments/:id/divisions/:divisionId/config`. `isConfigOverride` chép từ mẫu vòng bảng; chưa xác minh Backend Swiss có nhận `roundConfig.swiss` ở đường này (hợp đồng có nói "đường cấu hình division hiện có"). Cần xác nhận khi Backend xong.
- (Mới) Số đội cho trình chỉnh lấy từ `division['participantCount']` rồi `maxParticipants` của `GET /tournaments/:id/divisions`; chưa xác minh trường nào có thật (thiếu thì chỉ cap 30 vòng và mặc định vòng = 1).
- (Mới) `PATCH /tournaments/stages/:stageId` gửi `roundConfig: {swiss: <đủ 3 trường>}`; nếu Backend thay cả `roundConfig` thì mất khóa khác (stage Swiss hiện chỉ có `swiss`).
- (Mới) Màn ghép cặp không có test kéo-thả ở màn hẹp 320 dp (chỉ 360 và 800 dp); nút Lên/Xuống của editor tiebreak chưa kiểm vùng chạm ≥ 48 dp bằng test (TextButton mặc định 48 dp chiều cao).
- (Đã giải quyết) Task 1.3: không thêm chữ vào map của `AppConstants`, chỉ thêm hằng; nhãn từ l10n.
- Banner `tournament_card_with_banner.dart:533` hiện nhãn thể thức theo `format` (không phải `bracketType`): chỉ thêm nhánh Swiss theo `bracketType`.
- Tab Lịch Swiss: sau khi có vòng mới (poll), vòng đang chọn không tự nhảy sang vòng mới.
- Trang công khai `SwissBracketView` chỉ hiện top 8 xếp hạng ("thu gọn"); nếu cần đủ bảng thì đổi `_standingsLimit`.
- Chưa xác minh payload `/bracket` có `groupName`; thiết kế không phụ thuộc vì ưu tiên `stageType == 'SWISS'`.
- OpenSpec CLI `status`/`instructions apply` đã được thử nhưng không có JSON kết quả hiển thị trong runner; artifacts local đã đọc đầy đủ, plan không bị sửa.
