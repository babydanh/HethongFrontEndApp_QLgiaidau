# Kế hoạch triển khai

## Đã xong (trước khi có plan này)
- P0 Repository + entity: `lib/domain/repositories/tournament_management_repository.dart`, `lib/data/repositories/api/api_tournament_management_repository.dart`, `lib/domain/entities/roster_import.dart` (mới), `lib/domain/entities/add_athlete_candidate.dart`. Chưa analyze.

## Quyết định (chốt cho P1–P3)
- P1 (parser). Lỗi cục bộ chỉ gồm `MISSING_NAME` (thiếu cả tên lẫn email, theo web), `MISSING_EMAIL`, `INVALID_EMAIL`, `DUPLICATE_IN_FILE`. Không có `PLAYER2_INCOMPLETE` (web không có; email VĐV 2 là tùy chọn). `PLAYER2_REQUIRED` / `PLAYER2_NOT_ALLOWED` để server quyết.
- P1. Bỏ dòng khi name, teamName, email, phone đều rỗng (theo web).
- P1 (khác web). Elo: nếu khớp `^\d{1,3}([.,\s]\d{3})+$` thì bỏ dấu phân nghìn rồi parse số nguyên; không parse được → null. Web dùng `parseFloat` nên "1,250" thành 1 (lỗi web, không sao chép).
- P1 (khác web). Token paid: giữ token VI/EN theo web; bỏ token tiếng Nga của web (không đưa tiếng Nga vào code).
- P2. Preview tự chạy lại khi đổi plan (theo web). Tri-state tài khoản theo `03-endpoint-contract.md`.
- P3 (theo web, cây được phép). Thêm nhiều VĐV TUẦN TỰ (vòng `for`), dừng ở lỗi đầu tiên. Lỗi giữ lựa chọn.
- P3. `AddAthleteSheet` nhận thêm `String? divisionMatchType` (từ caller). Caller là `tournament_management_athletes_tab.dart`, do P2 sửa.

## Phần việc theo file (mỗi file một chủ)
- P1 Parser (agent RosterParser): `lib/core/services/roster_excel_reader.dart` (mới), `lib/features/organizer_ops/utils/roster_excel_parser.dart` (mới), `lib/core/services/roster_template_service.dart` (mới), `test/features/organizer_ops/roster_excel_parser_test.dart` (mới).
- P2 UI nhập Excel (agent RosterImportUI): `lib/features/tournament/widgets/tournament_management_athletes_tab.dart` (nút Nhập Excel `athletes-import-excel`, Tải mẫu `athletes-download-template`, truyền `divisionMatchType`), `lib/features/organizer_ops/screens/roster_import_sheet.dart` (mới).
- P3 Thêm VĐV (agent AddAthleteParity): `lib/features/organizer_ops/screens/add_athlete_sheet.dart`; `test/organizer_ops/add_athlete_entry_test.dart` (switch có nhánh `email`, override `addAthleteDirect` có `email`); `test/features/tournament_management_hub_screen_test.dart` (override `addAthleteDirect` có `String? email`).
- P4 Phụ InteractiveViewer (lead): `lib/features/match/screens/live_score_screen.dart` `_buildBracketOverlay` (dòng ~2084) và `_bracketRounds` (~2107): `InteractiveViewer(constrained: false)`, bỏ `SingleChildScrollView` ngang (2119) và dọc trong cột vòng (2153), kiểm tra trạng thái rỗng trước InteractiveViewer.

## Thứ tự
1. Chạy song song P1, P2, P3 (file tách rời, trừ caller P2 sửa tham số P3 đã định nghĩa).
2. Sau khi cả ba xong: lead chạy `dart analyze` theo file, rồi test mới và test liên quan, rồi build APK một lần.
3. Cài máy `aa785b1a` và kiểm tra thủ công phần không tự động được.

## Ngoài phạm vi (không làm trong change này)
- Hub Bracket redesign; khoá nút xếp lô; seed/categoryName/h2hStat.
