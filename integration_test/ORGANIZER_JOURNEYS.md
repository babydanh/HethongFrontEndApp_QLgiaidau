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
| `organizer_formats_journey_test.dart` | 40..59 | Vòng tròn, loại kép, vòng bảng (phân bảng, hạt giống), Thụy Sĩ (ghép cặp, hoàn tác vòng), vận hành giai đoạn |
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

- **Tràn layout** (`A RenderFlex overflowed by`): dropdown nội dung ở mục hạt giống
  (`tournament_management_divisions_section.dart:889`), dropdown nhà tài trợ
  (`tournament_management_sponsors_section.dart:392`), thanh quản lý lịch. Bộ lọc ở `signInAsOrganizer` chỉ bỏ qua loại lỗi này
  và cảnh báo debug "ListTile background color or ink splashes may be invisible" của bàn điểm live.
- **Sheet nhập điểm tab Kết quả** gửi `PATCH /matches/:id/score` cho trận chưa bắt đầu, Backend trả 400 "Hãy bắt đầu trận trước".
  Test bắt đầu trận bằng API trước khi mở App.
- **Chi tiết VĐV, giải miễn phí:** bỏ đánh dấu đã đóng phí làm hàng phí biến mất (`showFee` phụ thuộc `_paid`), không bật lại được.
- **Phân bảng:** mục "Chuyển về Chưa xếp" của đội trong một Bảng gọi `onDrop` của chính Bảng đó nên đội ở lại bảng
  (`group_stage_assignment_screen.dart`). Test bỏ bước này.
- **Tự động xếp hạt giống:** `POST /tournaments/:id/auto-seed` trả 201 nhưng App báo "Không thể hoàn tất thao tác" và không làm
  mới ô hạt giống (nghi `autoSeedParticipants` đọc phản hồi như danh sách hàng). Cần xác minh.
- **Thụy Sĩ:** màn ghép cặp không tự đóng sau "Đã tạo vòng 2." Cần xác minh.

Ghi chú: App chủ ý ẩn thể thức Thụy Sĩ khi tạo hoặc đổi nội dung (commit `2a227a69`), nên test dựng nội dung Swiss bằng API.
