## 1. Test và triển khai (đã làm theo TDD ở lượt Web; App viết test cùng lượt với code, xem handoff)

- [x] 1.1 Reader đọc vùng gộp (`roster_excel_reader.dart`, `Sheet.spannedItems`), `fillRosterMerges`.
  - Files: `lib/core/services/roster_excel_reader.dart`, `lib/features/organizer_ops/utils/roster_excel_parser.dart`
  - Tiêu chí: `TC-APP-ROSTER-PAIR-STT-05` xanh.
- [x] 1.2 Ghép cặp, phần lẻ, gợi ý đồng đội (`roster_pairing.dart`) và parser (slot `pairCode`, alias, `isPaid`, điểm).
  - Tiêu chí: `TC-APP-ROSTER-PAIR-STT-*`, `SECTION-SINGLES-*`, `PAID-DEFAULT-*`, `PARTNER-HINT-*` xanh.
- [x] 1.3 Guard, digest che dữ liệu, áp bố cục AI (`roster_layout.dart`, `roster_layout_digest.dart`), entity và repository AI (`api_roster_layout_repository.dart`).
  - Tiêu chí: `TC-APP-ROSTER-AI-LAYOUT-01..10` xanh.
- [x] 1.4 Màn nhập (`roster_import_sheet.dart`): đọc bằng luật, guard, gọi AI, trạng thái, gửi `isPaid`/`eloSource`; l10n vi/en + `flutter gen-l10n`.
  - Tiêu chí: `TC-APP-ROSTER-SHEET-01..05` xanh; test màn cũ xanh.

## 2. Kiểm tra

- [x] 2.1 `flutter test --no-pub test/features/organizer_ops` và `flutter analyze --no-pub lib/features/organizer_ops lib/core/services`.
- [x] 2.2 `openspec validate nhap-excel-cap-thanh-toan --strict`.
