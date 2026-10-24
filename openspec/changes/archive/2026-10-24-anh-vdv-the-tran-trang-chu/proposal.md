# Proposal

## Why

Thẻ giải ở Trang chủ (`lib/features/explore/widgets/live_tournament_with_matches_card.dart`) chỉ vẽ chữ viết tắt cho VĐV (`_DoubleAvatarWidget`, `_buildLargeAvatar`), dù `GET /matches` đã trả ảnh thành viên và `MatchModel.team1MemberInfos`/`team2MemberInfos` đã đọc `avatarUrl`. Người xem thấy "NM", "HL" thay cho ảnh của Nguyễn Minh Danh, Hoang Linh, trong khi màn chi tiết trận có ảnh. Đo production 2026-10-19: các trận "Sắp diễn ra" của "Giải Thứ 4 giao lưu VNDC", "Giải Giao Lưu VNDC T6" đều có `avatarUrl` cho cả hai đội.

## What Changes

- Dòng đội ở thẻ "Sắp diễn ra"/lịch ngang (`_DoubleAvatarWidget`, 4 chỗ gọi) và ảnh lớn ở thẻ trận đang đấu (`_buildLargeAvatar`, 2 chỗ gọi) hiện ảnh VĐV từ `teamNMemberInfos`; tối đa 2 ảnh mỗi đội.
- Lọc trùng thành viên theo `userId` (rỗng thì theo tên): API hiện trả cùng một người nhiều lần trong `participant.members`.
- Không có ảnh hoặc ảnh lỗi: giữ vòng tròn chữ viết tắt như hiện tại.

## Capabilities

### New Capabilities

- `home-match-card-avatars`: ảnh VĐV trên thẻ trận ở Trang chủ.

### Modified Capabilities

(không có)

## Out of scope

- Logo giải: các giải trong ảnh người dùng chưa đặt `logoUrl`, App hiện logo SportO mặc định là đúng; không đổi.
- Không sửa lỗi Backend trả trùng thành viên trong `participant.members` của `GET /matches` (ghi nhận, làm change Backend riêng).
- Không đổi Web.

## Impact

- App: `lib/features/explore/widgets/live_tournament_with_matches_card.dart`, test widget mới cho thẻ trận.
- API dùng sẵn: `GET /api/v1/matches` (`participant1.members[].avatarUrl`).
