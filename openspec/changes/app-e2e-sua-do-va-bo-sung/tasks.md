## 1. Sửa 8 file đỏ
- [ ] 1.1 organizer_flow, organizer_run_journey 36..37, organizer_schedule_settings_journey 74..75. Tiêu chí: 3 file xanh trên cloud trừ ca `BUG-` skip
- [ ] 1.2 social_create_journey 01, 03 và social_run_journey 10. Tiêu chí: 2 file xanh trên cloud trừ ca `BUG-` skip
- [ ] 1.3 tournament_player_flow và xem_vdv_lich. Tiêu chí: 2 file xanh trên cloud trừ ca `BUG-` skip
- [ ] 1.4 xem_bam_diem_pickleball (4 ca giao bóng, màn sân mới). Tiêu chí: file xanh trên cloud

## 2. Bổ sung test
- [ ] 2.1 Giao bóng và đổi sân pickleball, tennis, cầu lông trên màn sân mới (widget/unit test và E2E nếu cần)
- [ ] 2.2 Lấp ô trống còn lại của `integration_test/COVERAGE.md`

## 3. Tích hợp
- [ ] 3.1 Gộp nhánh con, chạy lại toàn bộ file trên cloud, cập nhật `COVERAGE.md` và `design.md`
- [ ] 3.2 `openspec validate app-e2e-sua-do-va-bo-sung --strict` và `merge-lane.py --push`
