# Kế Hoạch Triển Khai Đa Nền Tảng (Mobile, Tablet, TV)

Tài liệu này phác thảo chiến lược nâng cấp ứng dụng Quản lý Giải đấu từ một ứng dụng di động đơn thuần thành một hệ thống **Adaptive & Responsive** toàn diện. Tất cả các bước triển khai trong tài liệu này **phải tuân thủ nghiêm ngặt các tiêu chuẩn mã nguồn được định nghĩa tại `docs/SKILLS.md`** (SOLID, DRY, Clean Code, AppTheme, AppConstants).

---

## 1. Mục tiêu cốt lõi

- **Mobile (Width < 600dp):** Giữ nguyên trải nghiệm vuốt dọc, các danh sách dàn theo chiều dọc (1 cột).
- **Tablet (Width 600dp - 1200dp):** Tận dụng không gian ngang bằng Split-Screen (chia đôi màn hình), hiển thị `GridView` nhiều cột. Áp dụng DRY: Tái sử dụng các widget con thay vì viết lại toàn bộ luồng UI.
- **Smart TV/Web (Width > 1200dp):** Giao diện kích thước lớn, sử dụng `FocusNode` để hỗ trợ remote control (D-pad), hiển thị Bracket khổng lồ mà không vỡ layout.

---

## 2. Kiến trúc `ResponsiveLayout` (Tuân thủ DRY & SRP)

Để không lặp lại code kiểm tra kích thước màn hình ở khắp nơi, chúng ta sẽ xây dựng một Shared Widget duy nhất tại `lib/core/widgets/responsive_layout.dart`. Widget này chịu trách nhiệm duy nhất (Single Responsibility Principle) là phân luồng giao diện:

```dart
import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktopOrTv;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktopOrTv,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobile;
        } else if (constraints.maxWidth < 1200) {
          return tablet ?? mobile;
        } else {
          return desktopOrTv ?? tablet ?? mobile;
        }
      },
    );
  }
}
```

---

## 3. Các thay đổi về UI/UX (Tuân thủ Clean Code & AppTheme)

### A. Màn hình Danh sách Giải đấu (`home_screen.dart`)
- **Mobile:** Sử dụng `ListView.builder` dạng dọc.
- **Tablet/TV:** Chuyển sang `GridView.builder` sử dụng `SliverGridDelegateWithMaxCrossAxisExtent`.
  - Thay vì fix cứng số cột (tránh hardcode theo chuẩn Clean Code), dùng `maxCrossAxisExtent: 350` để Flutter tự động tính toán số cột.
  - Tái sử dụng nguyên bản widget `TournamentCard` đã được tách ở giai đoạn refactor.

### B. Màn hình Chi tiết Giải đấu (Master-Detail)
- **Mobile:** Dùng GoRouter Push sang một trang mới.
- **Tablet/TV:** Áp dụng Split-View (Chia đôi màn hình). 
  - Bên trái (Width 30%): Danh sách.
  - Bên phải (Width 70%): Chi tiết. 
  - Dùng state (StateProvider qua Riverpod) để lưu ID giải đấu/trận đấu đang được chọn thay vì routing lại toàn bộ trang. Việc này tuân thủ quy định Immutable State Management.

### C. Màn hình Sơ đồ thi đấu (Bracket)
- Tận dụng `InteractiveViewer`.
- Tách logic xử lý di chuyển bằng Remote TV ra một lớp hoặc hook riêng, tránh phình to method `build()` quá 50 dòng (theo quy định `SKILLS.md`).

---

## 4. Hỗ trợ Điều khiển TV (Focus System)

TV bắt buộc phải triển khai hệ thống **Focus Tree**. Chúng ta sẽ tạo một widget bọc ngoài `AppFocusable` tại `core/widgets/` để tái sử dụng ở mọi nơi.

- Không hardcode màu và size. Luôn sử dụng `context.colors.primary` và `AppTheme.radiusMedium` khi vẽ hiệu ứng Glow.
- Thuật toán `onFocusChange`: 
  - Khi được remote trỏ vào: Dùng `AnimatedScale` phóng to lên 1.05x, thêm `BoxShadow` từ cấu hình Theme.
  - Khi remote trỏ đi: Thu nhỏ lại kích thước bình thường.

---

## 5. Cơ chế Xoay màn hình thông minh (Smart Orientation)

Giao diện sẽ tự động phân xử (không hardcode khoá dọc toàn bộ ứng dụng). Việc này sẽ được cấu hình trong hàm `main()` hoặc một `AppInitializer` service:

- **Điện thoại di động (Width < 600dp):** Khóa cứng ở chế độ Màn hình dọc (Portrait) để tránh lỗi tràn viền. Chỉ mở khóa tạm thời khi vào xem **Sơ đồ Bracket** và **Màn hình Nhập điểm trận đấu**. Mọi lệnh gọi `SystemChrome.setPreferredOrientations` phải được trả về trạng thái cũ ở hàm `dispose()`.
- **Tablet / Smart TV / Web (Width >= 600dp):** Mở khóa hoàn toàn đa hướng. Cho phép người dùng cầm Tablet ở mọi tư thế, hoặc hiển thị tỷ lệ ngang 16:9 khi xuất ra máy chiếu. Hệ thống `ResponsiveLayout` sẽ tự gánh vác phần sắp xếp lại nội dung.

---

## 6. Danh sách Công việc (Roadmap)

1. `[ ]` Tạo thư mục và file `lib/core/widgets/responsive_layout.dart`.
2. `[ ]` Xây dựng Shared Widget `AppFocusable` hỗ trợ Focus Mode cho TV (tuân thủ giới hạn dòng code và Theme).
3. `[ ]` Nâng cấp `home_screen.dart` để tự động đổi `ListView` thành `GridView` trên Tablet/TV thông qua `ResponsiveLayout`.
4. `[ ]` Triển khai Master-Detail Split-Screen cho màn hình Chi tiết giải đấu khi chạy trên màn hình lớn.
5. `[ ]` Cấu hình `Shortcuts` và `Actions` ở màn hình Bracket để tương tác bằng D-pad (Remote TV) và cấu trúc lại mã xử lý Bracket để tránh vi phạm SRP.

> [!IMPORTANT]  
> Các tính năng Responsive này cần được thiết lập sớm và chuẩn mực. Khi đã có khung chuẩn vững chắc trong thư mục `core`, các giao diện sau này sẽ được kế thừa và tự động tương thích đa nền tảng một cách hoàn hảo mà không tốn công tối ưu lại!
