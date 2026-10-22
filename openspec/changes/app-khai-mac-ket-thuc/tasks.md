## 1. Hợp đồng và xử lý đăng ký theo division

- [ ] 1.1 Kiểm tra luật đăng ký theo trạng thái từng division và thêm ca hủy/mở/fallback ở cấp helper và nút đăng ký giải. Tiêu chí: `flutter test --no-pub test/features/register/division_selection_test.dart` và `flutter test --no-pub test/features/tournament_registration_cta_test.dart` → exit 0.
  - Files: `lib/domain/entities/tournament_registration.dart:1-178` (đọc, không cần sửa), `lib/features/register/utils/division_selection.dart:1-42` (đọc, không cần sửa), `lib/features/tournament/screens/tournament_intro_screen.dart:299-355` (đọc, không cần sửa), `lib/features/register/screens/tournament_register_screen.dart:442-495` (đọc, không cần sửa), `test/features/register/division_selection_test.dart:54-100`, `test/features/tournament_registration_cta_test.dart:162-265`
  - Giao: `isRegistrationDivisionActive(TournamentDivisionOption): bool` · Nhận: helper dùng bởi trình chọn division và màn đăng ký hiện hành
  - Chủ file chung: `test/features/register/division_selection_test.dart` và `test/features/tournament_registration_cta_test.dart`
  - Phụ thuộc: không

## 2. Vòng đời giải quản lý

- [ ] 2.1 Thêm start/complete vào repository quản lý, xác nhận trạng thái hợp lệ, khóa thao tác khi gửi, hiển thị cảnh báo thiếu sơ đồ, lỗi đúng message backend và reload chi tiết. Tiêu chí: `flutter test --no-pub test/features/tournament_management_hub_screen_test.dart` và `flutter test --no-pub test/tournament_management_repository_api_test.dart` → exit 0.
  - Files: `lib/domain/repositories/tournament_management_repository.dart:142-154`, `lib/data/repositories/api/api_tournament_management_repository.dart:508-523`, `lib/features/tournament/screens/tournament_management_section_screen.dart:787-974`, `lib/features/tournament/screens/tournament_management_hub_screen.dart:795-834`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_localizations.dart` và file sinh tương ứng, `test/features/tournament_management_hub_screen_test.dart:193-210,1020-1111`, `test/tournament_management_repository_api_test.dart:1102-1160`
  - Giao: `startTournament(String id): Future<Map<String, dynamic>>`, `completeTournament(String id): Future<Map<String, dynamic>>` · Nhận: thao tác gọi route `/tournaments/:id/start` và `/tournaments/:id/complete`
  - Chủ file chung: task này giữ `tournament_management_section_screen.dart`, hai file ARB, test hub và test API
  - Phụ thuộc: sau 1.1

## 3. Kiểm chứng tích hợp

- [ ] 3.1 Chạy kiểm tra tĩnh và test liên quan cho toàn bộ file đã sửa; chạy `openspec validate app-khai-mac-ket-thuc --strict`; chạy cloud app tests, ghi run ID và kết quả. Tiêu chí: kiểm tra tĩnh/test liên quan exit 0; validate strict pass; cloud app xanh.
  - Files: toàn bộ file ở task 1.1 và 2.1; `openspec/changes/app-khai-mac-ket-thuc/tasks.md`
  - Giao: (không) · Nhận: test đăng ký và lifecycle cùng qua
  - Chủ file chung: task này giữ `tasks.md`
  - Phụ thuộc: sau 1.1, 2.1
