## 1. Hợp đồng repository

- [x] 1.1 `addAthleteDirect` nhận `phone`, `notes`, `elo`, `eloSource` và gửi đúng tên trường Backend (test đỏ trước). Tiêu chí: `flutter test --no-pub test/tournament_management_repository_api_test.dart` → exit 0
  - Files: sửa `lib/domain/repositories/tournament_management_repository.dart` (:170), `lib/data/repositories/api/api_tournament_management_repository.dart` (:285); test `test/tournament_management_repository_api_test.dart`; fake `test/organizer_ops/add_athlete_entry_test.dart`, `test/features/tournament_management_hub_screen_test.dart` (:246)
  - Giao: `Future<String> addAthleteDirect(String id, {required String name, String? email, String? phone, String? notes, double? elo, String? eloSource, String? tournamentDivisionId})` · Nhận: (không)
  - Chủ file chung: 1.1 giữ hai file repository và hai fake test
  - Phụ thuộc: (không)

## 2. Popup

- [x] 2.1 Header chỉ tiêu đề "Thêm VĐV"; form đủ trường (SĐT, Điểm, Loại điểm, Ghi chú) kèm kiểm điểm. Tiêu chí: `flutter test --no-pub test/organizer_ops/add_athlete_entry_test.dart` → exit 0
  - Files: sửa `lib/features/organizer_ops/screens/add_athlete_sheet.dart` (`_buildHeader` :221, `_buildDirectEntry` :633, `_submitGuest` :1128), `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ `flutter gen-l10n`); test `test/organizer_ops/add_athlete_entry_test.dart`
  - Chủ file chung: 2.1 giữ `add_athlete_sheet.dart` và hai file `.arb`
  - Phụ thuộc: 1.1
- [x] 2.2 Hàng chờ "Thêm vào danh sách", nút "Thêm (N)" gửi tuần tự, dòng lỗi ở lại. Tiêu chí: `flutter test --no-pub test/organizer_ops/add_athlete_entry_test.dart` → exit 0
  - Files: sửa `lib/features/organizer_ops/screens/add_athlete_sheet.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; test `test/organizer_ops/add_athlete_entry_test.dart`
  - Chủ file chung: 2.2 giữ `add_athlete_sheet.dart` sau 2.1
  - Phụ thuộc: 2.1

## 3. Kiểm tra cuối

- [x] 3.1 Analyze, test liên quan, ảnh máy thật (chỉ xem popup, không bấm Thêm). Tiêu chí: `flutter analyze --no-pub lib/features/organizer_ops/screens/add_athlete_sheet.dart lib/data/repositories/api/api_tournament_management_repository.dart` → exit 0; `flutter test --no-pub test/organizer_ops/add_athlete_entry_test.dart test/features/tournament_management_hub_screen_test.dart test/tournament_management_repository_api_test.dart` → exit 0
  - Phụ thuộc: 2.2
