## Bối cảnh

Một lượt `app-e2e` trên cloud chạy 1 máy ảo Android API 34, kèm Backend, Postgres và Redis thật, tối đa 75 phút. Bộ hiện có dùng 3 tài khoản cố định:
- `admin1`: BTC.
- `user8`: VĐV.
- `e2eadmin`: ADMIN, chỉ dùng qua API.

Tài khoản phụ tạo bằng `POST /auth/mobile/register` nhưng không đăng nhập trên app. Vai trò trong app là `UserRole {admin, referee, organizer, viewer}` (`lib/providers/auth_provider.dart:16`). Quyền BTC, đồng BTC và quyền chấm điểm tính theo từng giải (`canManageTournament`, `scoringStaffTournamentIds`), không theo vai trò toàn cục.

## Các cách đã cân nhắc

| Cách | Mô tả | Đánh đổi |
|---|---|---|
| **A (chọn)** | Một máy ảo. Vai chính thao tác trên giao diện; vai phụ hành động qua API. Ở điểm giao thì đổi tài khoản trong giao diện (`signInAs`) để kiểm người kia thấy đúng. | Chạy được ngay trên hạ tầng hiện có, chạy song song theo file. Không kiểm được hai màn hình cùng lúc. |
| B | Hai máy ảo cùng lúc, mỗi máy một tài khoản | Kiểm realtime thật nhất, nhưng phải sửa workflow repo công khai, gấp đôi thời gian dựng, dễ chập chờn |
| C | Chỉ test API nhiều tài khoản, không có giao diện | Nhanh, nhưng không kiểm được nút hiện hay ẩn và màn bị chặn, mà người dùng cần kiểm chính những thứ đó |

Realtime trong cách A: vai phụ gọi API (ví dụ trọng tài cộng điểm). Màn của vai chính đang mở phải đổi trong 10 giây mà không cần tải lại. Như vậy kiểm được đường socket.

## Quyết định

1. **Mỗi chuỗi một bộ tài khoản riêng.**
   - `actors.dart` tạo tài khoản mới cho từng vai bằng `registerAccount` + `completePlayerProfile`. Tiền tố gồm thời gian và tên chuỗi.
   - Riêng ADMIN dùng `e2eadmin` (không tự tạo được).
   - Không dùng chung `admin1`/`user8`, nên 6 file chạy song song được.
   - Nhược điểm: tài khoản mới không có ELO hay lịch sử. Màn xếp hạng kiểm bằng dữ liệu seed (`--seed data`).
2. **`signInAs(tester, actor)`** chuyển từ `social_journey.dart` sang `actors.dart`, giữ lần chờ 1,5 giây giữa đăng xuất và đăng nhập (Backend huỷ token theo giây). `social_journey.dart` gọi lại hàm mới, không giữ bản sao.
3. **Phân quyền âm** dùng `expectBlocked(route)`. Hàm mở route bằng `GoRouter.go` rồi khẳng định đúng một trong ba điều: bị đưa về `/login` hay `/home`, thấy màn báo không có quyền, hoặc không có nút quản lý. Không chấp nhận màn trắng hay màn lỗi 401/403 thô.
4. **Test theo hành vi đúng.** Nếu đỏ vì lỗi sản phẩm thì:
   - Giữ `expect` (không bọc `if`, không nuốt lỗi).
   - Đánh dấu ca bằng `skip: true`, ghi `BUG-<id>` trong tên ca và chú thích cạnh `skip` (vì `skip` của `testWidgets` chỉ nhận `bool`), để cả bộ chạy tiếp.
   - Ghi lỗi vào mục "Phát hiện" bên dưới.
   - Gỡ `skip` khi lỗi được sửa.
5. **Một file không quá 60 phút trên cloud.** Vượt thì tách thành `..._1`, `..._2`.
6. **Allure cho E2E App.**
   - Flutter không có adapter Allure chính thức. Job chạy `flutter test --reporter json` (vẫn ghi log chữ cho `cloud-test-runner.py summary`), rồi script Python `scripts/e2e/flutter_json_to_allure.py` (repo orchestrator, có unit test) đổi sự kiện `testStart`/`testDone`/`print`/`error` ra `allure-results/*-result.json`.
   - Mỗi `[[SHOT name]]<base64>` trong `print` của ca đó thành attachment PNG; lỗi `expect` thành `statusDetails`. Nhãn `suite` = tên file, `story` = mã TC.
   - Sinh báo cáo bằng `npx allure-commandline@2.46.1 generate` như job Web, lưu vào kho private bằng `allure_archive.py publish --project qlgd-app-e2e` (secret `GH_PAT`). Lưu kho lỗi không làm job đỏ (`continue-on-error`).
   - Repo orchestrator public: không đưa Allure, ảnh hay log có base64 ảnh lên `upload-artifact`.
7. **Ma trận quyền qua API (chuỗi H)** không cần giao diện, chạy nhanh, bổ sung cho ca `expectBlocked`. Ô nào lệch kỳ vọng là một BUG, ghi vào bảng Phát hiện.

## Phát hiện (kết quả chạy thật trên cloud, 2026-11-14)

Mỗi dòng đã được một ca test tái hiện (ca bị `skip: true`, mã BUG trong tên ca hoặc ngay cạnh `skip`) hoặc bị bác bỏ. "Chưa kiểm bằng Botkeep": Botkeep không phản hồi lúc làm.

| ID | Mức | Mô tả | Vị trí | Ca |
|---|---|---|---|---|
| BUG-PERM-03 | Cao (Backend) | `PATCH /matches/:id/status` trả 200 cho người không có vai trò nào ở giải (đổi được trạng thái trận) | Backend, route trận | A-19b |
| BUG-PERM-04 | Cao (Backend) | `PATCH /matches/:id/score` trả 200 cho người không có vai trò nào ở giải (chấm được điểm) | Backend, route trận | A-19c |
| BUG-ADMIN-03 | Trung bình | Màn Quản lý CLB của admin gọi `GET /communities?limit=200`, Backend giới hạn 50 nên luôn 400 và báo lỗi tải | màn Quản lý CLB admin | E-07, E-08 |
| BUG-ADMIN-04 | Trung bình | `GET /admin/change-requests`, `/admin/disputes`, `/admin/verification` trả 404 nên 3 màn admin không tải được; `POST /users/change-requests` trả 400 "Giới tính chưa bị khóa" với tài khoản mới | màn admin tương ứng | E-09..E-12 |
| BUG-GUEST-01 | Trung bình | Khách vào được `/chat`, `/club-create`, `/club-invites` (allowlist `startsWith`) thay vì bị đưa về đăng nhập | `lib/core/router/app_router.dart:125-140` | E-19 |
| BUG-PERM-01 | Trung bình | Người không quản lý mở `/organizer/tournaments/:id/manage` vào được màn, chỉ Backend trả 403; màn `/ops` cũng mở được, 4 API trả 403 nhưng không có chữ báo thiếu quyền (chuỗi `opsNoPermission` có trong `app_vi.arb:5331` mà không dùng) | `app_router.dart:160-165, 415`; `organizer_ops_screen.dart:136-175` | B-14, B-17, G-15, H-17, H-19, A-18 |
| BUG-CLUB-02 | Trung bình | Thành viên thường mở `/club/:id/manage` vẫn vào màn Điều phối; Backend vẫn trả 403 khi duyệt | `app_router.dart:668-673`; `club_management_screen.dart:31` | C-17 |
| BUG-SOCIAL-D-02 | Trung bình (Backend) | `POST /social-sessions/:id/participants` không tạo thông báo cho người được thêm | Backend social | D-02, D-03 |
| BUG-SOCIAL-D-01 | Thấp | Người chơi không thấy trạng thái thanh toán của mình (chỉ tab Thanh toán của host có) | `lib/features/social` | D-08 |
| BUG-FILTER-01 | Trung bình | Bộ lọc Đăng ký gửi `status=REGISTRATION` nhưng giải mở đăng ký có `REGISTRATION_OPEN` nên danh sách rỗng | `api_tournament_repository.dart:749-751` | G-02 |
| BUG-FOLLOW-01 | Thấp | Theo dõi giải trả 403 (email chưa xác minh) nhưng app nuốt lỗi, nút không đổi, không báo gì | màn giải | B-08 |
| BUG-REF-01 | Thấp | Router đẩy `/referee/invites` về `/viewer` rồi `/home` với tài khoản trọng tài. `POST /tournaments/:id/referees` tạo trọng tài ACCEPTED ngay, không có lời mời chờ, nên không dựng được luồng nhận lời mời | `app_router.dart:164-166` | A-03, A-04 |
| BUG-ADMIN-01 | Thấp | Admin vào `/admin` bị chuyển về `/home`, không có màn quản trị tổng | `app_router.dart:241-246` | E-06 |
| BUG-F-01 | Thấp (Backend) | `POST /organizer/series/:id/invitations` trả 500; app không có màn mời nhân sự chuỗi, route là [ĐOÁN] | Backend series | F-05, F-06 |
| BUG-F-02 | Trung bình | Tab Danh sách tham gia của `/ops` không hiện VĐV mới sau Làm mới (45 giây) dù Backend đã có | màn `/ops` | F-08 |
| BUG-CHAT-01 | Thấp | `ChatDetailScreen` gọi `setState` sau `dispose` khi socket đóng | `chat_detail_screen.dart:166-173` | C-20 |
| BUG-CLUB-01 | Thấp | `PopScope` của màn CLB sửa provider trong lúc dựng cây khi route bị gỡ bằng `go('/home')` | `club_detail_screen.dart:473-479` | C (đã né bằng `pop`) |
| BUG-ENV-SEED-01 | Môi trường | Seed cloud báo `column "district_code" does not exist` ở lệnh `DELETE FROM wards` | seed cloud, ngoài phạm vi change | log mọi lượt |

Đã bác bỏ khi chạy thật:
- **BUG-GUEST-02** (khách mất mã mời): E-20 xanh, sau đăng ký về đúng giải được mời.
- **BUG-ADMIN-02** (admin thấy hộp chấm điểm): A-20 xanh, admin không có nút bắt đầu hay chấm điểm ở giải không phải của mình.

Backend phân quyền đúng ở các ô còn lại của ma trận H (người ngoài, thành viên, chủ CLB, trọng tài bị 403; khách bị 401; `PATCH /users/:id` trả 404 nên không sửa được hồ sơ người khác).

### Giới hạn đã biết của bộ test

- **Email chưa xác minh:** tài khoản mới bị Backend chặn 403 ở mọi lệnh giải và trận. Hệ quả: trọng tài dùng `user8` (đã xác minh); không kiểm được ô "qua" của đồng BTC trong ma trận H; với player, viewer, member, clubOwner mới, ô "chặn" ở route giải có thể là 403 vì chưa xác minh chứ không vì vai. Ô CLB và chat không bị guard email nên có giá trị thật.
- **Ca "nhẹ":** chuỗi B ca 07, 09, 13 chỉ kiểm màn mở được, không đi hết luồng.
- **Không có dữ liệu xếp hạng/ELO** trong seed nên G-11, G-12 kiểm theo dữ liệu API có gì thì khớp nấy.
- **Chuỗi F dùng chung `admin1`:** giới hạn 50 chuỗi có thể che chuỗi mới tạo.
- **Skip:** `testWidgets(skip:)` chỉ nhận `bool`, nên ca bị bỏ qua dùng `skip: true`, mã `BUG-...` ghi trong tên ca và chú thích cạnh `skip`. Gỡ `skip` khi lỗi được sửa.
- **Ảnh trong báo cáo Allure** chưa kiểm được vì token trên máy này không xem được kho private `babydanh/qlgd-e2e-archive`.

Các lỗi đã biết trong `ORGANIZER_JOURNEYS.md` (tràn layout nhà tài trợ, sheet nhập điểm gửi 400, hàng phí biến mất, màn Thụy Sĩ không tự đóng) giữ nguyên ở file đó.

## Rủi ro

- **Mật khẩu E2E ghi cứng:** `kE2ePassword` nằm trong repo công khai. Đây là tài khoản chỉ có trong DB của job CI. Change này không đổi, chỉ nêu lại.
- **Chập chờn do socket và thời gian:** chờ theo điều kiện (`pumpUntil`), không `Future.delayed` cố định ngoài lần chờ đổi tài khoản.
- **Cổng thanh toán và Google:** chỉ kiểm tới nút hoặc màn chuyển hướng.
