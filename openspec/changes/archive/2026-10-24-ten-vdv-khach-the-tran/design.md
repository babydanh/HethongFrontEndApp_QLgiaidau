# Design

## Context

- `MatchModel` lấy VĐV từ `participantN.members` ở 2 nơi parse: `api_match_repository.dart` (`_parseMemberInfos`, ~559) và `match.dart` (`parseMemberInfos`, ~334). Cả hai bỏ qua `guestNames`.
- Danh sách đội (`api_team_repository.dart:286-295`) đã nối `guestNames` thành `MatchMemberInfo(fullName: name)` không `userId`.
- Thẻ trận Trang chủ đã có `_uniqueMembers` (lọc trùng theo `userId`, rỗng theo tên; tối đa 2) và vẽ ảnh/chữ viết tắt theo từng VĐV (change `anh-vdv-the-tran-trang-chu`).
- Chi tiết trận `_buildTeamAvatarWidget` (`live_score_screen.dart:2645`) đã vẽ 2 vòng tròn khi `displayList.length >= 2`; ô không có `userId` đã là `CircleAvatar` không bấm được.
- `MatchRoundLabel.groupOrRoundRobinName` trả nguyên `group.name` ("B").

## Goals / Non-Goals

**Goals:** đội khách hiện đúng 2 VĐV ở mọi thẻ trận và Chi tiết trận; nhãn bảng tự giải thích.

**Non-Goals:** đổi layout thẻ; sửa nhãn "Môn"; đổi Web.

## Decisions

- **Nối `guestNames` ở tầng parse**, không ở widget. Mọi màn đọc `teamNMemberInfos` (thẻ, Chi tiết trận, ELO đôi) tự đúng, cùng cách danh sách đội đang làm. Phương án khác: App gọi thêm `GET /tournaments/:id/participants` để tra tên. Loại vì thêm một request mỗi giải ở Trang chủ, và trái quyết định "`guestNames` tính một chỗ ở Backend".
- **Một helper chung** nối `guestNames` cho cả 2 nơi parse, tránh lệch thứ tự.
- **Nhãn bảng giống Web** (`match-round-label.ts` của Web: `groupPrefix` "BẢNG {name}" + `legSuffix` "Lượt {n}", nối bằng " • "): tên bảng "B" hoặc "Bảng B"/"Group B" → "Bảng B"; tên khác giữ nguyên. Key l10n mới `matchRoundGroupPrefix` ("Bảng {name}" / "Group {name}"), `matchRoundLegSuffix` ("Lượt {leg}" / "Leg {leg}").

## Risks / Trade-offs

- Phụ thuộc Backend `guest-names-tran-dau` deploy. Trước đó App không đổi hành vi (trường vắng mặt).
- Nhãn dài hơn ở thẻ Trang chủ: thẻ dọc đủ chỗ; thẻ ngang 275px dùng bản ngắn "Bảng B".
