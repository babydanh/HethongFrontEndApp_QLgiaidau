# Plan: Match Schedule Card Redesign

## Mục tiêu
Thiết kế lại card trận đấu trong tab Lịch thi đấu (BracketViewScreen) cho rõ ràng:

## Yêu cầu
1. Card hiển thị: vòng đấu, trạng thái (Sắp đá/Live/Hoàn tất), giờ, địa điểm/sân
2. 2 đội + tỷ số, điểm từng set
3. Nút "Xem chi tiết" để xem đầy đủ
4. Tuân thủ SKILLS.md: SOLID, AppTheme, AppLogger, context.colors

## Component
- `MatchCardDetail` — sửa lại, giữ nguyên class name (đã dùng ở nhiều chỗ)
- Thêm expand sets + detail button

## States
- Scheduled: border xám, "SẮP ĐÁ"
- Live: border đỏ + glow, "LIVE" pulse
- Completed: border xanh, "HOÀN TẤT", winner highlight

## Luồng
1. BracketViewScreen gọi matchesProvider → list match
2. Render từng match → MatchCardDetail
3. Bấm card → navigate /referee/match/:id hoặc /admin/tournament/:id/match/:id
4. Bấm "Xem chi tiết" → cũng navigate
5. Bấm "Chi tiết set" → expand sets inline
