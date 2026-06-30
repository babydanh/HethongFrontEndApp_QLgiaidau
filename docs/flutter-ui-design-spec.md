# Flutter UI Design Spec — Baseline Tournament App Redesign

> **Mục tiêu:** Định nghĩa thiết kế giao diện cho toàn bộ Flutter App VNDC Sport đồng bộ với chất lượng cao cấp, hiện đại và chuẩn mực như bản Web.
> **Phong cách:** Sport-tech, Đen bóng đêm tuyệt đối (#000000) kết hợp xám trung tính, điểm xuyết ánh sáng Neon (Xanh dương #2979FF, Đỏ rực #EF4444, Cam hổ phách #D97706), bo góc bo mịn màng, hiệu ứng kính mờ (Glassmorphism), và khoảng đệm thoáng đãng.
> **Nguyên tắc cốt lõi:** Tuyệt đối tuân thủ quy tắc Dark Mode đen kịt (#000000), không pha trộn ánh xanh dương làm bạc màu nền tối.

---

## 🎨 Design Tokens & Color Palettes

```dart
// Nền app đen kịt tuyệt đối (#000000) - Không pha undertone xanh
bgDark: Color(0xFF000000)       

// Màu Card / Surface nổi (Xám trung tính siêu sâu)
bgCard: Color(0xFF121212)       
bgSurface: Color(0xFF1E1E1E)    

// Tông màu thương hiệu & Nhấn Neon nổi bật trên nền đen
primary: Color(0xFF2979FF)      // Xanh dương Neon chính
primaryLight: Color(0xFF82B1FF)
primaryDark: Color(0xFF1565C0)
success: Color(0xFF10B981)      // Xanh lá tươi
warning: Color(0xFFF59E0B)      // Cam hổ phách
error: Color(0xFFEF4444)        // Đỏ Neon rực rỡ

// Tông màu chữ phân cấp rõ ràng
textPrimary: Color(0xFFFFFFFF)    // Trắng tinh cho tiêu đề chính
textSecondary: Color(0xFF94A3B8)  // Xám trung tính nhạt cho phụ đề
textMuted: Color(0xFF64748B)      // Xám tối cho chi tiết phụ

// Viền & Phân cách siêu mảnh
border: Color(0xFF2D2D2D)       

// Bo góc tiêu chuẩn Web
radiusSM = 8
radiusMD = 12
radiusLG = 16
radiusXL = 20

// Gradients cao cấp (Tránh chuyển sắc gắt)
primaryGradient: LinearGradient(
  colors: [Color(0xFF2979FF), Color(0xFF1565C0)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
darkGradient: LinearGradient(
  colors: [Color(0xFF0D0D0D), Color(0xFF181818)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
liveGlowGradient: RadialGradient(
  colors: [Color(0xFFEF4444).withOpacity(0.15), Colors.transparent],
)
```

---

## 📱 MÀN HÌNH 1: Tournament Intro (Chi tiết giải đấu)

### Sơ đồ cấu trúc Layout
```
┌──────────────────────────────────────┐
```
```
│  🔙  [🔴 12 LIVE]                     │ ← AppBar trong suốt, badge góc phải
│                                      │
│  ┌──── GRADIENT HERO BANNER ───────┐ │
│  │  [🏸 CẦU LÔNG]    [ĐANG ĐĂNG KÝ] │ │ ← Badges nhỏ gọn
│  │                                  │ │
│  │  GIẢI CẦU LÔNG VNDC              │ │ ← Tiêu đề 18px đậm, tối đa 2 dòng
│  │  MỞ RỘNG 2026                    │ │
│  │                                  │ │
│  │  📅 15/06/2026   💰 300.000 VNĐ  │ │ ← Wrap dòng thông tin linh hoạt
│  └──────────────────────────────────┘ │
│                                      │
│  ┌─── INFO GRID (2×2) ─────────────┐ │
│  │ ┌──────────┐ ┌──────────┐       │ │
│  │ │ 🔀 Thể   │ │ 🏆 Nhánh │       │ │
│  │ │   thức   │ │   đấu    │       │ │
│  │ │ Đánh đôi │ │ Loại trực│       │ │
│  │ └──────────┘ └──────────┘       │ │
│  └──────────────────────────────────┘ │
│                                      │
│  ┌─── TAB BAR (Bóng đêm) ──────────┐ │
│  │  Giới thiệu  │  Đội tham gia     │ │ ← Chỉ báo màu xanh Neon
│  └──────────────────────────────────┘ │
│                                      │
│  ┌─── CONTENT CONTAINER ───────────┐ │
│  │  [Mô tả giải đấu]                │ │
│  │  Khung viền mảnh màu tối         │ │
│  └──────────────────────────────────┘ │
│                                      │
│  ┌─── STICKY ACTION BOTTOM ────────┐ │
│  │  [🔑 Vào giải đấu]  [📺 Xem Live] │ │ ← Gradient & Outline neon
│  └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Chi tiết đặc tả UI:
1. **Gradient Hero Banner**: 
   * Chiều cao: 260px.
   * Dải màu: `LinearGradient` từ màu đen đậm `#000000` chuyển mượt qua đỏ đô/tím đen đặc trưng của Web để tạo cảm giác sâu thẳm.
   * Tên giải đấu: Font size tối đa **18px-20px** (tránh chữ quá to gây tràn trên Web/Mobile), `fontWeight: FontWeight.w900`.
   * Chi tiết ngày & Phí: Sử dụng `Wrap` thay vì `Row` để tự động xuống dòng linh hoạt khi màn hình nhỏ.
2. **Info Grid (2x2)**:
   * Nền card: `#121212`, viền ngoài mảnh màu `#2D2D2D`.
   * Icon Container: Bo tròn nhẹ, phủ màu thương hiệu với độ trong suốt 10% (`primary.withOpacity(0.1)`).
3. **Sticky Action Bottom**:
   * Kính mờ (Glassmorphism) với `BackdropFilter` mờ 15px trên nền tối.
   * Nút "Vào giải đấu" phủ `primaryGradient` rực rỡ, bo góc `12`.
   * Nút "Xem Live" viền đỏ mảnh kèm hiệu ứng dot chấm tròn đỏ nhấp nháy (Breathing Pulse) khi giải đấu đang diễn ra.

---

## 📱 MÀN HÌNH 2: Tournament Detail (Admin Dashboard)

### Sơ đồ cấu trúc Layout
```
┌──────────────────────────────────────┐
```
```
│  🔙  Bảng Điều Hành       [⚙️]        │ ← Tiêu đề thanh trang nhã
├──────────────────────────────────────┤
│  ┌─── HERO BANNER ─────────────────┐ │
│  │  [🏸]  Giải Cầu Lông VNDC       │ │ ← Sport emblem bên trái
│  │        Cầu lông • Loại trực tiếp│ │
│  │  📅 15/06    👥 16 Đội   [LIVE] │ │
│  └──────────────────────────────────┘ │
│                                      │
│  ┌─── STATS ROW ───────────────────┐ │
│  │  [Đội]   [Trận]  [Xong]  [Live]  │ │
│  │  12      24      18      3       │ │
│  └──────────────────────────────────┘ │
│                                      │
│  ┌─── ACTION GRID (2-column) ──────┐ │
│  │ ┌──────────┐ ┌──────────┐       │ │
│  │ │ 📱 Mã    │ │ 👥 Quản  │       │ │
│  │ │  Token   │ │  lý đội  │       │ │
│  │ └──────────┘ └──────────┘       │ │
│  │ ┌──────────┐ ┌──────────┐       │ │
│  │ │ 🌳 Vẽ    │ │ 🎲 Bốc   │       │ │
│  │ │  Nhánh   │ │  thăm    │       │ │
│  │ └──────────┘ └──────────┘       │ │
│  └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Chi tiết đặc tả UI:
1. **Hero Banner**:
   * Khung nền bo góc `16`, đổ màu chuyển sắc tối từ đen sang xanh đậm.
   * Biểu tượng bộ môn: Đặt trong kén tròn 48x48 màu đục nhẹ.
2. **Stats Row**:
   * Dàn đều 4 cột bằng `Expanded`. Nền card màu `#121212`, chữ số ELO/Thống kê font size `20` đậm nét trắng tinh.
3. **Action Grid**:
   * Thiết kế dạng thẻ phẳng, tối giản nhưng cao cấp.
   * Hiệu ứng khi rê chuột/hover: Tự động sáng viền hoặc tăng độ sáng nhẹ.

---

## 🌳 MÀN HÌNH 3: Bracket (Sơ đồ nhánh đấu)

### Thiết kế Match Card (Thẻ trận đấu):
* **Kích thước**: Cố định rộng `160px`, cao `72px` để hiển thị cân đối trên mọi kích thước màn hình qua `InteractiveViewer`.
* **Trạng thái viền động**:
  * **Trận đang Live**: Viền đỏ Neon rực rỡ dày 1.5px kèm đổ bóng hồng ngoại mờ (`boxShadow` màu đỏ rực độ mờ 8px).
  * **Trận đã xong**: Viền xanh lá mảnh.
  * **Trận chưa đấu**: Viền xám tối mảnh.
* **Chi tiết bên trong card**:
  * Chia đôi bằng đường kẻ ngang cực mảnh ở giữa.
  * Mỗi đội chiếm một hàng: Tên đội căn trái (max 10 ký tự), điểm số căn phải đặt trong ô vuông xám nhạt bo góc 4.
  * Đội chiến thắng sẽ có biểu tượng 🏆 nhỏ và ô điểm chuyển màu xanh lá nổi bật.

---

## 🎛️ MÀN HÌNH 4: Live Score (Bàn Trọng Tài)

### Thiết kế giao diện Trọng Tài:
1. **Đầu trang**: 
   * Dấu chấm đỏ Neon thở nhịp nhàng (Breathing Animation) biểu thị trạng thái phát sóng trực tiếp.
2. **Phần nhập điểm**:
   * Chia đôi màn hình thành 2 nửa đối xứng trái/phải ứng với 2 đội.
   * Mỗi bên là một tấm chạm (InkWell) phản hồi nhạy bén. Chữ số điểm kích thước siêu lớn (FittedBox size 80, fontWeight w900) màu trắng sáng nổi bật trên nền tối 5%.
   * Thiết kế nút giảm điểm `[-]` nhỏ gọn nằm ở phía dưới để tránh bấm nhầm khi cộng điểm.
3. **Thanh thao tác chân trang**:
   * Nút bấm phẳng, phủ nền tối bóng, viền mảnh. Cung cấp nhanh các tính năng: Hoàn tác (Undo), Thổi còi dừng trận, và Xử thắng/Kết thúc.
