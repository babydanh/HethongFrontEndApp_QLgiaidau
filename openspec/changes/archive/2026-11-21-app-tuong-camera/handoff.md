# Handoff: Tường camera App (lưới 1×1/2×2/3×3/4×4)
<!-- Đọc file này TRƯỚC khi làm tiếp nhánh. Cập nhật TRƯỚC khi báo xong, fast-handoff, hoặc hết phiên. -->
Cập nhật: 2026-11-13 00:30 · bởi: claude · nhánh: app-tuong-camera · OpenSpec: app-tuong-camera

## Mục tiêu
BTC mở tab Camera trên App, bấm "Xem camera" để xem nhiều camera của giải cùng lúc theo lưới 1×1, 2×2, 3×3, 4×4, mỗi ô ghi trận đang chiếu. Xem `proposal.md`, `specs/camera-wall-app/spec.md`, `tasks.md`.

## Trạng thái
- Xong: OpenSpec `app-tuong-camera` (proposal, spec, tasks). Người dùng đã nói "apply" và giao làm trên cloud.
- Đang dở: chưa có code.
- Tiếp theo: làm 1.1 → 2.1 (TDD) → 2.2 → 2.3 → 3.1 theo `tasks.md`, tick `- [x]` khi tiêu chí qua, commit từng task.

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| Đối chiếu Web `camera-tuong-xem-giai` | thành công | Web có `src/features/tournaments/camera-wall.ts` + `CameraWall.tsx`, E2E `test/e2e/camera-wall.spec.ts` 5/5 pass (run 43265705027) |

## Ràng buộc đang có
- Không đổi Backend/Web, không thêm package, không thêm route vào `app_router.dart` (nguồn: proposal).
- Công tắc xem thử chỉ gắn/gỡ `LiveVideoPlayer` trên máy, không gọi API (nguồn: spec).
- Chuỗi hiển thị chỉ qua `.arb` + `flutter gen-l10n`; không sửa tay `app_localizations*.dart` (nguồn: AGENTS.md).
- Chỉ chạy test các file trong `tasks.md`; không chạy cả bộ, không E2E; `dart format` chỉ file mình sửa (nguồn: AGENTS.md, người dùng).
- Không đọc/in `.env`; test cần `.env` thì chép từ `.env.example` như CI (nguồn: AGENTS.md).

## Ràng buộc thay đổi lần này
- Thêm: toàn bộ ràng buộc trên (lần đầu tạo file).

## Câu hỏi còn mở
- không
