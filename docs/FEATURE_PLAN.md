# Kế hoạch Phát triển Tính năng (Feature Plan)

Tài liệu này ghi nhận các yêu cầu nghiệp vụ, phân tích và hướng giải quyết cho các tính năng sắp tới của ứng dụng Quản Lý Giải Đấu.

## 1. Nâng cấp Trang Tạo Giải Đấu (Tournament Creation)

### 1.1. Logic Chọn Môn Thể Thao & Hình Thức Thi Đấu
*   **Yêu cầu:** Tùy biến hình thức thi đấu dựa trên môn thể thao được chọn.
    *   **Cầu lông / Tennis:** Chỉ hiển thị Đánh Đơn / Đánh Đôi.
    *   **Bóng đá:** Hiển thị sân 5 (5v5), sân 7 (7v7), sân 11 (11v11).
*   **Phân tích & Thảo luận (Giới tính / Hạng mục):**
    *   *Vấn đề:* Đánh đơn/đôi nên chia theo giới tính (Đơn nam, Đơn nữ, Đôi nam, Đôi nữ, Đôi nam nữ).
    *   *Hướng giải quyết:* Thêm trường `Hạng mục / Nội dung` (Category). Sau khi user chọn "Đánh đôi", sẽ có tùy chọn phụ để chọn giới tính.
*   **Phân tích & Thảo luận (Bóng đá):**
    *   *Vấn đề:* Bóng đá 5v5 là số người trên sân, nhưng một đội có thể có 10-15 người (cả dự bị).
    *   *Hướng giải quyết:* Tách biệt `Đội hình thi đấu` (5v5) và `Danh sách đăng ký tối đa` (VD: 15 người). Khi quản lý Team, sẽ cho phép nhập danh sách cầu thủ lên đến con số tối đa này.

### 1.2. Giải Thích Thể Thức Thi Đấu (Info Modal)
*   **Yêu cầu:** Thêm nút `(i)` cạnh các thể thức (Single Elimination, Double Elimination, Round Robin). Bấm vào sẽ mở ra trang/modal giải thích kèm hình ảnh/animation minh họa.
*   **Hướng giải quyết:**
    *   Thêm icon `(i)` vào UI.
    *   Tạo một `BottomSheet` hoặc một màn hình riêng biệt (Dialog).
    *   Trong Dialog, dùng các file ảnh GIF hoặc sử dụng code vẽ Canvas (CustomPaint) để chạy một đoạn animation nhỏ minh họa cách nhánh đấu hoạt động.

### 1.3. Linh Hoạt Số Lượng Đội Tham Gia (Lẻ / Dư đội)
*   **Yêu cầu:** Bỏ việc gán cứng số lượng đội (4, 8, 16, 32...). Cho phép nhập số lượng linh hoạt (VD: 5, 7, 13 đội) để sát với thực tế.
*   **Phân tích & Thảo luận (Thuật toán BYE):**
    *   Trong loại trực tiếp (Elimination), nếu số đội không phải lũy thừa của 2 (VD: 13 đội, không đủ 16), ta áp dụng luật **BYE**.
    *   Sẽ có `16 - 13 = 3` suất BYE. Các đội mạnh (hạt giống - seeded) sẽ được bốc thăm vào vị trí có BYE, tức là được đặc cách không phải đá vòng 1, đi thẳng vào vòng 2.
    *   Trong đá vòng tròn (Round Robin), nếu số đội lẻ (VD: 5 đội), mỗi vòng sẽ có 1 đội được nghỉ (bốc trúng thăm BYE).
*   **Hướng giải quyết & Chốt phương án:** 
    *   Chuyển Dropdown chọn số lượng (16, 32...) thành TextField cho phép nhập tự do. 
    *   **Giới hạn số đội:** Để đảm bảo giao diện (UI) không bị vỡ và BTC kiểm soát được thời gian, ta sẽ **cho phép nhập tùy ý nhưng giới hạn tối đa là 32 đội**. (Đây là con số thực tế, đủ lớn cho hầu hết các giải đấu phong trào). Nếu nhập trống, ngầm hiểu là không giới hạn nhưng tối đa vẫn là 32.
    *   **Giới hạn số cầu thủ:** Đối với Bóng đá, vẫn giữ ô nhập "Số lượng cầu thủ đăng ký tối đa", gợi ý mặc định là 15 (sân 5) hoặc 20 (sân 7). Người dùng có thể để trống nếu không muốn giới hạn (tự do thay người).

---

## 2. Nâng cấp Trang Quản Lý Đội (Team Management)

### 2.1. Import danh sách từ Google Form / Excel
*   **Yêu cầu:** Đọc file Excel xuất ra từ Google Forms đăng ký. Lọc và tự động nhập danh sách vào hệ thống.
*   **Các trường thông tin cần thiết:**
    *   Tên, Số điện thoại, Email, Giới tính.
    *   *Đề xuất bổ sung thêm:* **Ngày sinh / Tuổi** (để phân loại nhóm tuổi), **Tên Đơn vị / CLB** (để tránh xếp các đội cùng CLB gặp nhau sớm), và **Hạt giống (Seed)** (nếu có, để chia nhánh bốc thăm).
*   **Hướng giải quyết:**
    *   Sử dụng thư viện `excel` để parse dữ liệu từ file `.xlsx`.
    *   Xây dựng màn hình **Preview (Xem trước)**: Sau khi đọc file, hiện ra danh sách đã quét. Admin có thể tick chọn bỏ đi những đơn rác/không hợp lệ trước khi bấm "Xác nhận Import".
    *   Dùng Batch Write đẩy hàng loạt lên Firestore.

### 2.2. Chỉnh Sửa Thông Tin Đội (Edit Team)
*   **Yêu cầu:** Cho phép chỉnh sửa thông tin của một đội đã tạo (sai tên, đổi người).
*   **Hướng giải quyết:**
    *   Thêm nút `Edit` (Hình cây bút) trong danh sách đội.
    *   Sử dụng lại form Add Team nhưng truyền data hiện tại vào để sửa.
    *   (Nâng cao) Giao diện quản lý danh sách thành viên (Roster) của từng đội để thêm/xóa cầu thủ.

---

## 3. Quản Lý Quyền Truy Cập (Token & QR Code)

### 3.1. Đổi / Làm Mới Mã Token (Role Management)
*   **Yêu cầu:** Quản lý 3 mã Token (Admin, Trọng tài, Khán giả). Cho phép Admin đổi/reset mã. Khi đổi, những người đang xài mã cũ sẽ bị out ra ngoài.
*   **Hướng giải quyết:**
    *   Thêm nút "Làm mới mã" (Refresh) bên cạnh mỗi Token. Khi bấm, update lại field Token mới trên Firestore.
    *   Ở phía App người dùng: Sử dụng Stream lắng nghe document giải đấu (hoặc collection `tokens`). Nếu token đang lưu dưới local không còn khớp với token trên server, lập tức clear session và đẩy user về màn hình "Nhập mã giải đấu".

### 3.2. Theo dõi số lượng người đang kết nối (Active Users)
*   **Yêu cầu:** Xem có bao nhiêu người đang online/vào giải bằng các mã này.
*   **Hướng giải quyết:**
    *   Sử dụng tính năng **Firebase Realtime Database Presence** (vì Firestore không tối ưu cho việc tracking online/offline).
    *   Giao diện Admin sẽ có các badge hiển thị số lượng realtime. VD: `Trọng tài: 🟢 4` | `Khán giả: 🟢 120`.

### 3.3. Tích hợp Mã QR cho Token
*   **Yêu cầu:** Tạo mã QR cho mỗi Token, người dùng chỉ cần quét là vào thẳng giải, không cần nhập mã thủ công.
*   **Hướng giải quyết:**
    *   Sử dụng thư viện `qr_flutter` tạo mã QR. Nội dung mã là dạng Deeplink/URL rút gọn. VD: `app://tournament/12345?token=VWR-XXXX`.
    *   Cho phép Admin bấm vào mã QR để phóng to, và có nút "Chia sẻ" (lưu thành file ảnh gửi qua Zalo, Facebook cho VĐV/Khán giả).

---
*Lưu ý: Tài liệu này là cơ sở để thống nhất requirement trước khi tiến hành code thực tế.*
