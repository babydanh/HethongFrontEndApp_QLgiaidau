## Why

Bộ `integration_test/` trên `main` (34 file) phủ tốt luồng quản lý giải của Ban tổ chức (TC-QLGD-APP-01..80), chấm điểm theo môn (TC-CBD-APP) và buổi Social (TC-SOCIAL-APP). Ngoài ba khu đó, khoảng 300 chức năng người dùng còn lại gần như chưa có E2E. Các khu trống: trọng tài, người xem live, đồng BTC, CLB, chat, thông báo, xếp hạng, thanh toán, chuỗi giải, Lite, admin, khách chưa đăng nhập.

Hầu như chưa test nào kiểm hiệu ứng chéo giữa nhiều tài khoản. Hành động của người khác đều làm qua API, chỉ Social có đổi tài khoản trong giao diện.

Khi đọc code để kiểm kê đã thấy vài chỗ nghi sai logic. Đáng chú ý nhất là người được mời làm trọng tài không mở được màn lời mời (mục "Phát hiện" trong `design.md`). Người dùng yêu cầu kiểm mọi luồng, mọi module bằng nhiều tài khoản và xem từng chức năng có hợp lý không.

## What Changes

- **Hợp đồng chung (làm trước):**
  - Thêm `integration_test/support/actors.dart`: tạo bộ tài khoản riêng cho mỗi chuỗi test (tiền tố `E2E<timestamp>-<chuỗi>`), đổi vai trong giao diện (`signInAs`), kiểm màn bị chặn (`expectBlocked`).
  - Mở rộng `integration_test/support/backend_api.dart` với các hàm cho vai phụ: mời và nhận lời mời trọng tài, đồng BTC, CLB (tạo, xin vào, duyệt, mời), chat, thông báo, theo dõi giải, chuỗi giải.
- **Thêm 6 file hành trình nhiều tài khoản:**
  - Mỗi file có bộ tài khoản riêng, nên 6 file chạy song song trên 6 máy cloud không đụng dữ liệu nhau.
  - Mã test `TC-MULTI-<chuỗi>-xx`, có `expect` chắc chắn và ảnh `shot()` ở mỗi bước.
  - Mỗi file có một nhóm ca "phân quyền âm": vai không đủ quyền thì không thấy nút, hoặc bị chặn ở route.

| Chuỗi | File | Nội dung |
|---|---|---|
| A | `multi_referee_live_journey_test.dart` | BTC mời trọng tài và đồng BTC, người nhận mở lời mời, chấp nhận, chấm điểm; người xem thấy tỉ số live, chat trận, xem lại |
| B | `multi_player_journey_test.dart` | VĐV đăng ký đơn, đôi, đội, mã mời, `join-team`, `lite-join`, theo dõi giải, thanh toán (tới màn cổng), dashboard, sửa hồ sơ, đổi mật khẩu, xếp hạng |
| C | `multi_club_chat_notify_journey_test.dart` | Tạo CLB, xin vào và duyệt, mời thành viên, chat CLB, chat 1-1, thông báo chéo, đọc và đọc hết thông báo |
| D | `multi_social_cross_journey_test.dart` | Social: host thêm tài khoản thì người đó nhận thông báo; người chơi thấy trạng thái thanh toán; báo cáo; đánh lại số TC trùng |
| E | `multi_admin_guest_journey_test.dart` | Admin duyệt giải và CLB trên giao diện, change-request, tranh chấp, xác minh; khách xem route công khai và bị chặn route riêng; đăng ký, quên mật khẩu |
| F | `multi_series_ops_lite_journey_test.dart` | Chuỗi giải (tạo, mời nhân sự, nhận lời mời), màn `/ops`, màn Lite (ghép cặp, quản lý) |

- **Kiểm "hợp lý":** test viết theo hành vi đúng. Test đỏ vì lỗi sản phẩm thì ghi vào mục "Phát hiện" của `design.md` (đường dẫn, bước tái hiện, ảnh). Change này không sửa code sản phẩm.
- **Cập nhật tài liệu chạy:** `integration_test/ORGANIZER_JOURNEYS.md` (bảng file, cách chạy song song).

## Out of scope

- Sửa lỗi sản phẩm tìm được: mỗi lỗi một change riêng, sau khi người dùng chọn.
- Thanh toán qua cổng thật (PayOS) và đăng nhập Google: chỉ kiểm tới màn cổng hoặc nút, không đi qua bên thứ ba.
- Chạy hai máy ảo cùng lúc trong một test. Realtime được kiểm bằng cách vai phụ hành động qua API, còn giao diện của vai chính phải tự cập nhật không cần tải lại.
- Đổi workflow `test-runner.yml` của repo `babydanh/agent-orchestrator`. Nó vẫn chạy mỗi lượt một file, tối đa 75 phút.
- Đưa mật khẩu E2E đang ghi cứng trong `backend_api.dart` ra `--dart-define`: cần sửa workflow nên làm change riêng.
- Không thêm package. Không sửa 4 file `organizer_*_journey`.

## Capabilities

### New Capabilities
- `app-e2e-nhieu-tai-khoan`: bộ integration test hành trình nhiều tài khoản phủ các module ngoài quản lý giải.

### Modified Capabilities
(không)

## Impact

- Chỉ thêm hoặc sửa file dưới `integration_test/`.
- Mỗi file chạy trên cloud bằng `cloud-test-runner.py run --target app-e2e`. Cả bộ khoảng 6 lượt × 30–60 phút, chạy song song được.
