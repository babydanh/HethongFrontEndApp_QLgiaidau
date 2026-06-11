# 🔄 REFACTOR PLAN (UPDATED)

> **Last Updated:** June 2, 2026
> **Status:** Planning

---

## 🎯 CÁC MỤC TIÊU CHÍNH TỪ USER FEEDBACK

### 1. Tăng khoảng cách Nhánh Thắng - Nhánh Thua
- **Vấn đề:** Hiện tại nhánh thắng và nhánh thua trong màn hình Bracket đang nằm quá sát nhau, gây rối mắt.
- **Giải pháp:** Sửa file `bracket_view_screen.dart`, tăng tham số `separation` trong thuật toán vẽ cây `SeparatedBuchheimWalkerAlgorithm` và cấu hình lại `levelSeparation`, `subtreeSeparation` để đẩy 2 nhánh xa nhau ra hơn.

### 2. Giao diện Viewer (Khán giả)
- **Vấn đề:** Khán giả khi ấn "Vào giải đấu ngay" thì bị chuyển đến trang `LiveMatchScreen` (hiển thị danh sách dọc xấu) thay vì nhìn thấy Sơ đồ thi đấu dạng cây.
- **Giải pháp:** Cập nhật `app_router.dart` để route mặc định của `/viewer` trỏ thẳng tới `BracketViewScreen`. Người dùng vẫn có thể xem được dạng cây tuyệt đẹp. (Vẫn giữ tab cho Đấu Vòng Tròn).

### 3. Lỗi số vòng mặc định ở Đấu Vòng Tròn (Round Robin)
- **Vấn đề:** User phàn nàn "nhập mấy vòng rồi vô vẫn thấy 20 vòng mặc định".
- **Giải thích & Giải pháp:** Đang có sự hiểu nhầm về logic "Số vòng" (Number of rounds) và "Số lượt" (Cycles). Khi nhập vòng, code đang hiểu sai mục đích. Tôi sẽ rà soát lại file `create_tournament_screen.dart` (đoạn textfield) và `RoundRobinGenerator` để sửa thành hiển thị đúng số vòng mong muốn, thay vì render 20 match/vòng mặc định không cần thiết.

### 4. Dọn dẹp giao diện Bốc thăm (Auto Draw Screen)
- **Vấn đề:** Sau khi bốc thăm, màn hình hiển thị quá nhiều trận đấu "Ma" dạng `?? vs ??` hoặc `BYE vs BYE` gây rối.
- **Giải pháp:** Tại file `auto_draw_screen.dart`, khi hiển thị `_previewMatches`, ta sẽ thêm bộ lọc (filter) để ẩn đi các trận đấu mà cả 2 đội đều là TBD (Chờ xác định) hoặc BYE, chỉ giữ lại các trận có tên đội thực sự để nhìn cho gọn gàng.
