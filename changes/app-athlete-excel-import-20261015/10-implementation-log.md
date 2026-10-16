# Nhật ký triển khai

## Giai đoạn đầu (repository và entity)
- `lib/domain/repositories/tournament_management_repository.dart`: `addAthleteDirect` thêm `email`, `tournamentDivisionId`; thêm `searchAddAthleteCandidates`, `addAthletePairs`, `previewRosterImportBatch`, `importRosterBatch`.
- `lib/data/repositories/api/api_tournament_management_repository.dart`: triển khai 4 method trên. `addAthleteDirect` gửi `email`. `importRosterBatch` tính `Idempotency-Key` = `roster:<id>:<sha256(JSON chuẩn hoá)>`.
- `lib/domain/entities/roster_import.dart` (mới). `lib/domain/entities/add_athlete_candidate.dart`: thêm `AddAthleteSource.email`, `AddAthleteSearchCandidate`, `AddedAthletePair`.
- `RosterImportBatchItem.teamName` là bắt buộc, luôn có trên wire (backend `IsString`).

## Subagent (kết quả đã kiểm lại bằng lệnh của lead)
- RosterParser: tạo `lib/features/organizer_ops/utils/roster_excel_parser.dart`, `lib/core/services/roster_excel_reader.dart`, `lib/core/services/roster_template_service.dart`, `test/features/organizer_ops/roster_excel_parser_test.dart`. Trạng thái: đã dừng.
- AddAthleteParity: sửa `lib/features/organizer_ops/screens/add_athlete_sheet.dart`, `test/organizer_ops/add_athlete_entry_test.dart`, `test/features/tournament_management_hub_screen_test.dart`. Trạng thái trả về: DONE_PENDING_LEAD_VERIFY.
- RosterImportUI: tạo `lib/features/organizer_ops/screens/roster_import_sheet.dart`; sửa `lib/features/tournament/widgets/tournament_management_athletes_tab.dart` (nút Nhập Excel, Tải mẫu, truyền `divisionMatchType`); thêm khoá l10n vào 5 file l10n. Trạng thái trả về: DONE_PENDING_LEAD_VERIFY.
- Quyết định lead đã gửi cho các agent:
  - `divisionMatchType` là tham số bắt buộc, kiểu `String?`. null nghĩa là không bật chế độ cặp.
  - Giữ tab "Nhập tên" cho khách, khách có thêm email.
  - RosterImportUI sở hữu tab VĐV và toàn bộ file l10n. AddAthleteParity không sửa l10n.
  - Thêm nhiều VĐV tuần tự, dừng ở lỗi đầu tiên (theo cây web được phép).
  - Preview chạy lại khi đổi tài khoản hoặc plan (theo web).

## Lead tự sửa
- `lib/features/organizer_ops/screens/organizer_ops_screen.dart`: caller thứ hai của `AddAthleteSheet` truyền `divisionMatchType: division.matchType`.
- `lib/features/match/screens/live_score_screen.dart` (pan sơ đồ nhánh đấu): `InteractiveViewer` đặt `constrained: false`; bỏ hai `SingleChildScrollView` lồng nhau; nhánh trạng thái rỗng `_bracketEmpty` tách riêng.
- `lib/features/organizer_ops/utils/roster_excel_parser.dart`: thêm slot `notes` (cột "Ghi chú") và `RosterParsedRow.notes`. Lý do: mẫu Excel app tải về có cột này, web gửi nó vào `customResponses.notes`, bỏ đi sẽ mất dữ liệu lặng lẽ. Bản đầu của parser đã bỏ `notes` có chủ đích; sửa lại sau khi đối chiếu.
- `test/tournament_management_repository_api_test.dart`: thêm nhóm "roster import batches" (4 test: route preview, `teamName` và provenance trên commit, cùng payload thì cùng Idempotency-Key, payload khác thì khác key) và 1 test email cho `addAthleteDirect`.
- Khoá l10n `opsAddAthleteSearchNameHint` đã obsolete (sheet cũ dùng, không còn chỗ nào dùng): xoá khỏi `app_vi.arb`, `app_en.arb`, `app_localizations.dart`, `app_localizations_vi.dart`, `app_localizations_en.dart`.
- Probe tạm `test/tmp_pan_probe_test.dart` đã xoá (đã xác nhận `No such file`).

## Quyết định về nơi làm việc
- AGENTS.md mục 2 yêu cầu worktree cho 3 repo đồ án. Cảnh báo đề nghị chuyển sang worktree trước khi sửa tiếp. User chọn ở lại repo chính. Đây là ngoại lệ theo AGENTS.md mục 2: người dùng nói rõ làm trực tiếp trên thư mục hiện tại.
- Hệ quả: repo có khoảng 50 file sửa và 57 file mới của session khác. Khi commit chỉ `git add` đúng file của phiên này, không `git add .`.

## Lỗi quy trình đã sửa
- Chạy `workflow/harness/new-change.ps1` với `ProjectRoot` là thư mục cha `D:/Duancanhan/Project_QuanLyGiaiDau/`. Harness tạo `changes/app-athlete-excel-import-20261015/` với 17 file ở cha. Đây là vi phạm quy tắc cấm ghi plan vào thư mục cha.
- Đã xoá đúng thư mục đó, xác nhận `REMOVED`. Không xoá gì khác.
- Artifact được viết lại trong repo App theo cấu trúc này.

## Lưu ý để user quyết
- Thư mục cha còn `changes/live-overlay-web-parity/` (chưa validate). Theo quy tắc cấm ghi plan vào thư mục cha, cân nhắc chuyển vào repo App. Chưa làm.
