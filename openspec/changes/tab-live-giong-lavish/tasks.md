## 1. Avatar chuẩn Web
- [x] 1.1 `ParticipantSideLines`: avatar tròn 18px màu theo tên (bảng 8 màu và chữ đầu+cuối như Web), tên 12.5px, tích xanh 12px bên thắng. Tiêu chí: `flutter test --no-pub test/core/participants/participant_side_lines_test.dart` exit 0 (viết test đỏ trước).
  - Files: sửa `lib/core/participants/participant_display.dart`; test `test/core/participants/participant_side_lines_test.dart`
  - Giao: `Color avatarFallbackColor(String name)`, `String avatarInitials(String name)` công khai; `ParticipantSideLines({..., String? waitingFor})`
  - Chủ file chung: task này giữ `participant_display.dart`
  - Phụ thuộc: không

## 2. Bảng trận
- [x] 2.1 Chép CSS mockup vào `ResultsMatchBoard` và `ResultsMatchRow` (chip + số đếm, công cụ, đầu hộp pill, hàng trận, dòng phụ, "Chờ đội thắng"); chuỗi qua l10n vi/en + `flutter gen-l10n`. Tiêu chí: `flutter test --no-pub test/features/tournament/widgets/results_match_board_test.dart` exit 0.
  - Files: sửa `lib/features/tournament/widgets/results_match_board.dart`, `results_match_row.dart`; tạo `lib/features/tournament/widgets/results_board_palette.dart`; sửa `lib/l10n/app_vi.arb`, `app_en.arb`; test `test/features/tournament/widgets/results_match_board_test.dart`
  - Chủ file chung: task này giữ hai file arb và hai file board/row
  - Phụ thuộc: 1.1

## 3. Kiểm chứng
- [ ] 3.1 `flutter analyze --no-pub` file đã sửa; test hẹp; `app-run.py status`; chụp điện thoại thật so từng dòng bảng quy đổi. Tiêu chí: exit 0, lệch = 0 kèm ảnh.
  - Phụ thuộc: 2.1
