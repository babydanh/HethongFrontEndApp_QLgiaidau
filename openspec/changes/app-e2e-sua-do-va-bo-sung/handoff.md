# Handoff: sửa 8 file E2E đỏ và bổ sung test App
Cập nhật: 2026-11-14 · nhánh `cloud/danh3-app-e2e-sua-do-va-bo-sung` · OpenSpec: app-e2e-sua-do-va-bo-sung · việc: app-e2e-nhieu-tai-khoan-112843

## Trạng thái
- Vòng 1: phủ 33/33 file integration_test, xanh 223, bỏ qua 30 (đều ca `BUG-`), đỏ 0; 8 file đỏ cũ đã sửa hết (test lỗi thời, không ca nào skip thêm); thêm 38 test giao bóng/đổi sân (pickleball 9, tennis 14, cầu lông 15) và 42 widget test (football_team, referee, payment, auth).
- Vòng 2: thêm widget test community (44 + 1 skip), auth (39 + 1 skip), payment (36 + 1 skip), explore/live (21). Lỗi mới: BUG-FORGOT-01 (cao), BUG-PAY-01 (trung bình), nghi vấn BUG-DIO-HANDLER-01, BUG-VENUE-SPORT-01.
- Dừng vì cần người dùng: sửa lỗi quyền trong `lib/` (BUG-CLUB-02, BUG-PERM-01): hệ thống từ chối giao agent sửa `lib/`; để người dùng quyết. Worktree `/data/home/wt/app-sua-9` còn một bản sửa BUG-CLUB-02 chưa commit, chưa kiểm, không đưa vào nhánh này.
- Gộp vào `main` bằng `merge-lane.py --push` (squash, không Co-Authored-By).

## Ràng buộc
- Không sửa `lib/`; không Co-Authored-By; không đọc/in `.env`.
