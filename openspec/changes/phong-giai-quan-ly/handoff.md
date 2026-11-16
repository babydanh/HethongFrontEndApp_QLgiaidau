# Handoff: phòng giải, quyền chủ giải + thông báo vào/ra
<!-- Đọc file này TRƯỚC khi làm. Cập nhật TRƯỚC khi báo xong. -->
Cập nhật: 2026-11-16 · bởi: claude (local) · nhánh: phong-giai-quan-ly · OpenSpec: không có (plan đầy đủ ở dưới, người dùng đã duyệt theo đề xuất A)

## Mục tiêu
Phòng chat giải đấu (`chat_rooms.type='TOURNAMENT'`, đã lên main: chỉ người đã đăng ký mới vào, chờ duyệt thì chỉ đọc, BTC/admin/trọng tài đi qua). Việc này: (1) chủ giải có ĐỦ quyền quản phòng (kick, gỡ kick, danh sách bị kick, danh sách người trong phòng, cấm nhắn tạm, chỉnh giãn cách, khoá/mở phòng); (2) có thông báo người vào/ra phòng; (3) vá 2 lỗ hổng: người mất tư cách vẫn nghe phòng, bình chọn (poll) lách luật đăng ký. Backend (hợp đồng) làm đầu tiên; Web và App làm theo hợp đồng bên dưới, đọc phòng thủ khi thiếu trường (chạy được với Backend cũ).

## Quyết định người dùng đã chốt (đề xuất A, 2026-11-16)
- **Q1 sự kiện báo:** CHỈ: lần đầu vào phòng, bị BTC mời ra, được cho vào lại, mất tư cách (đăng ký bị từ chối/rút/hết hạn/huỷ mà không còn đăng ký hợp lệ khác). KHÔNG báo mỗi lần mở/đóng popup, mất mạng, tải lại trang. "Ra" = bị đá hoặc mất tư cách, không phải ngắt kết nối.
- **Q2 ai thấy:** dòng "tham gia" cho CẢ PHÒNG; dòng kick / gỡ kick / mất tư cách CHỈ BTC (moderator) thấy, lọc ở BACKEND (khi trả tin và khi phát realtime), không lọc ở client. Người bị kick nhận thông báo riêng (dịch vụ thông báo có sẵn).
- **Q3 bộ quyền chủ giải:** kick + gỡ kick + danh sách bị kick (kèm ai kick, lúc nào) + danh sách người trong phòng (đã đăng ký, trạng thái duyệt, online, bị kick/cấm nhắn) + cấm nhắn tạm (15 phút / 1 giờ / 1 ngày, vẫn đọc được) + chỉnh giãn cách 0–60 giây + khoá/mở phòng (khoá = chỉ BTC/admin nhắn được).
- **Q4 ai là chủ giải:** người tạo giải, đồng BTC, quản lý CLB chủ quản VÀ admin hệ thống (bộ `isManager` + ADMIN). Họ ngang quyền, KHÔNG kick/cấm nhắn nhau, không kick/cấm admin.

## Luật quyền
| Hành động | VĐV đã duyệt | Chờ duyệt | Trọng tài | BTC / đồng BTC / quản lý CLB | Admin |
|---|---|---|---|---|---|
| Đọc, nhắn (giãn cách) | có | đọc | có | có, miễn giãn cách | có |
| Thu hồi tin của mình | có | không | có | có | có |
| Thu hồi tin người khác, ghim | không | không | không | có | có (MỚI) |
| Kick, gỡ kick, xem danh sách bị kick | không | không | không | có (gỡ kick + danh sách là MỚI) | có (MỚI) |
| Xem danh sách người trong phòng | không | không | không | có (MỚI) | có (MỚI) |
| Cấm nhắn tạm, giãn cách, khoá/mở | không | không | không | có (MỚI) | có (MỚI) |
Mọi kiểm tra quyền nằm MỘT chỗ: `TournamentChatAccessService` (cùng chỗ luật đăng ký), HTTP và WebSocket dùng chung.

## Hợp đồng API (CHỈ THÊM, không đổi/xoá trường cũ; App/Web cũ phải chạy)
- `GET /tournaments/:id/chat-room` (200): thêm `canModerate: boolean` (BTC/đồng BTC/quản lý CLB/admin). Giữ nguyên `role`, `registration`, `name`, `logoUrl`, `canWrite`... `role:'ORGANIZER'` giữ nghĩa cũ (isManager); admin có `canModerate:true`.
- `GET /chat/rooms/:id/kicks` (đã có): mỗi phần tử thêm `fullName`, `avatarUrl`, `kickedByName`, `kickedAt` (kiểm response hiện tại trước, giữ trường cũ).
- `GET /chat/rooms/:id/participants?limit&cursor` (MỚI, chỉ moderator): `{items:[{userId, fullName, avatarUrl, registration:'APPROVED'|'PENDING'|'STAFF', online:boolean, kicked:boolean, mutedUntil:string|null}], nextCursor}`.
- `POST /chat/rooms/:id/mutes` body `{userId, minutes: 15|60|1440}` và `DELETE /chat/rooms/:id/mutes/:userId` (MỚI, moderator; không cấm được BTC/admin: 403 `CANNOT_MUTE_ORGANIZER`).
- `PATCH /chat/rooms/:id/settings` body `{slowModeSeconds?: 0..60, locked?: boolean}` (MỚI, moderator; ngoài khoảng → 400).
- Lỗi 403 mới khi gửi: `TOURNAMENT_CHAT_MUTED` (kèm `until` ISO), `TOURNAMENT_CHAT_LOCKED`.
- Tin hệ thống: `chat_messages.type='SYSTEM'` (cột `type` varchar(32) đã có, KHÔNG đổi cột). `content` là câu tiếng Việt đọc được sẵn (client cũ hiển thị như văn bản thường); `metadata` (kiểm tên cột metadata thật của chat_messages trước) `{event:'JOINED'|'KICKED'|'UNKICKED'|'EVICTED', userId, visibleTo:'ALL'|'MODERATORS'}`. Người gửi null nếu schema cho phép, nếu không thì dùng người thực hiện.
- Socket mới: `chat:room:presence {roomId, online:number}` (chỉ moderator; đếm socket trong kênh `chat:{roomId}`, không lưu DB), `chat:room:settings {roomId, slowModeSeconds, locked}` (cả phòng), `chat:room:evicted {roomId, reason:'REGISTRATION_LOST'}` (chỉ người mất tư cách; client bỏ phòng, báo thân thiện). Giữ `chat:room:kicked` cho kick như cũ.

## Dữ liệu mới (migration CHỈ THÊM, `IF NOT EXISTS`, chạy lại an toàn; theo mẫu `2026-11-16_tournament_chat_room.sql` đã chạy production qua `run-prod-migration.js`)
- `chat_room_joins(room_id uuid, user_id uuid, joined_at timestamptz default now(), PRIMARY KEY(room_id,user_id))` (khoá chính chặn trùng: bấm đúp/2 tab không tạo thêm dòng "tham gia"; lần ghi thành công đầu tiên mới tạo tin SYSTEM; xoá theo phòng khi xoá phòng như lịch dọn 12 tháng).
- `chat_room_mutes(room_id, user_id, muted_by, until timestamptz, created_at, PRIMARY KEY(room_id,user_id))`.
- `chat_rooms.locked boolean not null default false` (kiểm cột hiện có trước: `slow_mode_seconds` đã có).

## Ràng buộc đang có (không được phá)
- Luật đăng ký đã lên main (Backend `f2240711`, Web `d73138e1`): NOT_REGISTERED/PENDING/APPROVED/STAFF, 403 `TOURNAMENT_CHAT_NOT_REGISTERED`/`_NOT_APPROVED`, `canWrite`, `registration`. KHÔNG đổi nghĩa.
- Kick hiện có: chỉ BTC, `CANNOT_KICK_ORGANIZER`, socket `chat:room:kicked`. Giữ; chỉ mở rộng quyền cho admin và thêm danh sách/gỡ kick.
- Admin hiện nhận `registration:'STAFF'` qua `ChatRepository.isSystemAdmin` (đọc `user_to_roles`, không truyền systemRoles). Dùng lại cho quyền quản trị.
- Không phá hợp đồng cũ; không đổi chữ ký hàm công khai ngoài phạm vi. Mọi thứ cộng thêm.
- Test hẹp ở máy, nặng (E2E, `flutter analyze`, cả bộ test App, E2E Web) trên GitHub Actions (cloud-test-runner). Không chạy Playwright local.

## Test cần có (TDD, đỏ trước; mã ca ghi trong tên test)
- TC-CHAT-MOD-01 admin + BTC kick/gỡ kick được; VĐV/trọng tài 403 `NOT_ORGANIZER`; không kick được BTC/admin (`CANNOT_KICK_ORGANIZER`).
- TC-CHAT-MOD-02 `GET kicks` trả tên người bị kick, tên người kick, thời điểm.
- TC-CHAT-MOD-03 mute: gửi 403 `MUTED` tới hết hạn rồi gửi lại được; vẫn đọc được; không mute được BTC/admin.
- TC-CHAT-MOD-04 khoá phòng: VĐV không gửi được, BTC vẫn gửi; giãn cách 0–60, ngoài khoảng bị từ chối.
- TC-CHAT-EVT-01 lần đầu vào tạo ĐÚNG 1 tin SYSTEM; vào lại / bấm đúp / 2 tab không tạo thêm.
- TC-CHAT-EVT-02 kick tạo tin SYSTEM chỉ moderator thấy (lọc ở Backend khi trả tin và khi phát); người bị kick nhận thông báo riêng.
- TC-CHAT-EVT-03 đăng ký chuyển REJECTED/WITHDRAWN/KICKED/EXPIRED/CANCELLED: socket bị đá + `chat:room:evicted`; còn đăng ký hợp lệ khác thì KHÔNG đá.
- TC-CHAT-ACL-06 `votePoll` người chưa đăng ký bị 403.
- TC-CHAT-UI-M-01..03 (Web/App) nút quản lý chỉ hiện với `canModerate`; dòng SYSTEM hiển thị; chịu payload Backend cũ.

## Triển khai và QUYỀN ĐÃ ĐƯỢC NGƯỜI DÙNG CHO (2026-11-16, nguyên văn: "đẩy lên cloud làm xong kêu nó lên staging main")
Xong code + test xanh thì tự đi tiếp, KHÔNG cần hỏi lại:
1. Backend và Web: `python3 ~/bin/staging-sync.py <worktree Backend> <worktree Web> --branch phong-giai-quan-ly` (chỉ repo có nhánh; chờ deploy staging xanh; thử nhanh tay bằng test/E2E cloud nếu có spec phù hợp).
2. Rồi lên main CHỈ qua `python3 ~/bin/merge-lane.py <worktree> --check "<test hẹp>" --push` (không bao giờ `git push` trực tiếp main/staging). Việc chạm file dùng chung (i18n, `scoped-messages.ts`, `app_localizations*`) cần `--e2e-specs` / cổng cloud: chọn spec liên quan. `merge-lane` chạy lệnh `--check` bằng cmd: dùng `node node_modules/jest/bin/jest.js ...` (không `node_modules/.bin/jest`); `tsc` cần `NODE_OPTIONS=--max-old-space-size=6144`. Trước khi lên main: `git rm -r openspec/changes/phong-giai-quan-ly` rồi commit (thư mục bàn giao này không được lên main).
3. THỨ TỰ BẮT BUỘC: **Backend → Web → App**. Backend lên main và deploy production xanh trước (chờ run deploy trong `babydanh/agent-orchestrator` xong; lỗi "Kiểm commit đích" thoáng qua thì `gh run rerun <id> -R babydanh/agent-orchestrator --failed`). Web và App CHỈ lên main sau khi Backend main đã chứa route `GET /chat/rooms/:id/participants` (kiểm: `git -C <repo Backend> fetch origin && git -C <repo Backend> grep -n participants origin/main -- src/modules/chat/chat.controller.ts`). Mỗi lần chỉ một deploy (VPS dùng chung).
4. Báo kết quả mỗi bước (commit, mã thoát thật, link run), rồi `cloud-xong <việc>`. Thất bại sau 3 vòng sửa hoặc đụng secret/migration production lỗi: dừng và báo người dùng.

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| Giao cho máy cloud lần 1 (fast-handoff) | thất bại | 4 máy đủ 3 việc, danh5 chưa clone repo, số còn lại ngủ (exit 7); đã đánh thức danh4 và giao lại 2026-11-16 |
| Rebase lên main (2026-11-17) | xong | bỏ 2 commit đăng ký cũ (đã squash thành 5cdf5b3b), giữ handoff; giao lần 2 qua fast-handoff |

## Ràng buộc thay đổi lần này
- Thêm: toàn bộ phần trên (quyền moderator, tin SYSTEM, mute/lock, eviction).
- Bỏ: không.

## Câu hỏi còn mở
- không (đã chốt Q1–Q4 theo A). Nếu gặp tên cột metadata/sender null không khớp giả định: chọn cách tối thiểu, ghi vào báo cáo.

---
# PHẦN RIÊNG: APP FLUTTER (repo HethongFrontEndApp_QLgiaidau, nhánh phong-giai-quan-ly tách từ nhánh phong-giai-dang-ky, commit `a98c9e2f`)
Nhánh này nằm TRÊN commit `a98c9e2f` "registration-aware chat entry" (luật đăng ký ở App) vốn đang qua cổng gộp lên main. Bạn làm phần App theo hợp đồng trên (Backend làm song song; parse phòng thủ). Đọc code thật: `lib/domain/entities/tournament_chat_room.dart`, `lib/domain/repositories/tournament_chat_repository.dart` + `lib/data/repositories/api/api_tournament_chat_repository.dart` (đã có `kickRoomUser`/`unkickRoomUser`), `lib/providers/tournament_chat_provider.dart`, `lib/features/chat/screens/chat_detail_screen.dart` (`_canKick` ~1013, kick ở ~1227, `_handleAccessError`), `lib/core/router/app_router.dart` (route `/chat/:id`), arb `lib/l10n/app_vi.arb`, `app_en.arb`.

Việc:
1. Entity + repository: parse `canModerate`; thêm `listKicks`, `listParticipants`, `mute`, `unmute`, `updateSettings`; model tin `SYSTEM`.
2. `chat_detail_screen.dart`: hiển thị tin SYSTEM (nhỏ, giữa); `_canKick` và các nút quản trị dựa `canModerate`; màn/bottom sheet "Quản lý phòng" 3 tab (Người trong phòng: kick/cấm nhắn; Bị kick/bị cấm: gỡ; Cài đặt: giãn cách 0-60, khoá/mở); xử lý lỗi `TOURNAMENT_CHAT_MUTED` (hiện đến khi nào), `TOURNAMENT_CHAT_LOCKED`, socket `chat:room:evicted` (rời phòng, báo thân thiện), `chat:room:settings`. Tách widget mới ra file riêng (`lib/features/chat/widgets/`), không làm `chat_detail_screen.dart` phình thêm.
3. arb vi + en (thêm cuối file) rồi `flutter gen-l10n` MỘT lần; commit các `app_localizations*.dart` vì repo theo dõi chúng. KHÔNG commit file platform sinh tự động (`linux/flutter`, `macos/Flutter`, `windows/flutter`): worktree mới hay bị dirty do autocrlf; trước `merge-lane` dọn bằng `git checkout -- linux/flutter macos/Flutter windows/flutter` (đây chỉ là file sinh tự động, an toàn).
4. Responsive: bottom sheet cuộn được, không hardcode kích thước (ScreenUtil nếu repo dùng).
Test (TDD): TC-CHAT-UI-M-01..03 trong `test/domain/tournament_chat_room_test.dart` và `test/features/tournament/tournament_chat_entry_test.dart` (+ test mới cho widget quản lý nếu có chỗ); chạy `flutter test --no-pub <các file>` → exit 0 rồi `flutter analyze` + cả bộ test lên cloud (cloud-test-runner target `app`). Lên main qua `merge-lane` (sửa file l10n = phần dùng chung → cổng cloud cả bộ). App KHÔNG có staging. Luật đăng ký App ĐÃ LÊN main (squash `5cdf5b3b`, 2026-11-17) và nhánh này đã rebase lên origin/main; chạy `merge-lane --push` SAU KHI Backend main có `GET /chat/rooms/:id/participants`.
