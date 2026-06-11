# 🏆 APP QUẢN LÝ GIẢI ĐẤU — PROJECT OVERVIEW (PLATFORM EDITION)

## 1. Tầm Nhìn Dự Án (Vision)

Ứng dụng **Quản lý Giải đấu** đang trong quá trình chuyển mình mạnh mẽ từ một công cụ bốc thăm đơn giản (dựa trên Firebase và Token vô danh) thành một **Nền tảng Thể thao Chuyên nghiệp (Sports Platform)**, lấy cảm hứng từ mô hình thành công của `baseline.vn`.

Dự án hướng tới việc xây dựng một hệ sinh thái toàn diện trên di động dành cho cộng đồng chơi thể thao phong trào và bán chuyên (Cầu lông, Pickleball, Tennis), nơi người chơi không chỉ tham gia giải đấu mà còn xây dựng hồ sơ thể thao cá nhân, tham gia câu lạc bộ, và đua top trên bảng xếp hạng ELO.

### 🌟 Điểm Nổi Bật Của Nền Tảng Mới
- 🔐 **Hệ thống Tài khoản Chuẩn mực:** Đăng nhập bằng số điện thoại/email, quản lý hồ sơ VĐV (Profile).
- 📈 **Hệ thống Điểm ELO:** Đánh giá trình độ VĐV dựa trên kết quả thi đấu thực tế, giúp phân hạng giải đấu công bằng.
- 🤝 **Cộng đồng (Communities/Clubs):** Không gian cho các câu lạc bộ hoạt động, tạo giải đấu nội bộ, giao lưu và thách đấu (Cáp kèo).
- 💳 **Thanh toán & Phí nền tảng:** Quản lý lệ phí tham gia và tự động trích xuất phí nền tảng chuyên nghiệp.
- ☁️ **Kiến trúc Backend Vững chắc:** Chuyển đổi hoàn toàn sang Custom Backend API (NestJS + PostgreSQL) để đảm bảo tính toàn vẹn dữ liệu, thay thế cho Firebase cũ.

---

## 2. Di Sản Cốt Lõi: Bộ Khung Không Thể Thay Thế (The Core Engine)

Mặc dù toàn bộ hạ tầng dữ liệu và luồng xác thực được đập đi xây lại, nhưng **giá trị cốt lõi của ứng dụng — bộ não tổ chức giải đấu — sẽ được giữ nguyên và nâng cấp**. Đây là bộ khung đã được xây dựng rất vững chắc và là "trái tim" của ứng dụng:

1.  **Hệ thống Tạo Giải Đấu (Tournament Creation Flow):** 
    - Luồng Wizard thiết lập giải đấu đa dạng, chi tiết từ thể thức (Đơn, Đôi, Đôi nam nữ) đến cấu hình luật chơi (Số set, điểm chạm, cách biệt 2 điểm).
    - Cấu trúc "Giải đấu mẹ - Giải đấu con (Parent - Divisions)" cho phép tổ chức sự kiện quy mô lớn với nhiều nội dung thi đấu.
2.  **Thuật Toán Bốc Thăm & Xếp Lịch (Draw & Scheduling Engine):**
    - Logic bốc thăm tự động dựa trên Hạt giống (Seed) và trình độ ELO.
    - Khả năng xử lý các trường hợp BYE (miễn đấu) hoàn hảo.
3.  **Giao Diện Sơ Đồ Thi Đấu (Bracket UI):**
    - Khung giao diện vẽ cây thư mục (Bracket tree) tương tác trực quan cho các thể thức Loại trực tiếp (Single/Double Elimination) và Vòng tròn (Round Robin).
    - Đây là phần phức tạp nhất ở Frontend và sẽ được giữ lại nguyên bản, chỉ thay đổi nguồn cấp dữ liệu từ Firebase sang JSON API.

---

## 3. Chân Dung Người Dùng (Target Audience)

| Vai trò | Phân hệ (Module) | Mô tả & Trải nghiệm |
|---|---|---|
| **Ban Tổ Chức (Organizer)** | `organizer/` | Tạo giải, quản lý đăng ký, thu phí, chốt danh sách, bấm nút bốc thăm, điều hành trận đấu, cập nhật điểm số. |
| **Trọng Tài (Referee)** | `referee/` | Quét mã QR trận đấu được phân công, nhập điểm Live, xác nhận kết quả (App chuyên dụng cho trọng tài sân). |
| **Vận Động Viên (Player)** | `tournaments/` & `profile/` | Tìm giải, đăng ký cá nhân/đội, xem lịch đấu của mình, theo dõi điểm ELO cá nhân, tham gia Câu lạc bộ. |
| **Chủ Câu Lạc Bộ (Club Admin)**| `communities/` | Quản lý thành viên CLB, tạo giải đấu nội bộ miễn phí, quản lý quỹ và bảng xếp hạng nội bộ. |

---

## 4. Kiến Trúc Công Nghệ Mới (Tech Stack Transition)

| Thành phần | Phiên bản cũ (Legacy) | Phiên bản Nền tảng (Hiện tại & Tương lai) |
|---|---|---|
| **Frontend Framework** | Flutter (Dart) | **Flutter (Dart)** - Áp dụng Clean Architecture chặt chẽ. |
| **Backend & Database** | Firebase (Firestore NoSQL) | **NestJS API + PostgreSQL (Relational DB)**. |
| **Xác thực (Auth)** | Firebase Anonymous Token | **JWT Authentication** (Access/Refresh Tokens), tích hợp OAuth2. |
| **State Management** | Riverpod + Firestore Streams | **Riverpod + REST API Polling / WebSockets**. |
| **Lưu trữ ảnh** | Firebase Storage | **Cloudinary** (Upload qua Backend). |
| **Bracket Engine** | Custom Graphview | **Giữ nguyên (Cập nhật Parser để đọc JSON từ Backend)**. |

---

## 5. Bản Đồ Tính Năng Tổng Thể (Feature Map)

```text
📦 FLUTTER SPORTS PLATFORM
 ┣ 📂 [1] Xác thực & Hồ sơ (Auth & Profile)
 ┃ ┣ 📜 Đăng nhập / Đăng ký (Phone/Email)
 ┃ ┣ 📜 Hồ sơ VĐV (Chỉ số ELO, Lịch sử đấu, Danh hiệu)
 ┃ ┗ 📜 Quản lý Đội/Nhóm cố định
 ┣ 📂 [2] Khám Phá & Đăng Ký (Discovery)
 ┃ ┣ 📜 Bảng tin Giải đấu sắp diễn ra (Lọc theo Tỉnh, Bộ môn)
 ┃ ┣ 📜 Thanh toán Lệ phí đăng ký (Integration cổng thanh toán)
 ┃ ┗ 📜 Tìm kiếm đồng đội đánh đôi
 ┣ 📂 [3] Quản Trị Giải Đấu (Tournament Operation) - CORE ENGINE
 ┃ ┣ 📜 Khởi tạo giải đấu (Parent - Divisions)
 ┃ ┣ 📜 Quản lý danh sách VĐV, Chốt sổ & Bốc thăm (Bracket)
 ┃ ┣ 📜 Nhập điểm trực tiếp (Live Scoring) & Livestream links
 ┃ ┗ 📜 Xử lý walkover, bỏ cuộc, phạt thẻ
 ┗ 📂 [4] Cộng Đồng & Bảng Xếp Hạng (Communities & Rankings)
   ┣ 📜 Tìm & Gia nhập Câu Lạc Bộ
   ┣ 📜 Bảng xếp hạng ELO chung (Global Ranking)
   ┗ 📜 Bảng xếp hạng ELO nội bộ CLB
```

---

## 6. Lời Kết

Hành trình nâng cấp này không nhằm đập bỏ những gì đã làm tốt, mà là **đặt một bộ máy tuyệt vời (bốc thăm, quản lý trận đấu) lên một bệ phóng mạnh mẽ và mở rộng hơn (Backend xịn, có user, có cộng đồng)**. 

Ứng dụng Flutter sẽ đóng vai trò là "mặt tiền" linh hoạt, tốc độ cao, đồng bộ dữ liệu thời gian thực với hệ thống Web, mang lại trải nghiệm chuyên nghiệp nhất cho nền thể thao phong trào tại Việt Nam.