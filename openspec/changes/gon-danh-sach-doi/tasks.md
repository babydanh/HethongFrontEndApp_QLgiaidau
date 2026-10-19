# Tasks

## 1. Hàng nội dung

- [x] 1.1 `division_accordion.dart`: tên nội dung dùng `Expanded` (bỏ `Spacer`), cột icon người + số trong `SizedBox` bề rộng cố định căn phải. Xong khi: widget test mới `test/features/division_row_alignment_test.dart` PASS: 2 nội dung tên ngắn/dài cho cùng `dx` mép phải của text số, tên dài có `overflow: ellipsis`.

## 2. Mở/thu nội dung ở tab Đội

- [x] 2.1 Giữ `DivisionAccordion` + `contentBuilder` ở tab Đội (mỗi lần mở 1 nội dung, bấm lại thì thu); `TeamsTab` nhận `isDoublesDivision` từ `TournamentDivision.isDoubles`. Xong khi: `test/features/tournament_teams_inline_layout_test.dart` PASS: bấm B thì A thu và đội B hiện dưới hàng B; bấm lại B thì không đội nào hiện.

## 3. Hàng đội đôi gọn

- [x] 3.1 `tournament_team_card.dart`: bỏ trạng thái xổ (`_isExpanded`, `AnimatedSize`, `_revealExpandedRow`), hàng đội đôi gồm tên + icon phí, dưới là chip thành viên (`Wrap`, avatar 10–12px bán kính, chữ 12px, `maxLines: 1` + ellipsis). Bỏ dòng "Thành viên:" và badge Elo. Bấm chip gọi `onMemberTap`. Xong khi: widget test mới `test/features/tournament_team_card_compact_test.dart` PASS: đội 2 người → 2 chip, không có text chứa "Elo" hay "Thành viên"; bấm chip → `onMemberTap` nhận đúng `userId`.
- [x] 3.2 Ô chờ đồng đội: đội đôi có `approvalStatus == 'PENDING_PARTNER'` hoặc đúng 1 thành viên trong nội dung đôi → ô tròn viền đứt hổ phách chỉ icon `person_add_alt_1`, `l10n.teamStatusWaitingForPartner` trong `Tooltip`/`Semantics`, không bấm được. Xong khi: test ở 3.1 PASS: 1 thành viên → có icon và tooltip, không có text "Chờ đồng đội"; 2 thành viên → không có icon.
- [x] 3.3 Chip chỉ từ roster thật: `api_team_repository.dart` `getAllByTournament` không điền tên đội vào `members`; card dùng `team.members`, rỗng thì không có hàng chip. Bỏ key `teamMemberFallback`. Xong khi: test ở 3.1 PASS ca roster rỗng: tên đội hiện đúng 1 lần, không icon chờ.
- [x] 3.4 `getAllByTournament` đọc `guestNames` vào `members` + `memberInfos` (không `userId`); card đơn dùng `userId` của info khi có info; `TeamsTab` bỏ fallback `team.userId`. Xong khi: `test/data/api_team_repository_guest_names_test.dart` PASS (2 khách, roster + khách, server cũ) và `tournament_team_card_compact_test.dart` PASS ca bấm chip khách → `userId` null.

## 4. Kiểm chứng tổng

- [x] 4.1 `flutter analyze --no-pub lib/features/tournament` không lỗi mới; `flutter test --no-pub` các file test ở 1.1, 2.1, 3.1, 3.4 và `tournament_tabs_density_smoke_test.dart` PASS.
- [x] 4.2 Smoke trên máy thật (hot reload qua scrcpy): mở tab "Danh sách đội" của giải nhiều nội dung, cột số thẳng hàng, bấm lại nội dung đang mở thì thu, đội đôi hiện 2 chip, đội thiếu người chỉ có icon chờ, bấm chip mở hồ sơ. Xong khi: có ảnh `adb exec-out screencap -p`.

## Workflow follow-up

- Sau khi Backend deploy `guestNames`: smoke trên máy giải "Giải Phong Trào VNDC T4" tab "Danh sách đội", đội "Hà Nội Pickleball Team" ở đầu danh sách có 2 chip VĐV.
