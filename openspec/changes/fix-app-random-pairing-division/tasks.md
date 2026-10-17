## 1. Util dùng chung

- [x] 1.1 Thêm `lib/core/utils/pair_generation_summary.dart` (`pairGeneratedLabels`, `pairUnpairedNames`, `unpairedDisplayNames` chuyển từ màn ghép cặp). Xong khi: `flutter test --no-pub test/core/utils/pair_generation_summary_test.dart` xanh.
- [x] 1.2 Thêm `lib/core/utils/api_error_message.dart` (`backendErrorMessage`). Xong khi: `flutter test --no-pub test/core/utils/api_error_message_test.dart` xanh.

## 2. Notifier

- [x] 2.1 `generatePairs` nhận `{divisionId}` (mặc định `soleActiveTournamentDivisionId`), trả body response. Xong khi: test notifier nhóm `generatePairs` xanh.
- [x] 2.2 `createBracket`: bỏ khối `pairs/generate` RANDOM và `catch`, trả body response. Xong khi: test notifier nhóm `createBracket` xanh và không có request `pairs/generate` trong log test.

## 3. Màn

- [x] 3.1 `lite_pairing_screen.dart` `_generatePairs`: gửi `divisionId` (`_divisionId`), hiện cặp và người lẻ từ response, lỗi hiện `backendErrorMessage`. Xong khi: test widget ghép ngẫu nhiên xanh.
- [x] 3.2 `lite_pairing_screen.dart` `_generateBracket` và `_fetchTournament`: lỗi 400 hiện nguyên văn; `_fetchTournament` ghi log thay vì nuốt lỗi. Xong khi: test widget tạo sơ đồ xanh.
- [x] 3.3 `lite_management_screen.dart`: nút ghép ngẫu nhiên hiện kết quả/lỗi; `_createBracket` hiện `autoPaired`/`unpairedNames` và lỗi Backend. Xong khi: `flutter analyze --no-pub lib test` không có lỗi trong file này.

## 4. Test

- [x] 4.1 Viết test unit/notifier/widget theo `design.md`. Xong khi: các file test mới đã được tạo và chạy xanh ở bước 5.2.
- [x] 4.2 Cập nhật `test/features/lite_participant_pairing_test.dart` để import `unpairedDisplayNames` từ util mới. Xong khi: file test xanh ở bước 5.2.

## 5. Kiểm chứng cuối

- [x] 5.1 `flutter analyze --no-pub lib test` không có lỗi (error = 0). Xong khi: kết quả analyze ghi rõ 0 error. Kết quả: 0 dòng `error`, 194 issue info/warning có sẵn của repo.
- [x] 5.2 `flutter test --no-pub` các file liên quan: pair_generation_summary, api_error_message, lite_management_pairing_request, lite_pairing_screen_request, lite_participant_pairing, bracket_generation_summary, api_tournament_generate_bracket. Xong khi: tất cả xanh. Kết quả: 27/27 PASS trên 7 file.
- [x] 5.3 `npx -y openspec validate fix-app-random-pairing-division --strict` pass. Xong khi: lệnh trả "is valid". Kết quả: "Change 'fix-app-random-pairing-division' is valid".
