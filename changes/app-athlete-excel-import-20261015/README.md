# app-athlete-excel-import-20261015

Đồng bộ quản lý VĐV của App với web: thêm VĐV (tìm theo email, chọn nhiều, cặp đôi, khách có email, tự duyệt) và nhập VĐV từ Excel (đọc file, nhận diện cột, preview trên server, commit dòng đủ điều kiện, idempotency, tải mẫu).

- Tier: Normal. Profile: không có (không commerce/dashboard/VN launch/theme/I18N profile). Chuỗi UI mới đi qua l10n.
- Trạng thái: IN_PROGRESS. Chưa analyze, chưa test, chưa build.
- Phạm vi trong: `lib/domain/**`, `lib/data/repositories/api/api_tournament_management_repository.dart`, parser/UI nhập Excel, `AddAthleteSheet`, 2 test thêm VĐV, và phần phụ `InteractiveViewer` của sơ đồ overlay (`live_score_screen.dart`).
- Ngoài phạm vi: redesign tab Hub Bracket; khoá nút xếp lô chống bấm đúp; seed/categoryName/h2hStat cho overlay (không có nguồn dữ liệu trong `MatchModel`); xác minh giao diện trên máy (`INJECT_EVENTS` bị từ chối).

## Lệch quy trình (ghi thật)
- Harness `workflow/harness/new-change.ps1` và `validate-workflow.ps1` chỉ có ở repo cha `D:/Duancanhan/Project_QuanLyGiaiDau`. Repo App không có `workflow/` và không có `openspec/`, nên harness không chạy được trong App.
- Vì vậy các artifact ở đây được viết tay, đặt tên theo bộ file của workflow (00, 03, 07, 08, 09, 10, 12).
- Đã có thay đổi repository và entity TRƯỚC khi viết plan này. Xem `10-implementation-log.md`.
- Một lần chạy harness nhầm với cha đã tạo 17 file ở `Project_QuanLyGiaiDau/changes/`; thư mục đó đã được xoá. Chi tiết trong `10-implementation-log.md`.
