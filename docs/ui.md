# Design System & Nguyên Tắc UI (App Quản Lý Giải Đấu)

Tài liệu này quy định các chuẩn mực về giao diện (UI) và trải nghiệm người dùng (UX) cho ứng dụng Quản Lý Giải Đấu, đảm bảo tính đồng nhất, hiện đại và thân thiện, đặc biệt là với người dùng Việt Nam.

## 1. Typography (Phông chữ)
- **Font chính**: `Be Vietnam Pro`
- **Lý do**: Được thiết kế chuyên biệt cho tiếng Việt, Be Vietnam Pro mang lại sự cân đối, mềm mại, hiện đại và rất dễ đọc trên cả màn hình nhỏ lẫn màn hình lớn. Nó khắc phục được các lỗi dấu tiếng Việt thường gặp ở các bộ font quốc tế.
- **Quy tắc sử dụng**:
  - `Display/Headline`: Dùng Font-weight Bold (700) hoặc ExtraBold (800).
  - `Body/Text thường`: Dùng Font-weight Regular (400) hoặc Medium (500).
  - Tránh sử dụng quá nhiều kích cỡ chữ khác nhau trên cùng một màn hình (tuân thủ theo `TextTheme` trong `AppTheme`).

## 2. Color Palette (Bảng màu)
Ứng dụng theo đuổi phong cách **Dark Mode Premium** với độ tương phản tốt và các điểm nhấn Gradient nhẹ nhàng:
- **Background**: `#0D1117` (Màu nền sâu, tạo cảm giác chuyên nghiệp).
- **Surface/Card**: `#161B22` & `#21262D` (Phân lớp bằng màu xám đen, giúp nổi bật nội dung).
- **Primary Color**: `#6C5CE7` (Tím hiện đại, dùng cho nút bấm chính và các điểm nhấn).
- **Thành phần Role**:
  - Admin (Ban tổ chức): Đỏ nhạt (`#E74C3C`) - Quyền lực, nổi bật.
  - Referee (Trọng tài): Cam (`#F39C12`) - Rõ ràng, dễ nhận biết.
  - Viewer (Người xem): Xanh lá (`#27AE60`) - Thân thiện, an toàn.

## 3. Shape & Borders (Hình khối & Bo góc)
- **Border Radius**: Sử dụng bo góc tương đối lớn để giao diện bớt cứng nhắc (vd: 12px cho Card thường, 16-24px cho Modal/BottomSheet).
- **Borders**: Sử dụng viền cực mỏng (`1px` với màu xám trong suốt `#30363D`) cho các Card thay vì đổ bóng quá dày, tạo phong cách *flat* hiện đại kết hợp *glassmorphism* nhẹ.

## 4. Bố cục (Layout) & Spacing
- **Khoảng cách (Padding/Margin)**: Sử dụng hệ thống spacing chuẩn (4, 8, 16, 24, 32). Tuyệt đối không hardcode các số lẻ.
- **Trang chủ (Home Screen)**: Phải cung cấp trải nghiệm "Liền mạch" (Seamless). Nút Action chính như "Tạo giải" hay "Nhập mã" phải nằm trong vùng dễ thao tác bằng một tay (vùng nửa dưới màn hình hoặc nổi bật ngay Header).
- **BottomSheet**: Ưu tiên dùng BottomSheet thay vì Dialog chèn giữa màn hình cho các thao tác nhập liệu ngắn (VD: Nhập mã Token), giúp người dùng không cảm thấy bị gián đoạn hoàn toàn luồng công việc.

## 5. Animation & Micro-interactions (Hiệu ứng chuyển động)
Ứng dụng tích hợp thư viện `flutter_animate` để mang lại trải nghiệm mượt mà, sống động:
- **Hiệu ứng Xuất hiện (Entry Animations)**:
  - Tất cả các Card giải đấu ở Trang chủ và các Form của Trang tạo giải đều có hiệu ứng `fadeIn` kết hợp `slideY` (hoặc `scale`) tăng dần theo chỉ số index, tạo cảm giác tải trang mượt mà thay vì xuất hiện đột ngột.
- **Micro-interactions**:
  - Các bộ chọn (Môn thi đấu, Thể thức, Hạng mục) có hiệu ứng `scale` nhẹ (phóng to lên 2-4%) và viền đổi màu gradient/accent phát sáng khi được chọn.
  - Icon cúp vàng trên Banner Trang chủ có hiệu ứng Shimmer định kỳ và dao động tỷ lệ (pulsing) để tạo điểm nhấn thị giác thu hút.
- **LED Trạng thái (LED Indicators)**:
  - Trận đấu đang diễn ra (`statusInProgress`) có đèn LED tròn màu xanh lục có hiệu ứng phát sáng nhẹ và nhấp nháy liên tục (lặp lại vô hạn) để thu hút sự chú ý của người dùng.
- **Phản hồi Lỗi (Feedback Animations)**:
  - Khi người dùng nhập sai mã Token trong Modal, ô nhập liệu sẽ tự động thực hiện hiệu ứng lắc nhẹ (`shake` animation) để báo lỗi trực quan mà không gây khó chịu cho người xem.
