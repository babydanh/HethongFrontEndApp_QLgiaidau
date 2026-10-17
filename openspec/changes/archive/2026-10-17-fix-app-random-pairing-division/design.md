## Thiết kế sửa ghép đôi và tạo sơ đồ Lite (App)

## Quyết định

### D1. divisionId của ghép ngẫu nhiên ở màn ghép cặp
Màn `LitePairingScreen` không có bộ chọn nội dung. `_divisionId` lấy bằng `liteSingleDivisionId(payload)`: chỉ có giá trị khi giải có đúng một nội dung. Mọi trường hợp khác là `null`, nên không gửi `divisionId` và để Backend trả 400.

### D2. divisionId của ghép ngẫu nhiên ở notifier
`LiteManagementNotifier.generatePairs(tournamentId, strategy, {divisionId})`. Khi không truyền, dùng `soleActiveTournamentDivisionId(state.tournament.divisions)` (đã có trong `lib/core/utils/tournament_division_id.dart`). Giải nhiều nội dung cho `null`, không đoán `divisions.first`.

### D3. Tạo sơ đồ không còn ghép trước
`createBracket` bỏ khối `pairs/generate` RANDOM và `catch`. Backend tự ghép trong nội dung của sơ đồ. `createBracket` trả body response để màn hiện `autoPaired`/`unpairedNames`.
`divisionId` của `createBracket` giữ nguyên `_liteDivisionId`: đây là hành vi đọc/reset đang dùng, không đổi trong change này.

### D4. Thông điệp lỗi từ Backend
Helper mới `backendErrorMessage(Object? error)` (`lib/core/utils/api_error_message.dart`) đọc `response.data['message']` của `DioException`. Có thì hiện nguyên văn; không có thì dùng thông điệp dự phòng cũ.

### D5. Parse response ghép cặp
`lib/core/utils/pair_generation_summary.dart`:
- `pairGeneratedLabels(raw)`: mỗi phần tử `paired[]` đổi thành `"A & B"` từ `memberNames`.
- `pairUnpairedNames(raw, namesById)`: ưu tiên `unpairedNames` của server; nếu thiếu/rỗng thì đổi `unpairedParticipantIds` qua map, id không có tên thành `#<id>`.
- `unpairedDisplayNames` chuyển từ `lite_pairing_screen.dart` sang util này để notifier và màn cùng dùng.

## Ràng buộc
- Không thêm shim hay nhánh dự phòng. Gọi Backend cũ không trả trường tuỳ chọn thì coi là rỗng.
- Không chạy `flutter analyze` hay `flutter test` ngoài danh sách đã ghi trong tasks; kiểm chứng chạy một lần sau khi hoàn tất.

## Kiểm chứng
- Unit: `test/core/utils/pair_generation_summary_test.dart`, `test/core/utils/api_error_message_test.dart`.
- Notifier: `test/providers/lite_management_pairing_request_test.dart` (fake Dio adapter): `createBracket` không gọi `pairs/generate`, gửi `divisionId`; `generatePairs` gửi `divisionId`; 400 giữ `message`.
- Widget: `test/features/lite/lite_pairing_screen_request_test.dart`: gửi `divisionId`, giải nhiều nội dung hiện đúng 400, tạo sơ đồ hiện người lẻ/cặp và không gọi `pairs/generate`.
