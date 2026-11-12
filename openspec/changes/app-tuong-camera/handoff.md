# Handoff: Tường camera App (lưới 1×1/2×2/3×3/4×4)
<!-- Đọc file này TRƯỚC khi làm tiếp nhánh. Cập nhật TRƯỚC khi báo xong, fast-handoff, hoặc hết phiên. -->
Cập nhật: 2026-11-12 · bởi: claude · nhánh: app-tuong-camera · OpenSpec: app-tuong-camera

## Mục tiêu
BTC mở tab Camera trên App, bấm "Xem camera" để xem nhiều camera của giải cùng lúc theo lưới 1×1, 2×2, 3×3, 4×4, mỗi ô ghi trận đang chiếu. Xem `proposal.md`, `specs/camera-wall-app/spec.md`, `tasks.md`.

## Trạng thái
- Xong: 1.1, 2.1, 2.2, 2.3, 3.1 (đã tick trong `tasks.md`). Test 5 file của 3.1: 54 pass / 0 fail. `flutter analyze --no-pub lib/features/tournament lib/l10n`: 0 error, 0 warning, 6 info cũ ở file không sửa.
- Đang dở: không. Chưa push main, chưa merge-lane, chưa archive (theo yêu cầu).
- Tiếp theo: người dùng xem PR/nhánh, tự gộp và archive OpenSpec.

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| Đối chiếu Web `camera-tuong-xem-giai` | thành công | Web có `camera-wall.ts` + `CameraWall.tsx`, E2E 5/5 pass (run 43265705027) |
| Dựng `LiveVideoPlayer` thẳng vào ô 3×3/4×4 | thất bại | Cột "chưa có tín hiệu" và hàng điều khiển bên trong tràn (RenderFlex) ở ô nhỏ; không sửa được file đó. Cách đã dùng: dựng ở cỡ ảo tối thiểu 280×240 rồi `FittedBox` thu nhỏ (`_ScaledPlayer`), `IgnorePointer` |
| `onDoubleTap` ở cả ô | thất bại | Tranh cử chỉ với `Switch`, nuốt lần chạm đầu của công tắc. Cách đã dùng: gắn chạm đúp riêng lên tên, vùng hình và dòng trận |
| `flutter test --no-pub` ngay sau khi clone | thất bại | Thiếu `.dart_tool`; cần `flutter pub get` một lần (không đổi pubspec) |

## Ràng buộc đang có
- Không đổi Backend/Web, không thêm package, không thêm route vào `app_router.dart` (nguồn: proposal).
- Công tắc xem thử chỉ gắn/gỡ `LiveVideoPlayer` trên máy, không gọi API (nguồn: spec).
- Chuỗi hiển thị chỉ qua `.arb` + `flutter gen-l10n`; không sửa tay `app_localizations*.dart` (nguồn: AGENTS.md).
- Chỉ chạy test các file trong `tasks.md`; không chạy cả bộ, không E2E; `dart format` chỉ file mình sửa (nguồn: AGENTS.md, người dùng).
- Không đọc/in `.env`; test cần `.env` thì chép từ `.env.example` như CI (nguồn: AGENTS.md).

## Ràng buộc thay đổi lần này
- Thêm: ô trong tường camera không nhận chạm vào trình phát (`IgnorePointer`), nên thanh điều khiển của `LiveVideoPlayer` không bấm được trong tường; chỉ chạm đúp phóng to và công tắc xem thử.
- Thêm: không gắn `onDoubleTap` lên cả ô, để công tắc nhận chạm đầu tiên.
- Thêm: `LiveVideoPlayer` trong ô luôn đi qua `_ScaledPlayer`, không dựng trực tiếp.

## Câu hỏi còn mở
- không
