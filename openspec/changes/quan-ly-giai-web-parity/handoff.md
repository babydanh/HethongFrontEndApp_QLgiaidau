# Handoff — quan-ly-giai-web-parity

## Mục tiêu
Đồng bộ MỌI chức năng quản lý giải của App khớp Web (kiểm kê 2026-10-25: Web `src/app/organizer/**` ~50 popup; App ~61 popup nhưng hụt nhiều chức năng thật), popup làm lại theo bottom sheet chuẩn App. Series + AI tạo giải: để sau (chốt người dùng).

## Trạng thái
- ĐÃ LÀM XONG code mọi task 0.1–5.2 (SDD, 2026-10-26), final review 3 reviewer + 1 đợt fix + scoped re-review: GỘP ĐƯỢC. Tip `c1f5cf6f` (base `origin/main` `a067d420`), chưa push.
- Test cục bộ: 57 file test hẹp = 497 test, exit 0; `flutter analyze` 7 file đã sửa: 0 error/warning (8 info curly_braces có từ trước).
- CHƯA tick trong tasks.md (chờ test API cloud, cần push nhánh trước): 2.1, 4.5, 5.1, 5.2.
- Gộp: nên gộp `lich-gon-gio-san-app` (nếu còn) trước vì cùng sửa `schedule_grid.dart`, rồi rebase; qua `merge-lane.py`, `--push` chỉ khi người dùng cho phép.

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
- Ràng buộc cũ (không thêm package, l10n 2 ARB, route theo controller thật, test nặng chạy cloud, không log stream key): không đổi (đã so).

- Đợt fix cuối (9 mục): bước lưới bulk theo `_stepMinutes`, dispose 9 controller, `onWaitingBatchFinished` khi thoát sớm, l10n "Sân khác", chip 44px + Semantics, setState nút Huỷ, removeWhere theo id, xuất roster Excel ghi vào thư mục tạm + xoá sau share + tên file strict. Cố ý KHÔNG xoá getter `PlatformFeeBreakdown.description` (test còn assert).

## Câu hỏi còn mở
- Minor còn lại: export Excel roster trên desktop bị xoá file ngay (`excel_export_service.dart:378-392`); test `participant_filter_chips_test.dart:133-148` cần `dart format`; tách file >800 dòng; giới hạn kích thước file nhập roster.
- AI layout file Excel (`/ai/.../roster-layout`) có đáng kéo vào App không (design.md — đề xuất chưa làm).
- Stream key: Web có cả SRT (đang ẩn trên Web) — App chỉ làm RTMP + PULL như Web hiển thị.
