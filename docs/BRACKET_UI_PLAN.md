# 🏆 Kế hoạch triển khai giao diện Cây Sơ Đồ Thi Đấu (Bracket UI)

## 1. Mục tiêu
Xây dựng giao diện hiển thị sơ đồ thi đấu (Tournament Bracket) trực quan cho giải đấu. Giao diện cần đáp ứng các yêu cầu sau:
- **Hiển thị theo dạng cây phân nhánh**: Hiển thị rõ ràng các cặp đấu từng vòng, đường nối giữa các trận đấu để xác định đội đi tiếp.
- **Thông tin trận đấu**: Hiển thị tên hai đội, tỉ số hiện tại của từng đội.
- **Trạng thái trận đấu**: Thể hiện rõ trận đấu có đang diễn ra (Live), chưa diễn ra (Scheduled), hoặc đã kết thúc (Completed).
- **Tương tác**: Cho phép người dùng (Admin, Trọng tài, Viewer) nhấn vào một cặp đấu để xem chi tiết trận đấu đó.

## 2. Công nghệ và Thư viện sử dụng
- **graphview**: Thư viện Flutter mạnh mẽ để vẽ cấu trúc đồ thị (Directed Acyclic Graph) và các bố cục dạng cây (Tree Layouts) chuyên nghiệp, tối ưu cho việc biểu diễn sơ đồ thi đấu phân nhánh phức tạp như Double Elimination.
- **InteractiveViewer**: Hỗ trợ zoom, pan cho phép xem toàn bộ bản đồ giải đấu lớn.
- **Riverpod**: Quản lý State và lắng nghe `snapshots` từ Firestore collection `tournaments/{id}/matches` để cập nhật giao diện realtime mỗi khi có thay đổi tỉ số hoặc trạng thái trận đấu.

## 3. Cấu trúc Giao diện (UI Structure)

### 3.1 Màn hình chính (Bracket Screen)
- Sử dụng **InteractiveViewer** bao bọc bên ngoài sơ đồ. Điều này cho phép người dùng zoom in, zoom out và pan (kéo thả) để xem toàn cảnh đồ thị cây, cực kỳ hữu ích với các giải đấu quy mô 16, 32 đội.
- **GraphView Widget**:
  - Dùng thuật toán `BuchheimWalkerConfiguration` hoặc các cấu hình `TreeLayout` phù hợp của `graphview` để tối ưu khoảng cách các nodes và bố cục nhánh Thắng/Thua.
  - Sắp xếp các node theo chiều từ trái sang phải (Trận sơ loại bên trái, chung kết bên phải).

### 3.2 Component hiển thị Trận Đấu (Match Node Card)
Mỗi node trên sơ đồ là một widget tùy chỉnh (VD: `MatchNodeCard`) đại diện cho một đối tượng `Match`, được `graphview` render.
Giao diện của Node bao gồm:
- **Header**: Tên vòng đấu và số thứ tự trận (VD: Vòng 1 - Trận 1).
- **Body**: 
  - Khối Đội 1: Tên đội 1 + Tỉ số (Bôi đậm nếu thắng).
  - Khối Đội 2: Tên đội 2 + Tỉ số (Bôi đậm nếu thắng).
- **Trạng thái (Indicator)**:
  - 🟢 **Live (Đang thi đấu)**: Dùng icon màu xanh lá, có thể thêm hiệu ứng nhấp nháy, kèm nhãn "LIVE" góc thẻ.
  - ⚪ **Scheduled (Sắp diễn ra)**: Thẻ có màu xám nhẹ, nhạt hơn, hiển thị giờ thi đấu dự kiến.
  - ⚫ **Completed (Đã xong)**: Bôi đậm đội chiến thắng, làm mờ thông tin đội thua để nổi bật kết quả.

### 3.3 Tương tác và Luồng hoạt động
- **On Tap (Nhấn vào card trận đấu)**: 
  - Trigger mở lên một `showModalBottomSheet` hoặc `Dialog` để hiển thị **Match Detail**.
  - **Match Detail View**: Hiển thị chi tiết hơn (Tên giải, vòng đấu, điểm chi tiết từng set đấu, thời gian, tên trọng tài...).
  - Dựa trên role (Role-based access):
    - **Admin/Trọng tài**: Giao diện chi tiết sẽ hiện thêm các nút tác vụ như "Cập nhật tỉ số", "Sửa kết quả", "Kết thúc trận".
    - **Viewer**: Giao diện chỉ ở chế độ Read-only (chỉ xem thông tin và điểm số hiện tại).

## 4. Cấu trúc dữ liệu liên quan (Tham chiếu từ Database)
Giao diện sẽ đọc dữ liệu trực tiếp từ model `Match` (định nghĩa trong `DATABASE_SCHEMA.md`).
`BracketGraphService` (được tạo ở `REFACTOR_PLAN.md`) sẽ chuyển đổi các `MatchModel` thành cấu trúc `Node` và `Edge` của `graphview`:
- Các field `status`: Quyết định màu sắc/trạng thái hiển thị (`live`, `scheduled`, `completed`) cho cả Node và Edge.
- `score1`, `score2`: Hiển thị tỉ số trong `MatchNodeCard`.
- `team1Name`, `team2Name`: Tên đối thủ trực tiếp trong `MatchNodeCard`.
- `nextMatchId` & `bracketPosition`: Sử dụng để xây dựng các cạnh (Edges) cho đồ thị cây (Node hiện tại sẽ tạo một Edge nối sang Node `nextMatchId`).
- `bracketSide` (winners/losers/grand_final): Dùng để xác định cách bố cục các nhánh Double Elimination và tô màu đường nối phù hợp.

## 5. Các bước thực hiện chi tiết (ImpleBracketGraphService)**:
   - Viết `BracketGraphService` để parse danh sách `MatchModel` thành cấu trúc `Graph` (bao gồm các `Node` và `Edge`) của `graphview`.
   - Ánh xạ tự động: Đội thắng ở `Match A` có `nextMatchId = Match B` sẽ tạo 1 Edge từ Node A -> Node B trong `graphview`.
   - Xử lý đặc biệt cho Double Elimination để tạo và liên kết Nodes/Edges cho nhánh Thắng và nhánh Thua, cũng như Chung kết Tổng.

2. **Thiết kế Component UI Match Node (`MatchNodeCard`)**:
   - Xây dựng widget độc lập `MatchNodeCard` sẽ được sử dụng làm `builder` cho các `Node` trong `graphview`.
   - Truyền biến `Match` vào và bind thông tin lên UI. Xử lý màu sắc, kiểu dáng theo trạng thái `status` của trận đấu và loại nhánh (`bracketSide`).

3. **Thiết kế UI Match Detail BottomSheet**:
   - Xây dựng view chi tiết giải đấu, show khi user tap vào card.

4. **Tích hợp Firestore Real-time Data với `graphview`**:
   - Ở tầng View, sử dụng Provider theo dõi Stream các trận đấu từ Firebase.
   - Mỗi khi stream có thay đổi, `BracketGraphService` sẽ được gọi để tái tạo lại cấu trúc `Graph` và `graphview` Widget sẽ tự động cập nhật lại sơ đồ theo thời gian thực.

5. **Tối ưu UX/UI (Animation & Styling cho `graphview`)**:
   - Tùy chỉnh `EdgeRenderer` của `graphview` để vẽ các đường nối hình chữ C vuông (Cubic/Orthogonal Lines) và tô màu theo trạng thái trận đấu (đường đi của đội thắng).
   - Khi load lên lần đầu, tự động cuộn `InteractiveViewer` tập trung vào nhánh đấu đang có trạng thái `Live` hoặc vòng đấu hiện tại.
   - Thêm các hiệu ứng animation nhẹ nhàng khi cập nhật trạng thái hoặc bốc thăm đội mới, tận dụng API của `graphview`.   - Thêm style cho các line (đường nối) của graph.
   - Khi load lên lần đầu, tự động cuộn InteractiveViewer tập trung vào nhánh đấu đang có trạng thái `Live` hoặc vòng đấu hiện tại.
