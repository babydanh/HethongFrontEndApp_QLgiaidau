# Bàn giao: lich-gon-gio-san-app

## Mục tiêu
Lưới lịch App gọn như Web: giờ và sân một cụm "🕐 giờ / sân", bỏ chữ "Sân", chip màu theo chỉ số sân, thu nhỏ thang giờ.

## Trạng thái
Code xong, đã commit trên nhánh. Web xong ở nhánh `lich-gon-gio-san` (999cad85).
Đã chạy: `openspec validate --strict` exit 0; `dart analyze` 4 file lib sửa/tạo: No issues, exit 0.
Cloud `--target app --branch lich-gon-gio-san-app` (run 40099718449): analyze + widget test xanh, exit 0. `flutter-reviewer`: không P0/P1, GỘP ĐƯỢC; còn P2 (chip sân co về ~10dp trên thẻ LIVE ở làn 120dp, `schedule_grid.dart:994-1025`) để làm sau.
CHƯA làm: `dart format` (sẽ đổi 3 file kể cả code cũ ngoài phạm vi, nên bỏ qua), kiểm hình trên thiết bị (3.2).
Nguy cơ xung đột: lane `results-awards-layout` cũng sửa `schedule_grid.dart` (import, ScheduleGrid, khoảng dòng 634-767).

## Đã thử: cách → kết quả → vì sao
- Thu nhỏ slot 30% như Web (144 thành 100) → bỏ → thẻ đôi 15 phút cần 108dp (avatar 14dp theo `core/participants`), nhỏ hơn thì thẻ tràn ô và đẩy trận kế sang lane mới. Chọn 112.

## Ràng buộc đang có
Không `flutter run`/build; `flutter test` cần asset `.env` (worktree không có, không tạo). Không thêm khoá i18n; nhiều lane sửa `.arb`, không đụng.

## Ràng buộc thay đổi lần này
Màu theo sân là ngoại lệ có chủ đích của quy ước "màu thẻ = trạng thái" (giống Web). Ràng buộc đang có: không đổi (đã so).

## Câu hỏi còn mở
- Kiểm hình ảnh thật trên thiết bị.
