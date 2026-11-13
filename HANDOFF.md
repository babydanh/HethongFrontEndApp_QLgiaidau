# Handoff: App - avatar màu chuẩn chung + Lịch thi đấu kéo chọn
<!-- Đọc file này TRƯỚC khi làm tiếp nhánh. -->
Cập nhật: 2026-11-13 · bởi: claude · nhánh: app-avatar-chung-lich-keo-chon · OpenSpec: không có

## Mục tiêu
Người dùng (ảnh chụp tab "Danh sách đội" của giải trên App) muốn 3 việc trên App Flutter:
1. **Avatar chữ cái có màu theo chuẩn chung như Web.** Hiện danh sách đội hiện vòng tròn xám + chữ xám; Web dùng màu theo TÊN (ổn định, một người một màu ở mọi nơi). Rà các chỗ khác trong App còn avatar xám/màu riêng và đưa về cùng chuẩn.
2. **Tab "Lịch thi đấu": kéo chọn hình chữ nhật kiểu Windows** — nhấn giữ rồi kéo ở vùng trống ngoài thẻ, vẽ khung chữ nhật chọn các ô/trận nằm trong khung, trên toàn bề mặt lưới của tab.
3. **Lưới sân × giờ: bấm vào tiêu đề sân (hoặc giờ) thì chọn hết các ô của sân (hoặc giờ) đó.**

## Trạng thái
- Xong: chưa làm gì ở nhánh này (chỉ tạo nhánh từ origin/main).
- Đang dở: không.
- Tiếp theo: đọc code theo "Gợi ý vị trí" bên dưới, làm theo thứ tự 1 → 3, mỗi việc một commit hẹp có test.

## Gợi ý vị trí (đã kiểm bằng ripwire/git grep trên origin/main, chưa sửa gì)
- **Chuẩn màu Web** (nguồn sự thật): `HethongFrontEndWeb_QLgiaidau/src/utils/avatar-fallback.ts` → `AVATAR_FALLBACK_COLORS` 8 màu (#2563eb #c2410c #047857 #7e22ce #be123c #475569 #0f766e #b45309), chữ trắng, hash theo TÊN (NFC, trim, gộp khoảng trắng, lower `vi`), chữ cái = chữ đầu của từ đầu + chữ đầu của từ cuối.
- **App đã có sẵn bản tương đương**: `lib/core/participants/participant_display.dart` → `avatarFallbackColor(name)` (~dòng 527), `avatarInitials(name)` (~538), danh sách `_avatarFallbackColors` (~514). Phải đối chiếu 8 màu + thuật toán hash với Web, nếu lệch thì sửa cho khớp Web.
- **Nguyên nhân avatar xám ở tab Danh sách đội**: `ParticipantSideLines` (cùng file, ~dòng 338) có cờ `coloredAvatars` mặc định `false`; chỉ `lib/features/tournament/widgets/results_tab.dart:364` bật `true`. Màn Danh sách đội không bật nên ra xám. Cách sửa gọn: đổi mặc định thành màu chuẩn (hoặc bật ở mọi nơi gọi) rồi gỡ nhánh xám nếu không còn dùng.
- Các chỗ khác nghi còn avatar riêng: 28 file có `CircleAvatar(`, tiêu biểu `lib/features/social/widgets/social_avatar.dart` (dùng `AppTheme.primary`), `lib/features/chat/screens/chat_detail_screen.dart:1173,1559`, `lib/core/widgets/app_menu_sheet.dart:512`, `lib/features/tournament/widgets/tournament_contact_form.dart`. Chỉ đổi avatar CHỮ CÁI KHÔNG ẢNH (fallback); ảnh người dùng giữ nguyên.
- **Lịch thi đấu**: `lib/features/tournament/widgets/schedule_grid.dart` (`ScheduleGrid`, đã có `onRangeSelected` + `onLongPressStart/MoveUpdate/End` quanh dòng 457-465 = chọn khoảng bằng nhấn giữ) và `lib/features/tournament/widgets/tournament_schedule_court_grid.dart` (`TournamentScheduleCourtGrid`, build ~dòng 295, `_toolbar` ~877, có `selectedCourts`). Mở rộng đúng cơ chế sẵn có thành khung chữ nhật, KHÔNG viết lại lưới.

## Ràng buộc đang có
- Chỉ làm trong App (`HethongFrontEndApp_QLgiaidau`); không đổi Backend/Web, không đổi hợp đồng API. (nguồn: người dùng nói "app nha")
- Kéo chọn không được làm hỏng cuộn dọc/ngang của lưới trên điện thoại: dùng nhấn giữ rồi kéo (long-press) ở vùng trống, kéo bình thường vẫn là cuộn. (nguồn: UX trên di động)
- Test nặng (`flutter analyze` toàn repo, full `flutter test`) chạy trên GitHub Actions (`cloud-test-runner.py --target app`); trên máy cloud chỉ chạy `flutter test --no-pub <file>` từng file. Thêm test ID dạng `TC-APP-AVATAR-01`, `TC-APP-SCHED-MARQUEE-01`, giữ test cũ.
- Màu chữ trên avatar phải giữ trắng, độ tương phản WCAG AA như Web. (nguồn: comment trong `avatar-fallback.ts`)
- Commit tiếng Việt, hẹp đúng file, không `Co-Authored-By`; KHÔNG push `main` (App không deploy nhưng vẫn để người dùng duyệt). Không đụng 7 file generated EOL (`linux/`, `macos/`, `windows/` generated_plugin*).

## Ràng buộc thay đổi lần này
- Thêm: toàn bộ danh sách trên (lần đầu bàn giao nhánh này).
- Bỏ: không có.

## Câu hỏi còn mở
- Việc 2 và 3 người dùng viết ngắn nên có chỗ chưa chắc: (a) "chọn" xong thì làm gì (chọn nhiều trận để đổi sân/giờ/xoá, hay chỉ tô sáng)? (b) "sân giờ xẹt" hiểu là bấm tiêu đề sân/giờ → chọn hết ô thuộc hàng/cột đó. Nếu code hiện tại đã có khái niệm ô đang chọn (`onRangeSelected`) thì dùng lại nó và hành động sau chọn y như hiện có; không tự thêm hành động mới. Ghi rõ cách hiểu đã chọn vào mô tả commit/PR.
