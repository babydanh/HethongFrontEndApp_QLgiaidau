# Proposal

## Why

Run E2E `39111478956` (target `app-e2e`, ref `46c2d691`) đỏ ca `integration_test/tournament_player_flow_test.dart` với `WebSocketConnectionClosed` (log `%TEMP%/cloud-test-39111478956-117628371847.log`, dòng 3644–3666). Stack: `Socket.ondisconnect` → `Socket.destroy` → `Manager.close` → `Socket.close` (engine) → `WebSocketTransport.doClose` → `IOWebSocket.close` (`web_socket-1.0.1/lib/src/io_web_socket.dart:103-117`). Lỗi là Future không được await nên không bắt được ở call site.

Nguyên nhân nằm ở vòng đời phòng trong app, `lib/core/services/match_socket_service.dart`:

- Phòng không đếm tham chiếu. `leaveTournament` gỡ phòng giải dù còn watcher khác giữ (`lib/data/repositories/api/api_tournament_repository.dart:605` và `:1124`, hai nơi cùng giữ một giải). Watcher hủy trước làm watcher còn lại mất phòng.
- Socket không ngắt khi rỗng phòng. Backend `HethongBackendApi_QuanlyGiaiDau/src/modules/matches/live-score.gateway.ts:104-123` ngắt client không ở phòng nào sau 30 giây bằng `client.disconnect(true)`. Lệnh `disconnect(true)` đóng luôn kết nối engine.io, và thư viện ném lỗi ở trên.
- `disconnect()` gọi `_socket!.disconnect()` rồi `_socket!.close()`. `Socket.close()` là alias của `disconnect()` (`socket_io_client-3.1.6/lib/src/socket.dart:591`), nên teardown chạy hai lần.

Mức chắc chắn: [INFERENCE]. Chuỗi trên khớp stack và mã backend, nhưng CI không có log socket của app (`AppLogger` dùng `dart:developer.log`, `app_logger.dart:38-59`), nên không quan sát được trigger lúc chạy. Bằng chứng xác nhận là run `app-e2e` xanh sau sửa.

Ca này còn một lỗi test độc lập (không thuộc change này): test chờ nhãn "Đăng ký ngay" trên trang chi tiết giải, nhưng nhãn đó chỉ có ở màn đăng nhập. CTA thật là "Đăng ký" (`tournament_register_bar.dart:73`). Đã sửa trong test, ghi ở `app-e2e-integration/findings.md`.

## What Changes

- `lib/core/services/socket_room_ref_counter.dart` (mới): đếm tham chiếu cho một phòng. `retain` báo cần join khi là người giữ đầu tiên; `release` báo cần leave khi là người giữ cuối cùng.
- `lib/core/services/match_socket_service.dart`:
  - trận, giải, phiên CLB, cộng đồng dùng đếm tham chiếu; `leave*` chỉ emit leave khi người giữ cuối rời;
  - sau khi rời phòng cuối, `_releaseIdleConnection` ngắt socket để không giữ socket rỗng phòng;
  - bỏ lời gọi `close()` thừa trong `disconnect()`;
  - bọc `_socket!.connect()` của nhánh kết nối lại bằng try/log.
- `test/core/services/socket_room_ref_counter_test.dart` (mới): 7 unit test cho helper.

### Out of scope (KHÔNG làm)

- Không sửa `web_socket` hay `socket_io_client` (thư viện). Lỗi Future nội bộ của thư viện không bắt được ở call site; chỉ giảm trigger.
- Không đổi Backend. Ngưỡng 30 giây giữ nguyên.
- Không nới assertion hay bỏ ca test socket.

## Capabilities

### New Capabilities

(không có)

### Modified Capabilities

(không có: không có capability socket trong `openspec/specs/`.)

## Impact

- Repo App: `lib/core/services/match_socket_service.dart`, `lib/core/services/socket_room_ref_counter.dart` (mới), `test/core/services/socket_room_ref_counter_test.dart` (mới).
- Chữ ký public của `MatchSocketService` không đổi. Call site dùng `join`/`leave`/`connect`:
  - `lib/data/repositories/api/api_tournament_repository.dart:590-605`, `:1108-1124`;
  - `lib/data/repositories/api/api_match_repository.dart:263-349`, `:792`, `:898-899`;
  - `lib/providers/query_providers.dart:341-355` (viewerCountProvider);
  - `lib/features/match/screens/live_score_screen.dart:225`, `:259`;
  - `lib/features/community/widgets/club_activity_tab.dart`, `lib/features/community/screens/club_match_sessions_screen.dart`, `lib/features/register/screens/tournament_register_screen.dart`.
