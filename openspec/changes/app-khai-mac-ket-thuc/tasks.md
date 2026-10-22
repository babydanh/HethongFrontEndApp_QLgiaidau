## 1. Hợp đồng và xử lý đăng ký theo division

- [x] 1.1 Kiểm tra luật đăng ký theo trạng thái từng division và thêm ca hủy/mở/fallback ở cấp helper và nút đăng ký giải. Tiêu chí: bộ Flutter test App đầy đủ trên cloud đạt exit 0.
  - Files: `lib/domain/entities/tournament_registration.dart:1-178` (đọc, không cần sửa), `lib/features/register/utils/division_selection.dart:1-42` (đọc, không cần sửa), `lib/features/tournament/screens/tournament_intro_screen.dart:299-355` (đọc, không cần sửa), `lib/features/register/screens/tournament_register_screen.dart:442-495` (đọc, không cần sửa), `test/features/register/division_selection_test.dart:54-100`, `test/features/tournament_registration_cta_test.dart:162-265`
  - Giao: `isRegistrationDivisionActive(TournamentDivisionOption): bool` · Nhận: helper dùng bởi trình chọn division và màn đăng ký hiện hành
  - Chủ file chung: `test/features/register/division_selection_test.dart` và `test/features/tournament_registration_cta_test.dart`
  - Phụ thuộc: không

## 2. Vòng đời giải quản lý

- [x] 2.1 Thêm start/complete vào repository quản lý, xác nhận trạng thái hợp lệ, khóa thao tác khi gửi, hiển thị cảnh báo thiếu sơ đồ, lỗi đúng message backend và reload chi tiết. Tiêu chí: bộ Flutter test App đầy đủ trên cloud đạt exit 0.
  - Files: `lib/domain/repositories/tournament_management_repository.dart:142-154`, `lib/data/repositories/api/api_tournament_management_repository.dart:508-523`, `lib/features/tournament/screens/tournament_management_section_screen.dart:787-974`, `lib/features/tournament/screens/tournament_management_hub_screen.dart:795-834`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_localizations.dart` và file sinh tương ứng, `test/features/tournament_management_hub_screen_test.dart:193-210,1020-1111`, `test/tournament_management_repository_api_test.dart:1102-1160`
  - Giao: `startTournament(String id): Future<Map<String, dynamic>>`, `completeTournament(String id): Future<Map<String, dynamic>>` · Nhận: thao tác gọi route `/tournaments/:id/start` và `/tournaments/:id/complete`
  - Chủ file chung: task này giữ `tournament_management_section_screen.dart`, hai file ARB, test hub và test API
  - Phụ thuộc: sau 1.1

- [x] 2.2 Một nút vòng đời theo việc tiếp theo như Web (người dùng chốt 2026-10-22): bỏ `lockTournament`/`/lock`, thêm `closeRegistration` (`/close-registration`); UPCOMING "Mở đăng ký ngay"; mở mà chưa có trận "Chốt đăng ký"; có trận hoặc đã đóng "Khai mạc giải" kèm ô "chốt luôn" khi còn mở; đã đóng thêm "Mở lại đăng ký". Tiêu chí: test TC-APP-LIFECYCLE-04/06/07 và test API lifecycle qua trên cloud.
  - Files: `lib/domain/repositories/tournament_management_repository.dart`, `lib/data/repositories/api/api_tournament_management_repository.dart`, `lib/features/tournament/screens/tournament_management_section_screen.dart`, `lib/features/tournament/screens/tournament_management_widgets.dart`, ARB + file sinh, `test/features/tournament_management_hub_screen_test.dart`, `test/tournament_management_repository_api_test.dart`
  - Phụ thuộc: sau 2.1
- [x] 2.3 Menu nội dung khoá/mở đăng ký mọi lúc trừ giải đã kết thúc/huỷ; quá hạn thì mở lại kèm hạn mới; thẻ ghi trạng thái đăng ký và "Không có hạn đăng ký". Tiêu chí: TC-APP-DIVLOCK-01/02/03 qua trên cloud.
  - Files: `lib/features/tournament/screens/tournament_management_divisions_section.dart`, `test/features/tournament_management_divisions_section_test.dart`
  - Phụ thuộc: sau 2.2
## 3. Kiểm chứng tích hợp

- [x] 3.1 Chạy kiểm tra tĩnh và test liên quan cho toàn bộ file đã sửa; chạy `openspec validate app-khai-mac-ket-thuc --strict`; chạy cloud app tests, ghi run ID và kết quả. Tiêu chí: kiểm tra tĩnh/test liên quan exit 0; validate strict pass; cloud app xanh.
  - Files: toàn bộ file ở task 1.1 và 2.1; `openspec/changes/app-khai-mac-ket-thuc/tasks.md`
  - Giao: (không) · Nhận: test đăng ký và lifecycle cùng qua
  - Chủ file chung: task này giữ `tasks.md`
  - Phụ thuộc: sau 1.1, 2.1
- Bằng chứng cloud: run ID `39724753066` — https://github.com/babydanh/agent-orchestrator/actions/runs/39724753066 — job “Test Flutter App (Dart Analyze & Widget)” thành công.
- Bằng chứng cloud cho 2.2/2.3 (App `c2d3dcc6`): run ID `39806384925` — https://github.com/babydanh/agent-orchestrator/actions/runs/39806384925 — analyze + toàn bộ widget test xanh. Lần chạy trước `39805362668` đỏ 2 ca TC-APP-LIFECYCLE-06/07 vì card so "REGISTRATION_OPEN" trong khi entity lưu mã chuẩn hoá "registration"; đã sửa.
- Mở lại khi hạn giải đã qua thì hỏi hạn mới (App `6d7a7808`, TC-APP-LIFECYCLE-08 + test API payload): run ID `39807816317` — https://github.com/babydanh/agent-orchestrator/actions/runs/39807816317 — xanh.
