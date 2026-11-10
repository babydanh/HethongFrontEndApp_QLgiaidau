## Why

Playoff của giải vòng bảng + knock-out hiện chỉ hiện "N/A" ở các ô vòng đầu khi chưa có đội, nên chủ giải không biết ô nào chờ "Nhất bảng A" hay "Nhì bảng B", và không đổi được. Màn Bảng đấu còn thiếu: tự cuộn khi kéo, đổi thứ tự trong cùng bảng, thả đội về "Chưa xếp".

## What Changes

- Playoff (trang chi tiết giải và màn quản lý) hiện nhãn "Nhất A", "Nhì B", "Hạng 3 xuất sắc nhất" ở ô vòng 1 còn trống.
- Chủ giải kéo-thả một nhãn lên nhãn khác để đổi chỗ (gọi `PATCH /tournaments/:id/divisions/:divisionId/bracket/seed-order`); người xem chỉ thấy nhãn. Khóa khi playoff đã có trận bắt đầu.
- Thuật toán nhãn bám theo Web `knockout-seed-labels.ts` và Backend `advanceStandings` (đọc `advanceMapping` của stage playoff).
- `GroupStageView` (chế độ chỉnh sửa): tự cuộn khi kéo gần mép, thả đội vào vị trí trong cùng bảng, thả đội về khu "Chưa xếp".

## Out of scope

- Nhãn chỉ cho vòng 1 nhánh thắng; không làm nhánh thua/chung kết.
- Không đổi Backend/Web. Endpoint `seed-order` hiện chỉ có ở nhánh staging của Backend; lên production cần Backend + Web lên main riêng.
- Không đổi `PATCH /bracket/slots` hay `PATCH /tournaments/stages/:id` (sẽ xóa `advanceMapping`).

## Capabilities

### New Capabilities
- `bracket-playoff-seeding`: nhãn hạt giống ở playoff và đổi chỗ bằng kéo-thả.

### Modified Capabilities
- `bracket-group-stage-management`: tự cuộn, đổi thứ tự trong bảng, thả về "Chưa xếp".

## Impact

- App: `knockout_seed_labels.dart`, `playoff_seed_labels.dart`, `playoff_bracket_board.dart`, `playoff_double_elim_view.dart`, `public_bracket_view.dart`, `group_stage_view.dart`, `bracket_view_screen.dart`, `tournament_intro_screen.dart`, `tournament_repository.dart`, `api_tournament_repository.dart`, `app_vi.arb`, `app_en.arb`, test liên quan.
