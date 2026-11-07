## Why

Người chấm điểm bấm đội thắng pha nhưng đội đó đang nhận bóng ở pickleball side-out thì nút "+" bị khoá, chỉ có "ĐỔI GIAO" không giải thích, nên tưởng App sai luật. Cầu lông, bóng bàn, tennis không cho biết ai đang giao; tennis không dùng `noAd`/`finalSetMode`/`tiebreakMode` dù có trong cấu hình; bóng đá ghi thẻ/thay người nhưng không có hậu quả. Người dùng đã duyệt bản thiết kế tương tác `reference/design-prototype.html` (Lavish) và yêu cầu làm hết.

## What Changes

Quyết định mặc định theo đề xuất trong trang thiết kế (người dùng ra lệnh làm hết, chưa tick riêng): Q1-A, Q2-A, Q3-A, Q4 đủ ba mục, Q5 đủ ba mục.

- **Pickleball (side-out):** bấm "+" của đội nhận = đội giao thua pha (Giao 1 → Giao 2 → đổi giao, không ai được điểm), kèm thông báo giải thích; nút giữa đổi nhãn thành "MẤT GIAO" kèm dòng "→ Giao 2 / → đổi giao". Sân ngang tràn mép trái như đã tràn mép phải (lỗi "bên trái không full"). Lite mặc định Rally (không hiện giao bóng side-out).
- **Cầu lông, bóng bàn, tennis:** thêm dòng "● GIAO" dưới tên đội (cầu lông thêm ô phải/trái và VĐV khi đánh đôi). Chỉ hiển thị, cách bấm điểm không đổi.
- **Tennis:** hỗ trợ No-Ad, match tie-break 10 điểm thay set quyết định, tie-break theo cấu hình (không cứng 6-6).
- **Bóng đá:** ghi thẻ hỏi số áo, vàng thứ 2 tự thành đỏ, đếm cầu thủ trên sân, dưới 7 người thì trận dừng; giới hạn số lần thay người (mặc định 5); chỉ ghi bàn khi đang trong hiệp/bù giờ.
- **Web:** cùng bộ luật cho phần chấm điểm của Web (tennis tie-break theo cấu hình, No-Ad, match tie-break, hiển thị giao bóng, bóng đá nếu Web có màn chấm), kèm nhặt lại hai commit giao bóng mở màn đã có ở nhánh `giao-bong-mo-man`.

## Out of scope

- Backend (không đổi API/schema; chỉ đọc cấu hình đã có). Công tắc Rally/Side-out ngay trong Lite cần Backend nên để lại.
- Luật bóng bàn "expedite" sau 10 phút, nghỉ 60/120 giây có đếm giờ thật, hình phạt thẻ (treo giò).
- Tab "Phạt", thanh bên dưới ("Ngoại lệ / Xử thắng / Chốt set / Lưu") giữ nguyên.
- Đẩy lên `main` Web (deploy production) và staging: chờ người dùng nói đúng.

## Capabilities

### New Capabilities
- `cach-bam-diem-cac-mon`: cách bấm điểm và hiển thị giao bóng/luật theo môn.

### Modified Capabilities
(không)

## Impact

- App Flutter: `lib/features/match/` (widgets, notifiers), `lib/domain/services/`, `lib/utils/pickleball_court.dart` nếu cần, 2 file `.arb`, test.
- Web Next.js: `src/features/matches/`, màn chấm điểm trong `src/app/organizer/tournaments/[id]/ops/components/scoring/`, `src/app/(public)/live/[matchId]/components/`.
- Không thêm package.
