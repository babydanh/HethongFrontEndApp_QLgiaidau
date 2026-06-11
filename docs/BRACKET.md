# Đặc tả Tính Năng Bracket (Cây Thi Đấu)
*(Tuân thủ kiến trúc Clean Architecture & SKILLS.md)*

Tài liệu này đặc tả chi tiết về cách thiết kế giao diện dạng cây (Tree Visualization) và logic tự động chuyển nhánh (Auto-advancement) cho vòng loại trực tiếp (Knockout/Single Elimination).

## 1. Yêu cầu Giao diện (UI) - Cây thi đấu chuyên nghiệp

### 1.1 Hình dáng Cây Thi Đấu (Tree Structure)
Thay vì hiển thị các trận đấu xếp dọc thô sơ, sơ đồ thi đấu phải được render theo dạng cây nối liền, phân cấp theo vòng sử dụng thư viện `graphview`.
- **Double Elimination:**
  - Vẽ **Nhánh Thắng (Winners Bracket)** và **Nhánh Thua (Losers Bracket)** riêng biệt nhưng được liên kết rõ ràng bởi `graphview`.
  - `graphview` sẽ tự động tính toán bố cục để đảm bảo các nhánh không chồng chéo và có khoảng cách hợp lý.
  - Kết nối giữa nhánh Thắng và nhánh Thua ở Chung kết Tổng (Grand Final) sẽ được thực hiện thông qua `graphview` edges, hiển thị rõ đội thắng nhánh Thua sẽ đối đầu với đội thắng nhánh Thắng.
  - Chỉ hiển thị các đội có thật trong các node, loại bỏ các ô "Bye" hoặc trống.
- **Round 1:** Chứa các đội ban đầu.
- **Tứ kết (Quarter-finals):** Chứa các đội thắng từ vòng trước.
- **Bán kết (Semi-finals):** Chứa các đội thắng từ vòng trước.
- **Chung kết (Final):** Chứa 2 đội (1 trận).

Mỗi cột tương ứng với một Vòng (Round). Người dùng có thể cuộn ngang (Scroll Horizontal) để xem các vòng tiếp theo.

### 1.2 Dây Nối (Connecting Lines)
- Giữa các khối `MatchNodeCard` của vòng hiện tại và vòng tiếp theo phải có **dây nối hình chữ C vuông (Cubic/Orthogonal Lines)**, được render bởi `graphview`.
- **Màu sắc dây nối:** 
  - Màu xám/nhạt (Mặc định) cho các trận chưa đấu.
  - Màu sáng (AppTheme.primary) nối từ đội chiến thắng tới trận tiếp theo (tô sáng đường đi của nhà vô địch). `graphview` sẽ được cấu hình để cho phép tùy chỉnh màu sắc cạnh dựa trên trạng thái trận đấu.

## 2. Logic Tự động Xếp Vòng Trong (Auto-advancement)

Để giải đấu tự vận hành một cách mượt mà, khi một trận đấu kết thúc, hệ thống phải tự động đẩy đội thắng vào nhánh tiếp theo.

### 2.1 Quy tắc Xác định Nhánh Đấu (Bracket Placement)
Mỗi trận đấu (MatchModel) cần được đánh số thứ tự (Ví dụ: Trận số 1, Trận số 2).
Logic cơ bản của Single Elimination:
- Đội thắng ở Trận `N` sẽ đi tiếp vào Trận `(N / 2)` của vòng tiếp theo.
- Trọng tài nhấn "Kết thúc trận đấu" (End Match) -> Kích hoạt lệnh trong `MatchNotifier` -> Hệ thống sẽ tính toán và `updateMatch()` cho trận tiếp theo trên Firestore.

### 2.2 Ràng buộc và Trạng thái
- Trận đấu ở vòng sau chỉ có thể chuyển sang trạng thái `In Progress` khi **CẢ HAI** trận đấu ở nhánh trước đã kết thúc và đẩy đội thắng vào.
- Nếu một trận đấu kết thúc do đối thủ bị Truất quyền (Default/Black Card), đội còn lại nghiễm nhiên được tự động đẩy vào nhánh trong.

## 3. Quản lý Bốc Thăm (Draw Mechanics)

### 3.1 Giao diện Bốc thăm
Tại màn hình quản lý sơ đồ (khi giải đấu chưa bắt đầu), `graphview` sẽ hiển thị các node động và đường nối khi bốc thăm:
- Hỗ trợ nút **"Bốc thăm toàn bộ" (Auto Draw)** để hệ thống random các đội vào các Slot trống của vòng 1. `graphview` sẽ cập nhật UI theo thời gian thực.
- Hỗ trợ chế độ **"Bốc từng đội" (Manual/Step-by-step Draw)**: 
  - Ứng dụng hiển thị danh sách các đội chưa có vị trí (chỉ các đội có thật, không có "Bye"). `graphview` sẽ chỉ render các node có dữ liệu đội hợp lệ.
  - Mỗi lần nhấn nút, ứng dụng sẽ chọn ngẫu nhiên 1 đội và lấp vào 1 vị trí trống trong cây (kèm hiệu ứng UI lật thẻ sinh động). `graphview` sẽ cập nhật cấu trúc đồ thị và node tương ứng với hiệu ứng animation.

### 3.2 Xóa Đội & Hủy Bốc Thăm (Clear Draw)
- Chỉ Admin có quyền nhấn nút **Làm lại sơ đồ (Clear Draw)**. 
- Tính năng này sẽ xóa toàn bộ danh sách liên kết Match hiện tại, trả các đội về danh sách "Chưa bốc thăm". `graphview` sẽ cập nhật lại cấu trúc đồ thị về trạng thái ban đầu (chỉ hiển thị các node đội chưa bốc thăm).

### 3.3 Khóa Chức năng (Tournament Lock)
*(Tuân thủ bảo mật và tính toàn vẹn dữ liệu)*
- Ngay khi trận đấu đầu tiên trong Bracket bắt đầu (có thay đổi điểm số hoặc chuyển trạng thái `InProgress`), tính năng "Hủy bốc thăm", "Xóa đội", "Thêm đội" phải bị **KHÓA HOÀN TOÀN**.
- Không cho phép thay đổi cấu trúc cây thi đấu giữa chừng để tránh lỗi dữ liệu.
