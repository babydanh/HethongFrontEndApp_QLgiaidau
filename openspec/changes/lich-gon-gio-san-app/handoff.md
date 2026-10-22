# Bàn giao: lich-gon-gio-san-app

## Mục tiêu
Lưới lịch App gọn như Web: giờ và sân một cụm "🕐 giờ / sân", bỏ chữ "Sân", chip màu theo chỉ số sân, thu nhỏ thang giờ.

## Trạng thái
Code xong, đã commit trên nhánh. Web xong ở nhánh `lich-gon-gio-san` (999cad85).
Đã chạy: `openspec validate --strict` exit 0; `dart analyze` 4 file lib sửa/tạo: No issues, exit 0.
CHƯA chạy (hook đĩa 7.5GB chặn): `flutter test` các file lịch, `dart analyze` file test, `dart format`. Test mới chưa xác nhận đỏ/xanh. Chạy trên cloud (cloud-test-runner) trước khi gộp.
Nguy cơ xung đột: lane `results-awards-layout` cũng sửa `schedule_grid.dart` (import, ScheduleGrid, khoảng dòng 634-767).

## Đã thử: cách → kết quả → vì sao
- Thu nhỏ slot 30% như Web (144 thành 100) → bỏ → thẻ đôi 15 phút cần 108dp (avatar 14dp theo `core/participants`), nhỏ hơn thì thẻ tràn ô và đẩy trận kế sang lane mới. Chọn 112.

## Ràng buộc đang có
Không `flutter run`/build; `flutter test` cần asset `.env` (worktree không có, không tạo). Không thêm khoá i18n; nhiều lane sửa `.arb`, không đụng.

## Ràng buộc thay đổi lần này
Màu theo sân là ngoại lệ có chủ đích của quy ước "màu thẻ = trạng thái" (giống Web). Ràng buộc đang có: không đổi (đã so).

## Câu hỏi còn mở
- Kiểm hình ảnh thật trên thiết bị.
