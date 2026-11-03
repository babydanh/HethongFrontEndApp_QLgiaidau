## 1. Test và code
- [x] 1.1 Mốc Kết thúc giải + focus `tournamentClosing`. Tiêu chí: `flutter test --no-pub test/features/tournament/overview_edit_test.dart` → exit 0
  - Files: sửa `lib/features/tournament/widgets/overview_tab.dart`, `screens/tournament_management_section_screen.dart`, `widgets/tournament_edit_popup.dart`
- [x] 1.2 Con mắt banner. Tiêu chí: cùng file test → exit 0
  - Files: sửa `widgets/tournament_management_header.dart`, `screens/tournament_management_hub_screen.dart`
- [x] 1.3 Con mắt Ban tổ chức (`founderVisibilityPatch`). Tiêu chí: cùng file test → exit 0
  - Files: sửa `utils/tournament_contact.dart`, hub screen
- [x] 1.4 Khung `TournamentEditSheet`. Tiêu chí: cùng file test → exit 0
  - Files: tạo `widgets/tournament_edit_sheet.dart`; sửa `tournament_edit_popup.dart`
- [x] 1.5 Bốn mốc ngày: bấm là ra bộ chọn, lưu ngay; mốc khai mạc/bế mạc không bị khoá khi giải đã đóng đăng ký (server chỉ khoá ngày đăng ký). Tiêu chí: `flutter test --no-pub test/features/tournament/overview_date_direct_test.dart` → exit 0
  - Files: sửa `screens/tournament_management_section_screen.dart`, `widgets/tournament_edit_popup.dart`; test `test/features/tournament/overview_date_direct_test.dart`, `test/features/tournament_management_hub_screen_test.dart`
## 2. Kiểm
- [x] 2.1 `flutter analyze --no-pub lib/features/tournament` + test liên quan → exit 0
