## Why

Trên `main`, 8 file E2E cũ của App đang đỏ (organizer_flow, organizer_run_journey TC-QLGD-APP-36..37, organizer_schedule_settings_journey TC-QLGD-APP-74..75, social_create_journey TC-SOCIAL-APP-01 và 03, social_run_journey TC-SOCIAL-APP-10, tournament_player_flow, xem_bam_diem_pickleball, xem_vdv_lich). Phần lớn do màn hình đổi mà test chưa đổi theo (màn bấm điểm kiểu sân mới, form tạo giải, lời mời trọng tài tạo ACCEPTED ngay...). Đồng thời `integration_test/COVERAGE.md` còn nhiều chức năng chưa có test, nhất là logic giao bóng và đổi sân của pickleball, tennis, cầu lông trên màn sân mới.

## What Changes

- Sửa 8 file đỏ: ca lỗi thời thì sửa test giữ ý kiểm tra; ca lỗi app thật thì giữ `expect`, `skip: true` kèm mã `BUG-...` và ghi vào `design.md`.
- Bổ sung test cho các ô trống của `COVERAGE.md`: widget/unit test cho logic giao bóng và đổi sân (pickleball, tennis, cầu lông), E2E `integration_test/` khi cần màn thật.
- Chạy từng file trên cloud (`app-e2e`), tối đa 3 vòng cho mỗi lỗi; gộp `main` bằng `merge-lane.py`.
- Không sửa code sản phẩm trong `lib/`.

## Impact

- Chỉ đụng `integration_test/`, `test/` và tài liệu OpenSpec. Không đổi hành vi app.
