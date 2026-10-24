# Proposal

## Why

Người dùng báo 2026-10-19 (ảnh "Giải Thứ 4 giao lưu VNDC", nội dung Đôi Nam):

- Thẻ trận Trang chủ chỉ có nhãn "B", trong khi trận thuộc "Vòng bảng", bảng B. Người xem không hiểu "B" là gì.
- Mỗi đội chỉ có một vòng tròn chữ viết tắt tên đội ("CP", "BH"). Màn Chi tiết trận cũng chỉ có một chữ "C", "B" và dòng "ELO Đơn" cho một trận đôi.

Đo production cùng ngày: cả 8 đội của giải là cặp VĐV chưa có tài khoản. `GET /tournaments/:id/participants` trả `guestNames` (vd `["Nguyễn Minh Anh", "Trần Quốc Bảo"]`), nhưng `GET /matches` trả `participant.members: []` và không có `guestNames`. Vì vậy App không biết đội có 2 người. Backend có change riêng `guest-names-tran-dau` để thêm `guestNames` vào payload trận.

## What Changes

- App đọc `participantN.guestNames` của `GET /matches` và `GET /matches/:id`, nối sau thành viên có tài khoản (chỉ có tên, không ảnh, không `userId`), giống cách `api_team_repository.dart` đang làm với danh sách đội.
- Thẻ trận Trang chủ (3 kiểu thẻ trong `live_tournament_with_matches_card.dart`): đội có 2 VĐV hiện 2 vòng tròn, mỗi vòng là ảnh hoặc chữ viết tắt tên của chính VĐV đó.
- Chi tiết trận: dưới tên đội hiện 2 vòng tròn VĐV, ELO ghi "ELO Đôi". Ô của VĐV khách không bấm mở hồ sơ.
- Nhãn vòng bảng giống Web: "Bảng B • Lượt 1" (thẻ hẹp: "Bảng B"), thay cho "B".

## Capabilities

### New Capabilities

- `match-athlete-display`: cách App hiện VĐV của mỗi đội trên thẻ trận và Chi tiết trận, gồm VĐV chưa có tài khoản.
- `match-round-label`: chữ hiển thị vòng/bảng của một trận.

### Modified Capabilities

(không có)

## Out of scope

- "Môn: Cầu lông" trên Chi tiết trận của giải Pickleball: ghi nhận (`SportRuleService.fromString(null)` mặc định Cầu lông), làm change riêng.
- Không đổi Web.

## Impact

- App: `lib/domain/entities/match.dart` (hoặc nơi parse participant của trận), `lib/features/explore/widgets/live_tournament_with_matches_card.dart`, `lib/features/match/screens/live_score_screen.dart`, `lib/core/utils/match_round_label.dart`, `lib/l10n/app_vi.arb`, `app_en.arb`.
- Phụ thuộc Backend `guest-names-tran-dau` đã deploy. Trước khi deploy, App vẫn chạy như hiện tại (không có `guestNames` thì không đổi gì).
