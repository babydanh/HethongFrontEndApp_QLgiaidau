# 📅 PLAN — Kế hoạch phát triển chi tiết

---

## Timeline tổng quan

```
Phase 1 ──────── Phase 2 ──────── Phase 3 ──────── Phase 4
Foundation       Tournament &     Bracket &        Real-time &
& Auth           Teams            Matches          Polish
(Tuần 1)         (Tuần 2)         (Tuần 3-4)       (Tuần 5)
```

---

## 🔵 Phase 1 — Foundation & Auth (Tuần 1)

### Mục tiêu
Xây dựng nền tảng: cấu hình Firebase, thiết lập kiến trúc dự án, và hoàn thiện hệ thống xác thực bằng Token.

### Tasks

#### 1.1 Project Setup
- [ ] Cấu hình Firebase project (Firestore, Auth)
- [ ] Chạy `flutterfire configure` để sinh `firebase_options.dart`
- [ ] Thêm tất cả dependencies vào `pubspec.yaml`
- [ ] Tạo cấu trúc thư mục `lib/` theo Clean Architecture
- [ ] Setup `analysis_options.yaml` (lint rules)

#### 1.2 Design System
- [ ] Tạo `app_theme.dart` — Color palette, Typography, Spacing
- [ ] Tạo bộ custom widgets cơ bản:
  - `AppButton` — Primary, Secondary, Danger
  - `AppTextField` — Input với validation
  - `AppCard` — Card bo tròn với shadow
  - `LoadingOverlay` — Loading toàn màn hình
  - `EmptyState` — Placeholder khi không có data

#### 1.3 Data Models
- [ ] `TournamentModel` — fromMap / toMap / copyWith
- [ ] `TeamModel` — fromMap / toMap / copyWith
- [ ] `MatchModel` — fromMap / toMap / copyWith
- [ ] `StandingModel` — fromMap / toMap / copyWith
- [ ] `TokenModel` — fromMap / toMap / copyWith

#### 1.4 Token & Auth System
- [ ] `TokenGenerator` — Sinh token ngẫu nhiên (ADM/REF/VWR-XXXX-XXXX)
- [ ] `TokenRepository` — CRUD token trên Firestore
- [ ] `AuthNotifier` (Riverpod) — Quản lý state xác thực
- [ ] Firebase Anonymous Auth integration
- [ ] Lưu token vào SharedPreferences (auto-login)

#### 1.5 Navigation
- [ ] Setup `GoRouter` với route structure
- [ ] Role-based redirect (Admin/Referee/Viewer)
- [ ] `RoleGuard` widget — Ẩn/hiện UI theo quyền

#### 1.6 Screens
- [ ] `SplashScreen` — Logo + loading
- [ ] `TokenEntryScreen` — Ô nhập token + Validate + Navigate

### Deliverable Phase 1
✅ User nhập token → App xác thực → Chuyển đến đúng giao diện theo role

---

## 🟡 Phase 2 — Tournament & Teams CRUD (Tuần 2)

### Mục tiêu
Admin có thể tạo giải đấu, quản lý đội/VĐV, và import danh sách từ file.

### Tasks

#### 2.1 Repositories
- [ ] `TournamentRepository` — CRUD + Stream
- [ ] `TeamRepository` — CRUD + Stream + Batch import

#### 2.2 Providers
- [ ] `tournamentProvider` — StreamProvider cho danh sách giải
- [ ] `teamsProvider` — StreamProvider.family cho đội theo giải

#### 2.3 Tournament Screens (Admin)
- [ ] `TournamentListScreen` — Danh sách giải đấu + Nút tạo mới
- [ ] `CreateTournamentScreen` — Form tạo giải (tên, môn, thể thức...)
- [ ] `TournamentDetailScreen` — Dashboard giải: teams, bracket, token sharing
- [ ] Hiển thị + Copy/Share 3 token keys

#### 2.4 Team Management Screens (Admin)
- [ ] `TeamListScreen` — Danh sách đội trong giải
- [ ] `AddTeamScreen` — Form thêm đội thủ công
- [ ] `ImportTeamsScreen` — Import từ CSV/Excel
  - [ ] Chọn file (file_picker)
  - [ ] Preview danh sách trước khi import
  - [ ] Batch write lên Firestore

#### 2.5 QR Code (Optional)
- [ ] Sinh QR code cho mỗi VĐV (qr_flutter)
- [ ] Màn hình quét QR check-in (mobile_scanner)

### Deliverable Phase 2
✅ Admin tạo giải → Thêm đội thủ công hoặc import file → Chia sẻ token

---

## 🟠 Phase 3 — Bracket & Matches (Tuần 3-4)

### Mục tiêu
Hệ thống bốc thăm, sinh bracket, và nhập điểm thi đấu.

### Tasks

#### 3.1 Thuật toán Bracket (Core Logic)
- [ ] `BracketGenerator` — Single Elimination
  - [ ] Seed-based positioning
  - [ ] BYE handling (số đội lẻ)
  - [ ] Link nextMatchId giữa các vòng
- [ ] `BracketGenerator` — Double Elimination
  - [ ] Winners bracket
  - [ ] Losers bracket
  - [ ] Grand Final
- [ ] `RoundRobinGenerator`
  - [ ] Circle method scheduling
  - [ ] Phân bảng tự động
  - [ ] Tính điểm xếp hạng

#### 3.2 Bốc thăm
- [ ] `AutoDrawScreen` — Bốc thăm tự động
  - [ ] Fisher-Yates shuffle
  - [ ] Animation xáo trộn
  - [ ] Hiển thị kết quả + Xác nhận
- [ ] `ManualDrawScreen` — Bốc thăm thủ công
  - [ ] UI "rút thăm" từng đội
  - [ ] Animation kịch tính (cho chiếu projector)
  - [ ] Chọn bốc theo vòng cụ thể

#### 3.3 Match Repository
- [ ] `MatchRepository`
  - [ ] Tạo matches từ bracket generator
  - [ ] Cập nhật điểm
  - [ ] Xác định winner → Cập nhật trận tiếp theo
  - [ ] Stream realtime

#### 3.4 Bracket UI
- [ ] `BracketViewScreen` — Vẽ cây bracket (graphview)
  - [ ] Single Elimination tree
  - [ ] Double Elimination (2 nhánh)
  - [ ] Zoom & Pan support
  - [ ] Highlight trận đang live
- [ ] `RoundRobinViewScreen` — Bảng xếp hạng
  - [ ] Table view theo bảng
  - [ ] Tự động cập nhật khi có kết quả

#### 3.5 Score Input
- [ ] `ScoreInputScreen` — Nhập điểm (Admin + Referee)
  - [ ] Hiển thị 2 đội + Điểm
  - [ ] Nút +1 / -1
  - [ ] Nhập theo set (Best of 3/5)
  - [ ] Nút "Bắt đầu trận" → status = live
  - [ ] Nút "Kết thúc trận" → Xác nhận winner
  - [ ] Auto-advance: Winner vào trận tiếp theo

### Deliverable Phase 3
✅ Bốc thăm → Sinh bracket → Nhập điểm → Bracket tự động cập nhật

---

## 🔴 Phase 4 — Real-time & Polish (Tuần 5)

### Mục tiêu
Hoàn thiện trải nghiệm real-time cho Viewer, xuất kết quả, và polish UI.

### Tasks

#### 4.1 Real-time Viewer
- [ ] `LiveMatchScreen` — Xem trận đấu trực tiếp
  - [ ] Firestore snapshot listeners
  - [ ] Score animation khi thay đổi
  - [ ] Auto-scroll đến trận đang live
- [ ] `ViewerBracketScreen` — Bracket realtime
  - [ ] Bracket cập nhật khi trận kết thúc
  - [ ] Highlight trận live (nhấp nháy)
  - [ ] Chế độ "Projector" (full screen, font lớn)

#### 4.2 Referee Flow
- [ ] `RefereeMatchListScreen` — DS trận được phân công
  - [ ] Chỉ hiện trận scheduled/live
  - [ ] Bấm vào → Nhập điểm
- [ ] Restrict: Referee chỉ update score fields

#### 4.3 Kết quả & PDF
- [ ] `ResultScreen` — Bảng kết quả cuối cùng
  - [ ] Xếp hạng: Vô địch, Á quân, Hạng 3
  - [ ] Thống kê từng đội
- [ ] Export PDF (pdf + printing)
  - [ ] Thông tin giải đấu
  - [ ] Danh sách đội
  - [ ] Kết quả từng trận
  - [ ] Bảng xếp hạng

#### 4.4 UI Polish
- [ ] Animation transitions giữa các màn hình (flutter_animate)
- [ ] Shimmer loading effect
- [ ] Dark mode / Light mode toggle
- [ ] Responsive layout (mobile + tablet + desktop)
- [ ] Wakelock cho chế độ projector

#### 4.5 Testing & Bug Fixes
- [ ] Unit tests cho bracket algorithms
- [ ] Unit tests cho token generator
- [ ] Widget tests cho các màn hình chính
- [ ] Edge case testing:
  - [ ] Số đội lẻ (BYE)
  - [ ] Mất mạng giữa chừng
  - [ ] 2 người nhập điểm cùng lúc
  - [ ] Token bị deactivate

### Deliverable Phase 4
✅ App hoàn chỉnh: Admin quản lý → Trọng tài nhập điểm → Viewer xem real-time → Xuất PDF

---

## 📊 Ước tính khối lượng công việc

| Phase | Số files | Estimate |
|---|---|---|
| Phase 1 — Foundation | ~20 files | 5-7 ngày |
| Phase 2 — CRUD | ~15 files | 5-7 ngày |
| Phase 3 — Bracket | ~15 files | 10-14 ngày |
| Phase 4 — Polish | ~10 files | 5-7 ngày |
| **Tổng** | **~60 files** | **25-35 ngày** |

---

## 🎯 Milestone Checkpoints

```
✅ Milestone 1 (End Phase 1):
   "Tôi nhập token → Vào được đúng giao diện"

✅ Milestone 2 (End Phase 2):
   "Tôi tạo giải, import 16 đội từ Excel thành công"

✅ Milestone 3 (End Phase 3):
   "Tôi bốc thăm, thấy bracket, nhập điểm xong bracket tự cập nhật"

✅ Milestone 4 (End Phase 4):
   "Khán giả mở app, nhập token viewer, thấy điểm cập nhật real-time"

---

## 📈 Tích hợp Thiết kế ELO Cặp đôi Lâu dài (Doubles ELO History)
- [ ] Thiết lập bảng `pair_ranks` để lưu ELO cho các cặp đôi (định danh bởi `user1Id` và `user2Id`).
- [ ] Khởi tạo ELO cặp đôi bằng trung bình cộng ELO cá nhân đánh đôi khi cặp đôi đăng ký giải đấu lần đầu.
- [ ] Tính toán, cập nhật và lưu giữ ELO cặp đôi độc lập sau mỗi trận đấu của giải đấu có tính ELO.
- [ ] Đảm bảo ELO cặp đôi được tái sử dụng nếu 2 VĐV tái hợp ở các giải đấu sau.

