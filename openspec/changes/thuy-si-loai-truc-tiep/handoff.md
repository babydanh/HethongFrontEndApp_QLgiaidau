# Bàn giao: thuy-si-loai-truc-tiep (App)

## Mục tiêu
App hiểu "Thụy Sĩ + loại trực tiếp": cấu hình `advanceTopN` và hiển thị hai phần (Thụy Sĩ, loại trực tiếp) kèm đường ngăn top N. Hợp đồng chung: `design.md` (Backend và Web cùng bản).

## Trạng thái
Đã lập plan, `openspec validate thuy-si-loai-truc-tiep --strict` pass. Chưa code (mọi task `[ ]`). Nhánh `thuy-si-loai-truc-tiep` tách từ `origin/thuy-si-20261021` (App không có staging).

## Đã thử
- Khảo sát App (2026-10-22): `bracket_view_screen.dart:310-323` và `public_bracket_view.dart:43-60` cho nhánh Swiss thắng mọi nhánh khác nên cây loại trực tiếp bị bỏ; `planSwissSave` gửi cả khối `swiss` khi PATCH stage nên `SwissConfig` phải mang `advanceTopN` qua `fromJson`/`toJson`, nếu không Backend trả `SWISS_ADVANCE_LOCKED`.
- App chưa có chỗ nào gọi `advance-standings` (vòng bảng) nên cũng không thêm nút `swiss/advance` (người dùng duyệt phạm vi 2026-10-22: BTC bấm trên Web).

## Ràng buộc đang có
- Không sửa `generated_plugin*`; không commit file sinh. Không chạy `flutter run`/build/integration test.
- Tám test cũ của `test/features/public_bracket_view_test.dart` đỏ sẵn (thiếu asset/`.env`): không tính là lỗi mới.
- Lane `chay-app-scrcpy-20261018` có dòng chồng ở `test/core/utils/match_round_label_test.dart`: không sửa file đó.
- Không push `main`; commit hẹp, không `Co-Authored-By`.

## Ràng buộc thay đổi lần này
Thêm vào hợp đồng Swiss: `advanceTopN`, stage 2 `Vòng loại trực tiếp`, cảnh báo/mã lỗi mới (App chỉ hiển thị, không gọi route mới). Hợp đồng cũ giữ nguyên (đã so).

## Câu hỏi còn mở
- Có cần nút "Đưa vào loại trực tiếp" trong App cho BTC chỉ dùng điện thoại không (hiện không).
- `SwissStageInfo` có thể cần getter `advanceTopN` (task 2.2 ghi rõ chỉ thêm getter).
