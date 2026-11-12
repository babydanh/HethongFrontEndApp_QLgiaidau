# E2E App: hành trình quản lý giải (integration_test)

Chạy trên Android emulator API 34 với Backend, Postgres và Redis thật. Không chạy trên máy dev hay máy cloud nhỏ:
dùng GitHub Actions (job `test-app-e2e` của `.github/workflows/test-runner.yml` ở repo `babydanh/agent-orchestrator`).

## Hành trình quản lý giải (TC-QLGD-APP-xx)

Bốn file phủ vòng đời quản lý giải của Ban tổ chức, tương đương các spec quản lý của Web. Mỗi file tự dựng dữ liệu
bằng API (tiền tố `E2E<timestamp>` riêng mỗi lần chạy nên chạy hai lần hoặc hai máy chồng nhau không đụng dữ liệu nhau).

| File | TC | Nội dung |
|---|---|---|
| `organizer_setup_journey_test.dart` | 01..19, 80 | Tạo giải nhanh, tổng quan, nội dung thi đấu (thêm, sửa, khóa, đóng/mở hàng loạt, xóa, luật chuẩn), VĐV (duyệt, từ chối, chi tiết, check-in, phí, liên hệ) |
| `organizer_run_journey_test.dart` | 20..39 | Vòng đời đăng ký, khai mạc, bốc thăm, bảng đấu, tab Kết quả (lọc, tìm, nhập điểm), bàn điểm live, kết thúc giải, trang công khai |
| `organizer_formats_journey_test.dart` | 40..59 | Vòng tròn, loại kép, vòng bảng (popup tạo bracket, hạt giống), Thụy Sĩ (ghép cặp, hoàn tác vòng), vận hành giai đoạn |
| `organizer_schedule_settings_journey_test.dart` | 60..79 | Địa điểm và sân, lưới lịch, thanh quản lý lịch, nhà tài trợ, trọng tài, tài chính, chia sẻ, xóa giải |

Helper dùng chung: `support/organizer_journey.dart` (`signInAsOrganizer`, `seedTournament`, `openManageHub`, `openHubTab`,
`tapKey`, `expectKey`) và `support/backend_api.dart` (thêm `startTournament`, `completeTournament`, `scoreMatch`,
`startMatch`, `getTournament`, `listVenues`, `listSponsors`).

### Chạy trên cloud (mỗi lần một file, không chạy song song)

```bash
gh workflow run test-runner.yml -R babydanh/agent-orchestrator \
  -f target_project=app-e2e -f app_ref=<nhánh đã push> \
  -f specs=integration_test/organizer_setup_journey_test.dart
gh run view <run_id> -R babydanh/agent-orchestrator --log
```

`specs` chỉ nhận ký tự `[A-Za-z0-9_./ -]`. Đọc kết quả: bước đỏ trước bước "Chạy integration_test" là hạ tầng; dòng
`N failed` trong log là test. Ảnh chụp chỉ có trong log (`[[SHOT ...]]`, base64) vì runner không giữ artifact.

## Bug sản phẩm đã biết (test không sửa code sản phẩm)

Test ghi rõ lý do ở chỗ bỏ qua; không có ca nào "xanh giả" bằng cách bọc `if (finder.evaluate().isNotEmpty)`.

- **Tràn layout** (`A RenderFlex overflowed by`): dropdown nhà tài trợ (`tournament_management_sponsors_section.dart:392`),
  thanh quản lý lịch. Bộ lọc ở `signInAsOrganizer` chỉ bỏ qua loại lỗi này và cảnh báo debug "ListTile background color or
  ink splashes may be invisible" của bàn điểm live. Dropdown nội dung ở mục Hạt giống (từng tràn 20 px) đã hết vì mục đó bị gỡ.
- **Sheet nhập điểm tab Kết quả** gửi `PATCH /matches/:id/score` cho trận chưa bắt đầu, Backend trả 400 "Hãy bắt đầu trận trước".
  Test bắt đầu trận bằng API trước khi mở App.
- **Chi tiết VĐV, giải miễn phí:** bỏ đánh dấu đã đóng phí làm hàng phí biến mất (`showFee` phụ thuộc `_paid`), không bật lại được.
- **Thụy Sĩ:** màn ghép cặp không tự đóng sau "Đã tạo vòng 2." Cần xác minh (test đóng bằng `pop`).

### Đã hết hoặc không còn áp dụng sau khi main đổi màn

- **Chuyển về Chưa xếp** (từng gọi `onDrop` của chính Bảng): màn Phân bảng vòng bảng thủ công đã bị gỡ (commit `9abf1282`), nên
  không còn tái hiện và test không còn bước này.
- **Tự động xếp hạt giống báo lỗi dù Backend trả 201** (`autoSeedParticipants`): mục Hạt giống người tham gia đã bị gỡ khỏi màn
  Quản lý (commit `36e77e17`), nên không còn áp dụng. TC-49 và TC-50 (hạt giống) đã bỏ khỏi file formats; TC-48 giữ phần cấu hình
  vòng bảng (số bảng, đội mỗi bảng, đội đi tiếp, playoff, cách xếp Ngẫu nhiên hoặc Theo ELO).
- Tạo bracket Vòng tròn và Vòng bảng đi qua popup cài đặt (`bracket-create-confirm`), popup xếp đội vào bảng theo ELO hoặc ngẫu
  nhiên (commit `e740022d`); TC-42 và TC-53 xác nhận popup bằng giá trị gợi ý.

Ghi chú: App chủ ý ẩn thể thức Thụy Sĩ khi tạo hoặc đổi nội dung (commit `2a227a69`), nên test dựng nội dung Swiss bằng API.

### Thay đổi test theo `main` mới và độ bền (2026-11-12)

- **Hộp Thêm nhà tài trợ** (commit `c63e4c23`): còn 3 ô chữ (tên, website, mô tả), hạng chọn bằng chip `sponsor-tier-*`, logo bắt buộc
  nhưng chỉ chọn bằng thư viện ảnh hệ thống (không thao tác được trên emulator). TC-74 dựng nhà tài trợ có logo bằng API, kiểm
  hộp, bắt buộc logo, ẩn/hiện, sửa hạng và lưu trữ trên giao diện.
- **Đăng xuất rồi đăng nhập lại trong cùng một giây:** Backend huỷ token theo mốc giây nên token mới bị 401. `signInAsOrganizer`
  chờ 1,5 giây giữa hai bước.
- **Độ bền:** TC-01 nhận form tạo giải bằng tiêu đề "Tạo giải nhanh" (form đăng nhập cũng có `TextFormField`); TC-07 thử lại khi nút
  menu 3 chấm biến mất lúc danh sách làm mới; TC-13 bấm gửi lại khi nút gửi còn khóa sau lần gửi trước.
