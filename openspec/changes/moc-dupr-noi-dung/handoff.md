# Handoff: moc-dupr-noi-dung (App)
Cập nhật: 2026-10-29 · bởi: claude · nhánh: moc-dupr-noi-dung · OpenSpec: moc-dupr-noi-dung

## Mục tiêu
App cho BTC đặt mốc DUPR ở editor nội dung pickleball, và cho VĐV thấy mốc, kiểm điểm, khai điểm ở màn đăng ký (đơn và đôi). Chi tiết: `proposal.md`, `design.md`.

## Trạng thái
- Xong: task 1.1–6.1 đã tick. `flutter test --no-pub` 9 file/thư mục DUPR + `test/registration` → exit 0, 89 test pass. `flutter analyze --no-pub` 6 thư mục → 49 mục có sẵn, không có mục mới (`doubles_registration_screen.dart:545` và `tournament.dart:675` có từ trước). `openspec validate moc-dupr-noi-dung --strict` exit 0. `flutter-reviewer` lượt 2: GỘP ĐƯỢC.
- Đang dở: không.
- Tiếp theo: xem màn thật khi người dùng cần (app chung chưa chạy: `app-run.py start`); chờ Backend lên.

## Đã thử
| Cách | Kết quả | Vì sao / bằng chứng |
|---|---|---|
| Card đọc `division.categoryId` | bỏ | `GET /tournaments/:id/divisions` không trả categoryId; card luôn ẩn. Thay bằng `division.categoryId ?? categoryId của giải` (`f1c4c30e`) |
| Lỗi tải điểm không có lối thoát | đã sửa | thêm nút Thử lại (`602bcd67`) |
| Race tải điểm / `_duprValid` kẹt khi gỡ card | đã sửa | `_loadSeq`, báo hợp lệ trong dispose (`a894277a`) |

## Ràng buộc đang có
- Backend là nguồn sự thật; client chỉ hướng dẫn. Phụ thuộc Backend `moc-dupr-noi-dung` (cùng tên) apply trước.
- Không đổi kiểm ELO (cố ý để nguyên).
- Cây có `linux|macos|windows/flutter/generated_plugin*` bị sửa sẵn do git-wt: không đụng, không add.

## Ràng buộc thay đổi lần này
- Thêm: `Tournament.categoryId` (lib/domain/entities/tournament.dart) phục vụ card; ghi quy tắc vào `design.md` D2.
- Bỏ: không.

## Câu hỏi còn mở
- Ô khai điểm lưu `isPublic: true` không hỏi người dùng (Backend lộ 1 bit điểm đồng đội khi đăng ký đôi: xem handoff Backend).
- P3 chưa sửa: `didUpdateWidget` nhánh `else` không tăng `_loadSeq` (`dupr_limit_card.dart:73-87`); nút đăng ký bật ngắn khi `categoryId` giải chưa về (`:65-69`).
- Chưa có test cấp màn đăng ký cho việc truyền `categoryId` và khoá nút; chưa chạy app thật.
