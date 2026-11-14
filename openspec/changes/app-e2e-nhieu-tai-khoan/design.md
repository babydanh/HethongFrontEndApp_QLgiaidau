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
   - Đánh dấu ca bằng `skip: 'BUG-<id>: <mô tả>'` để cả bộ chạy tiếp.
   - Ghi lỗi vào mục "Phát hiện" bên dưới.
   - Gỡ `skip` khi lỗi được sửa.
5. **Một file không quá 60 phút trên cloud.** Vượt thì tách thành `..._1`, `..._2`.
6. **Allure cho E2E App.**
   - Flutter không có adapter Allure chính thức. Job chạy `flutter test --reporter json` (vẫn ghi log chữ cho `cloud-test-runner.py summary`), rồi script Python `scripts/e2e/flutter_json_to_allure.py` (repo orchestrator, có unit test) đổi sự kiện `testStart`/`testDone`/`print`/`error` ra `allure-results/*-result.json`.
   - Mỗi `[[SHOT name]]<base64>` trong `print` của ca đó thành attachment PNG; lỗi `expect` thành `statusDetails`. Nhãn `suite` = tên file, `story` = mã TC.
   - Sinh báo cáo bằng `npx allure-commandline@2.46.1 generate` như job Web, lưu vào kho private bằng `allure_archive.py publish --project qlgd-app-e2e` (secret `GH_PAT`). Lưu kho lỗi không làm job đỏ (`continue-on-error`).
   - Repo orchestrator public: không đưa Allure, ảnh hay log có base64 ảnh lên `upload-artifact`.
7. **Ma trận quyền qua API (chuỗi H)** không cần giao diện, chạy nhanh, bổ sung cho ca `expectBlocked`. Ô nào lệch kỳ vọng là một BUG, ghi vào bảng Phát hiện.

## Phát hiện từ đọc code (cần test xác nhận)

| ID | Mức | Mô tả | Vị trí |
|---|---|---|---|
| BUG-REF-01 | Cao | Người được mời làm trọng tài (JWT là PLAYER, nên vai trò trong app là `viewer`) bấm "Mở danh sách" lời mời thì bị đẩy về `/viewer` rồi về `/home`, không nhận hay từ chối được | `lib/core/router/app_router.dart:164-166`, `lib/features/dashboard/screens/dashboard_screen.dart:759` |
| BUG-GUEST-01 | Trung bình | Khách chưa đăng nhập vào được `/chat`, `/club-create`, `/club-invites`, `/profile` (allowlist dạng `startsWith`), thấy màn rồi gặp lỗi 401 thay vì được đưa về đăng nhập [SUY LUẬN] | `app_router.dart:125-140` |
| BUG-GUEST-02 | Trung bình | Khách mở link mời rồi đi tiếp vào route ngoài allowlist thì bị đẩy `/home` và mất mã mời [SUY LUẬN] | `app_router.dart:120-142` |
| BUG-PERM-01 | Thấp | Người không phải BTC mở `/organizer/tournaments/:id/manage` vào được màn, chỉ bị Backend trả 403 | `app_router.dart:~160` |
| BUG-ADMIN-01 | Thấp | Admin đăng nhập đi `/admin` rồi bị chuyển về `/home`; không có màn quản trị tổng | `core/utils/navigation_helpers.dart:~52`, `app_router.dart:~244` |
| BUG-ADMIN-02 | Thấp | ADMIN toàn cục không tự có quyền chấm điểm, nhưng hộp sửa điểm admin vẫn hiện theo `isAdmin`; cần xác nhận ý định | `lib/features/match/screens/live_score_screen.dart:770-792` |
| BUG-CHAT-01 | Thấp | `ChatDetailScreen` gọi `setState` sau `dispose` khi socket đóng | `lib/features/chat/screens/chat_detail_screen.dart:164-171` |

Các lỗi đã biết trong `ORGANIZER_JOURNEYS.md` (tràn layout nhà tài trợ, sheet nhập điểm gửi 400, hàng phí biến mất, màn Thụy Sĩ không tự đóng) giữ nguyên ở file đó.

## Rủi ro

- **Mật khẩu E2E ghi cứng:** `kE2ePassword` nằm trong repo công khai. Đây là tài khoản chỉ có trong DB của job CI. Change này không đổi, chỉ nêu lại.
- **Chập chờn do socket và thời gian:** chờ theo điều kiện (`pumpUntil`), không `Future.delayed` cố định ngoài lần chờ đổi tài khoản.
- **Cổng thanh toán và Google:** chỉ kiểm tới nút hoặc màn chuyển hướng.
