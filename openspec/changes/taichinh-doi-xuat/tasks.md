## 1. Màn 19 Tài chính & thanh toán

- [x] 1.1 Nút Lưu lệ phí cố định ở đáy, form ngân hàng vào bottom sheet có xác nhận, lịch sử thành dòng mở danh sách. Tiêu chí: `flutter test --no-pub test/features/tournament_management_finance_section_test.dart test/features/finance_fee_quick_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/screens/tournament_management_finance_section.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/tournament_management_finance_section_test.dart`, `test/features/finance_fee_quick_test.dart`

## 2. Màn 20 Quản lý đội / VĐV

- [ ] 2.1 Ô tìm, chip lọc có số, tên 2 dòng, hàng gọn, menu ⋮ mỗi đội. Tiêu chí: `flutter test --no-pub test/features/team_list_screen_test.dart` → exit 0
  - Files: sửa `lib/features/teams/screens/team_list_screen.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/team_list_screen_test.dart`

## 3. Màn 21 Xuất báo cáo

- [ ] 3.1 `ExcelExportService.exportTournamentReport` + tên file lọc ký tự lạ. Tiêu chí: `flutter test --no-pub test/features/tournament_report_excel_test.dart` → exit 0
  - Files: sửa `lib/core/services/excel_export_service.dart`; test `test/features/tournament_report_excel_test.dart`
- [ ] 3.2 Sheet chọn nội dung + mục "Xuất báo cáo" trong menu ⋮ của hub. Tiêu chí: `flutter test --no-pub test/features/tournament_report_sheet_test.dart test/features/tournament_management_hub_screen_test.dart` → exit 0
  - Files: tạo `lib/features/tournament/widgets/tournament_report_sheet.dart`; sửa `lib/features/tournament/screens/tournament_management_hub_screen.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/features/tournament_report_sheet_test.dart`

## Chưa làm

Sheet Lịch/Tài chính/Hạng mục/Nhân sự của báo cáo: Web (`utils/tournamentWorkbook.ts`) chỉ có 5 sheet Overview/Divisions/Participants/Matches/Officials, không có sheet Tài chính; App chưa có endpoint tài chính theo giải. Chỉ làm sheet có dữ liệu sẵn.
