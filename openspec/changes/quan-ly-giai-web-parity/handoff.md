# Handoff — quan-ly-giai-web-parity

## Mục tiêu
Đồng bộ MỌI chức năng quản lý giải của App khớp Web (kiểm kê 2026-10-25: Web `src/app/organizer/**` ~50 popup; App ~61 popup nhưng hụt nhiều chức năng thật), popup làm lại theo bottom sheet chuẩn App. Series + AI tạo giải: để sau (chốt người dùng).

## Trạng thái
- PROPOSED — chờ người dùng nói "apply" rồi mới làm task.
- Đã có: proposal.md, design.md, tasks.md (25 task, 6 nhóm), 6 spec delta (2 MODIFIED + 4 NEW), worktree `quan-ly-giai-web-parity` từ origin/main.

## Đã thử: cách → kết quả → vì sao
- 2 agent kiểm kê song song Web + App → bản đồ ~110 popup/luồng hai bên, nguồn cho gap matrix trong `.lavish/plan.html` và tasks.md.

## Ràng buộc đang có
- Không thêm package Flutter (kéo-thả dùng LongPressDraggable/ReorderableListView core; QR dùng package qrcode đã có; Excel dùng lib hiện có).
- Key l10n phải có ở cả app_vi.arb + app_en.arb rồi `flutter gen-l10n`; không sửa file sinh.
- Route backend đối chiếu controller thật (`HethongBackendApi_QuanlyGiaiDau/src/modules/**`) trước khi viết repository — App chỉ gọi route Web đang dùng, không bịa.
- Test nặng chạy cloud (cloud-test-runner); local chỉ `flutter test --no-pub` file lẻ.
- Livestream camera đang bị chặn cố ý vì bảo mật (comment `tournament_management_livestream_section.dart:18-33`) — người dùng đã chốt gỡ chặn theo web; không log stream key.

## Ràng buộc thay đổi lần này
- Bỏ giới hạn "chỉ admin được kết thúc giải" (`_canFinalizeTournament`) — theo Web, backend chốt quyền.
- Popup mới đều qua khung `TournamentManageSheet` (task 0.1).

## Câu hỏi còn mở
- AI layout file Excel (`/ai/.../roster-layout`) có đáng kéo vào App không (design.md — đề xuất chưa làm).
- Stream key: Web có cả SRT (đang ẩn trên Web) — App chỉ làm RTMP + PULL như Web hiển thị.
