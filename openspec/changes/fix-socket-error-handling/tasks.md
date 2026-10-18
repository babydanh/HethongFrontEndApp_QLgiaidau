# Tasks

## 1. Chẩn đoán

- [x] 1.1 Xác định ca `WebSocketConnectionClosed` là lỗi vòng đời socket của app, không phải môi trường test. Bằng chứng: stack log `%TEMP%/cloud-test-39111478956-117628371847.log` dòng 3644–3666; `live-score.gateway.ts:104-123` (`client.disconnect(true)` sau 30 giây khi không ở phòng); `match_socket_service.dart` trước sửa `leave*`/`disconnect()`; `api_tournament_repository.dart:605,1124`. Mức: [INFERENCE], chưa có log socket runtime trong CI.

## 2. Sửa

- [x] 2.1 Đếm tham chiếu phòng: `lib/core/services/socket_room_ref_counter.dart`. Xong khi: unit test xanh. Bằng chứng: `flutter test --no-pub --no-test-assets test/core/services/socket_room_ref_counter_test.dart` → `All tests passed!` (7/7). Máy không có `.env` nên dùng `--no-test-assets`; test không đọc asset.
- [x] 2.2 `lib/core/services/match_socket_service.dart`: ref-count cho trận/giải/phiên CLB/cộng đồng, `_releaseIdleConnection`, bỏ `close()` thừa, bọc reconnect. Xong khi: `dart analyze` sạch trên 3 file. Bằng chứng: `dart analyze lib/core/services/socket_room_ref_counter.dart lib/core/services/match_socket_service.dart test/core/services/socket_room_ref_counter_test.dart` → `No issues found!`.
- [ ] 2.3 Ghi F4 (lỗi socket) và F5 (lỗi nhãn test đăng ký) vào `openspec/changes/app-e2e-integration/findings.md` kèm hash commit. Xong khi: có hash.

## 3. Kiểm trên cloud

- [ ] 3.1 Run `app-e2e` đầy đủ trên head chứa sửa: ca `tournament_player_flow_test.dart` không còn `WebSocketConnectionClosed`. Xong khi: có run id và kết quả ca đó trong log.
- [ ] 3.2 `npx openspec validate fix-socket-error-handling --strict` exit 0. Xong khi: có exit code.
