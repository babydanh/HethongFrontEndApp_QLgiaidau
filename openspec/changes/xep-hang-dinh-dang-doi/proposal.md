## Why

Màn Xếp hạng trên App chỉ còn hai chip Nam/Nữ: commit `56e51956` (2026-09-16) đã gỡ 5 chip định dạng, và `LeaderboardScreen` luôn gửi `matchType: ''` nên Backend không bao giờ trả bảng đôi. Backend (`rankings.repository.ts`) vẫn hỗ trợ `matchType = DOUBLES | MIXED_DOUBLES` (nhánh `pairRanks`) và Web (`RankingsTab.tsx`) vẫn có bộ lọc Định dạng. Người dùng chọn phương án A (2026-10-26): khôi phục chip định dạng theo kiểu Web, hàng đôi hiện tên cả hai VĐV.

## What Changes

- Thêm hàng chip **Định dạng** (Tất cả / Đơn / Đôi / Đôi nam nữ) phía trên hàng chip Nam/Nữ ở `LeaderboardScreen`; mặc định "Tất cả" (giữ đúng hành vi hiện tại: không gửi `matchType`).
- Chọn định dạng thì gửi `matchType` thật (`SINGLES` / `DOUBLES` / `MIXED_DOUBLES`) cho `GET /rankings`.
- Chip Nam/Nữ ẩn khi chọn "Đôi nam nữ"; khi đó không gửi `genderRestriction` (chỉ lọc theo `matchType`). Các định dạng còn lại vẫn gửi MALE/FEMALE như cũ.
- Hàng đôi hiển thị tên cả hai VĐV: bục podium dùng `displayName` thay `fullName`; ô tìm kiếm khớp cả tên đội và tên từng VĐV trong cặp.
- Không thêm key l10n mới: dùng lại `filterAll`, `clubRankingSingles`, `clubRankingDoubles`, `doublesMixed`, `clubRankingMale`, `clubRankingFemale`.

## Out of scope

- Backend và Web không đổi (không đổi route/DTO; chỉ dùng tham số `matchType` đã có).
- Bảng xếp hạng bóng đá theo đội (`footballTeamRankingsProvider`) và chip giới tính của nó.
- Lỗi cũ: nút thử lại dùng `_rankingQuery` lệch `_selectedCategory` thô; tách file `leaderboard_screen.dart` (711 dòng).
- Dữ liệu `pairRanks` thật ở từng môi trường (bảng đôi có thể trống; App hiển thị trạng thái rỗng sẵn có).

## Capabilities

### New Capabilities
- `app-ranking-format-filter`: Bộ lọc định dạng (đơn/đôi/đôi nam nữ) ở màn Xếp hạng và hiển thị tên cặp ở hàng đôi.

### Modified Capabilities
- (không)

## Impact

- Sửa: `lib/features/rankings/screens/leaderboard_screen.dart` (state `_matchType`, hai chỗ dựng `RankingQuery`, hàng chip, haystack tìm kiếm), `lib/features/rankings/widgets/podium_view.dart:176` (`displayName`).
- Repo khác: Backend `GET /rankings` đã nhận `matchType` và `genderRestriction`, không cần sửa; Web `RankingsTab.tsx` là chuẩn tham chiếu.
- Rủi ro: bảng đôi có thể trống trên môi trường chưa có `pairRanks`; hàng đôi cần `players` từ Backend (fixture test dùng dữ liệu giả).
