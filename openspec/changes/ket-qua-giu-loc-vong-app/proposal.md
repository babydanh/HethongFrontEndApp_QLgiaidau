## Why

Tab "Kết quả" của App ở nội dung đã xong (có bục trao giải) chỉ đưa trận chung kết vào bảng (`finalOnly` cắt danh sách bằng `pickFinalMatches`). Bảng còn một vòng nên menu "Tới vòng" vô nghĩa, chip đếm sai, người xem không xem lại được vòng bảng, tứ kết, bán kết. Chủ repo yêu cầu làm giống bản sửa Web `ket-qua-cong-khai-loc-vong`: giữ bộ lọc, chỉ mở sẵn chung kết.

## What Changes

- `ResultsMatchBoard` đổi `finalOnly` thành `focusFinal`: bảng nhận đủ trận của nội dung; chip, ô tìm, "Tới vòng" đủ các vòng.
- Nội dung đã có bục: hộp vòng chứa trận chung kết mở sẵn, các vòng khác gập.
- Hàm mới `focusResultsRoundKey(rounds, matchIds)` trong `results_rounds.dart`; không có chung kết thì giữ `defaultResultsRoundKey` như cũ.
- `ResultsMergedTab` truyền `focusFinal: hasPodium`.

## Out of scope

- Không đổi Backend, Web; không đổi luật chọn chung kết (`pickFinalMatches`).

## Capabilities

### New Capabilities
- `app-results-final-focus`: nội dung đã xong giữ mọi vòng trên bảng Kết quả App, chỉ mở sẵn chung kết.

### Modified Capabilities
(không có)

## Impact

- `lib/features/tournament/utils/results_rounds.dart`, `lib/features/tournament/widgets/results_match_board.dart`, `lib/features/tournament/widgets/results_merged_tab.dart`
- Test: `test/features/tournament/widgets/results_match_board_test.dart` (TC-RESULTS-APP-FINAL-01..02)
