## 1. Đọc điểm và gửi điểm từng VĐV

- [x] 1.1 `parseRosterScore` có cờ, đổi thang cột, đôi gộp giữ `player1Elo`/`player2Elo`, item gửi hai trường này. Tiêu chí: `flutter test --no-pub test/features/organizer_ops/roster_score_flags_test.dart` → exit 0
  - Files: `lib/features/organizer_ops/utils/roster_excel_parser.dart`, `lib/features/organizer_ops/utils/roster_pairing.dart`, `lib/domain/entities/roster_import.dart`, `lib/features/organizer_ops/screens/roster_import_sheet.dart`, test `test/features/organizer_ops/roster_score_flags_test.dart`
  - Giao: `RosterScore? parseRosterScore(String)`; `rosterRowScores(RosterParsedRow)`; `RosterParsedRow.player1Elo/player2Elo/eloFlags`

## 2. Hiển thị

- [x] 2.1 Dòng điểm trình trên thẻ đôi, cờ vàng; ẩn `memberElos` ở chi tiết participant. Tiêu chí: `flutter test --no-pub test/features/organizer_ops/` → exit 0
  - Files: `lib/features/organizer_ops/screens/roster_pair_card.dart`, `lib/features/tournament/widgets/participant_detail_sheet.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ `flutter gen-l10n`)
  - Phụ thuộc: sau 1.1

## 3. Kiểm cuối

- [x] 3.1 Tiêu chí: `flutter analyze --no-pub lib/features/organizer_ops lib/domain/entities/roster_import.dart lib/features/tournament/widgets/participant_detail_sheet.dart` → exit 0; `flutter test --no-pub test/features/organizer_ops/` → exit 0
