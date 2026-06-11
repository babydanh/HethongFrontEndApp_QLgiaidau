# 🚀 Kế Hoạch Tái Cấu Trúc Toàn Diện Ứng Dụng Di Động (Flutter)
## (Chuyển đổi từ Firebase Backend-as-a-Service sang Custom Backend API NestJS/PostgreSQL)

> **Mục tiêu:** Đồng bộ hóa hoàn toàn ứng dụng di động (`app_quanly_giaidau`) với hệ thống Web (`frontend-web_qlgiaidau`) và Backend API (`backend-api_qlgiaidau`). Tham chiếu logic và UI/UX từ các nền tảng tổ chức giải đấu chuyên nghiệp (như `baseline.vn`). Gỡ bỏ sự phụ thuộc vào Firebase (ngoại trừ Push Notifications/Crashlytics nếu cần).

---

## 🎯 1. Tầm Nhìn & Nguyên Tắc Tái Cấu Trúc (Dựa trên `SKILLS.md`)

*   **Đồng Bộ Cấu Trúc Dữ Liệu:** Đảm bảo Flutter App hiểu và xử lý đúng cấu trúc `Parent Tournament` (Giải đấu mẹ) và `Division/Match Type` (Giải đấu con) mới được cập nhật trên Web.
*   **Clean Architecture:** Tuân thủ phân lớp thư mục `lib/` (Presentation -> Domain -> Data). Không gọi API trực tiếp trong UI. Mọi request phải đi qua lớp Repository.
*   **State Management:** Chuyển đổi các luồng stream của Firestore sang cơ chế fetch REST API kết hợp Caching. Quản lý trạng thái bằng Provider/Riverpod thống nhất.
*   **Xử lý Lỗi (Error Handling):** Mapping toàn bộ mã lỗi từ Backend NestJS thành các thông báo thân thiện với người dùng trên App. Xử lý Token Expiration (Refresh Token) mượt mà.
*   **Trải nghiệm người dùng (UX):** Áp dụng thiết kế thẻ (Card), Huy hiệu trạng thái (Badge), và điều hướng phân cấp chuẩn mực như thiết kế của Web Tailwind và Baseline.vn.

---

## 🗺️ 2. Lộ Trình Tái Cấu Trúc (Phased Approach)

### Phase 1: Chuẩn bị Môi trường & Networking Layer (Tuần 1)
*   **Mục tiêu:** Xây dựng lõi kết nối API vững chắc thay thế cho Firebase SDK.
*   **Task List:**
    *   [ ] Thiết lập `Dio` hoặc `http` client với Interceptors (để gắn JWT Bearer Token tự động).
    *   [ ] Viết `TokenManager` để xử lý lưu trữ bảo mật (Secure Storage) JWT Access Token và Refresh Token.
    *   [ ] Xây dựng lớp `ApiResponse` generic để parse dữ liệu chuẩn JSON từ backend `{ "statusCode": 200, "message": "...", "data": ... }`.
    *   [ ] Dọn dẹp Firebase SDK (gỡ bỏ `cloud_firestore`, `firebase_auth`, `firebase_database`). Chỉ giữ lại `firebase_messaging` nếu dùng cho thông báo.

### Phase 2: Tái cấu trúc Xác thực & Hồ sơ (Auth & User Profile) (Tuần 1-2)
*   **Mục tiêu:** Chuyển từ Firebase Auth sang JWT Auth của Backend.
*   **Task List:**
    *   [ ] Cập nhật UI/Logic màn hình Đăng nhập/Đăng ký để gọi API `/auth/login` và `/auth/register`.
    *   [ ] Tích hợp tính năng Đăng nhập bằng Google/Apple thông qua OAuth2 Backend (trả về JWT thay vì dùng token Firebase).
    *   [ ] Gọi API `/users/profile` để tải thông tin người dùng, lưu vào State Management (thay thế luồng nghe trực tiếp từ Firestore `users` collection).
    *   [ ] Cập nhật tính năng đổi Avatar (Upload file thông qua API Backend thay vì Firebase Storage).

### Phase 3: Tái cấu trúc Luồng Tổ Chức & Quản Lý Giải Đấu (Tuần 2-3)
*   **Mục tiêu:** Áp dụng mô hình **Mẹ-Con (Parent-Divisions)** như đã làm trên Web.
*   **Task List:**
    *   [ ] **Dashboard (Giải của tôi):** Gọi API `GET /tournaments/parent/my`. Hiển thị dưới dạng "Nhóm giải đấu", kèm theo danh sách các Hình thức thi đấu (Divisions) như Đơn Nam, Đôi Nữ.
    *   [ ] **Luồng Tạo Giải Đấu (Wizard):** Thực hiện 2 bước API y hệt Web:
        1. Gọi `POST /tournaments/parent` tạo Giải đấu mẹ.
        2. Lấy `parentId` gọi `POST /tournaments` tạo Division đầu tiên.
    *   [ ] **Quản lý Chi tiết:** Sửa đổi các API endpoints khi cập nhật thông tin giải đấu. Tách biệt giữa Update Parent (Banner, Logo chung) và Update Division (Luật chơi, số set).
    *   [ ] Tái thiết kế màn hình Sơ đồ thi đấu (Bracket) để render dựa trên JSON từ API thay vì cấu trúc document đệ quy của Firestore.

### Phase 4: Tính năng Đăng ký, Cáp Kèo & Cộng đồng (Tuần 3-4)
*   **Mục tiêu:** Khớp với trải nghiệm tìm kiếm và tham gia giải đấu của VĐV trên nền tảng baseline.vn.
*   **Task List:**
    *   [ ] Luồng duyệt Giải đấu công khai (Khám phá Giải): Gọi API phân trang, tìm kiếm có bộ lọc (Tỉnh thành, bộ môn, trình độ).
    *   [ ] Giao diện "Chi tiết giải đấu" dành cho VĐV: Hiển thị Overview, Điều lệ, Danh sách VĐV, và Sơ đồ Bracket.
    *   [ ] Luồng Đăng ký (Checkout): Xử lý logic đăng ký Đơn/Đội. Map với API `/tournaments/:id/register`.
    *   [ ] **Cộng đồng (Clubs):** Gọi API lấy danh sách Câu lạc bộ, Bảng xếp hạng ELO nội bộ thay vì query Firestore.

### Phase 5: Thanh Toán & Nâng Cao (Tuần 4)
*   **Mục tiêu:** Tích hợp quy trình thanh toán lệ phí (Payment) và bảo trì dữ liệu.
*   **Task List:**
    *   [ ] Triển khai cổng thanh toán (nếu có, qua webview lấy link từ backend) để nộp lệ phí sàn (Platform Fee) hoặc lệ phí giải đấu (Entry Fee).
    *   [ ] Luồng "Chốt danh sách" và tự động sinh Sơ đồ đấu (gọi API trigger sinh Bracket thay vì App tự sinh logic offline rủi ro).
    *   [ ] Viết Unit Test cho tầng Repositories mới (gọi API mock).

---

## ⚙️ 3. Chi tiết Chuyển đổi Kỹ thuật (Technical Mapping)

| Tính năng cũ (Firebase) | Trạng thái mới (NestJS/Postgres API) | Hành động trên Flutter |
| :--- | :--- | :--- |
| `FirebaseAuth.instance.currentUser` | JWT Token + `/auth/me` | Dùng `SecureStorage` lưu JWT, viết interceptor đính kèm `Bearer`. |
| Nghe Realtime `onSnapshot()` | Polling API hoặc WebSocket (Socket.io) | Chuyển sang `FutureProvider` (gọi API 1 lần) kết hợp "Pull-to-refresh". Tích hợp WebSocket cho điểm số Live. |
| Firebase Storage (Ảnh/Logo) | Cloudinary (thông qua Backend) | Upload qua API backend (`multipart/form-data`), nhận URL trả về. |
| Phân trang Firestore (cursor) | Offset/Limit (Paginated API) | Xử lý ListView tự động load thêm page (`page=1, limit=10`). |
| Offline Cache | Tự quản lý (SQLite / Hive / SharedPreferences) | (Tùy chọn) Lưu JSON response cục bộ cho các màn hình tĩnh (như luật lệ). |

---

## ⚠️ 4. Rủi Ro Cần Lưu Ý & Cách Giảm Thiểu

1.  **Mất tính năng Real-time:** 
    *   *Rủi ro:* Trọng tài nhập điểm xong, khán giả không thấy ngay như Firestore.
    *   *Giảm thiểu:* Implement WebSockets cho màn hình `MatchDetail` (Chi tiết trận đấu đang diễn ra) để nhận broadcast sự kiện "Cập nhật điểm".
2.  **Độ trễ API (Latency):**
    *   *Rủi ro:* App có cảm giác chậm hơn so với khi dùng Firebase có local cache mặc định.
    *   *Giảm thiểu:* Dùng Skeleton Loading thay vì Spinner (Loading Spinner). Áp dụng Optimistic UI Updates (Cập nhật giao diện ngay lập tức giả định API thành công, nếu lỗi thì revert).
3.  **Thay đổi Cấu trúc Bracket:**
    *   *Rủi ro:* JSON trả về từ DB quan hệ khác với Object Tree của NoSQL.
    *   *Giảm thiểu:* Viết lớp DTO (Data Transfer Object) để ánh xạ JSON từ API thành mô hình Class (Models) quen thuộc của giao diện Bracket hiện tại ở Flutter.

> **Note:** Kế hoạch này dùng để làm kim chỉ nam. Quá trình code sẽ không bắt đầu cho đến khi có lệnh xác nhận từng Phase từ người dùng. Tuyệt đối bám sát `SKILLS.md` trong quá trình thực thi mã nguồn.