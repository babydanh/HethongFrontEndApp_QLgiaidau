# Test Cases - Flutter: Home, Dashboard, Upload, QR Scanner

## 1. HOME / EXPLORE (TC-FLUTTER-HOME)

### TC-FLUTTER-HOME-001: Hiển thị danh sách giải đấu
- **Module**: home
- **Screen**: `features/home/screens/home_screen.dart`
- **Preconditions**: Đã login, có dữ liệu tournament
- **Steps**: 1. Vào Home tab (Explore)\n2. Quan sát danh sách
- **Expected**: Hiển thị danh sách tournament, có phân loại Live/Upcoming/Completed
- **Edge cases**: Tournament list rỗng, chỉ có 1 tournament

### TC-FLUTTER-HOME-002: Filter theo môn thể thao
- **Module**: home
- **Screen**: `features/home/screens/home_screen.dart`
- **Preconditions**: Có nhiều tournament khác môn
- **Steps**: 1. Vào Home tab\n2. Chọn filter "Cầu lông"
- **Expected**: Chỉ hiển thị tournament môn Cầu lông
- **Edge cases**: Chọn "Tất cả", chọn môn không có dữ liệu

### TC-FLUTTER-HOME-003: Search giải đấu
- **Module**: home
- **Screen**: `features/home/screens/home_screen.dart`
- **Preconditions**: Có dữ liệu
- **Steps**: 1. Vào Home tab\n2. Gõ tên giải vào search bar
- **Expected**: Filter realtime theo tên
- **Edge cases**: Search không có kết quả, search tiếng Việt không dấu

### TC-FLUTTER-HOME-004: Carousel giải nổi bật
- **Module**: home
- **Screen**: `features/home/screens/home_screen.dart`
- **Preconditions**: Có ít nhất 2 tournament nổi bật
- **Steps**: 1. Vào Home tab\n2. Vuốt carousel
- **Expected**: Tự động chuyển trang, có dot indicator
- **Edge cases**: Không có tournament nổi bật

### TC-FLUTTER-HOME-005: Pull-to-refresh
- **Module**: home
- **Screen**: `features/home/screens/home_screen.dart`
- **Preconditions**: Đã có dữ liệu
- **Steps**: 1. Kéo xuống để refresh
- **Expected**: Danh sách được refresh, loading indicator
- **Edge cases**: Refresh khi đang tải

### TC-FLUTTER-HOME-006: Tab giải đấu (Tournaments tab)
- **Module**: home
- **Screen**: `features/home/screens/home_screen.dart`
- **Preconditions**: Có tournament
- **Steps**: 1. Vào Tab "Giải đấu"\n2. Quan sát
- **Expected**: Hiển thị danh sách tournament + status segment (Tất cả/Đăng ký/Thi đấu/Hoàn thành)
- **Edge cases**: Chuyển tab, filter kết hợp

### TC-FLUTTER-HOME-007: Loading state
- **Module**: home
- **Screen**: `features/home/screens/home_screen.dart`
- **Preconditions**: API chậm
- **Steps**: 1. Vào Home
- **Expected**: Hiển thị CircularProgressIndicator hoặc shimmer

### TC-FLUTTER-HOME-008: Error state
- **Module**: home
- **Screen**: `features/home/screens/home_screen.dart`
- **Preconditions**: API lỗi
- **Steps**: 1. Vào Home
- **Expected**: Hiển thị error message + nút Thử lại

## 2. DASHBOARD (TC-FLUTTER-DASH)

### TC-FLUTTER-DASH-001: Dashboard workspace
- **Module**: dashboard
- **Screen**: `features/dashboard/screens/dashboard_screen.dart`
- **Preconditions**: Đã login, có workspace data
- **Steps**: 1. Vào /dashboard
- **Expected**: Hiển thị workspace overview (organized, participating, referee)
- **Edge cases**: Workspace rỗng, chỉ có 1 loại

### TC-FLUTTER-DASH-002: Chưa login redirect
- **Module**: dashboard
- **Screen**: `features/dashboard/screens/dashboard_screen.dart`
- **Preconditions**: Chưa login
- **Steps**: 1. Vào /dashboard
- **Expected**: Hiển thị login prompt
- **Edge cases**: Session hết hạn

### TC-FLUTTER-DASH-003: OrganizerLiteSection
- **Module**: dashboard
- **Screen**: `features/dashboard/screens/dashboard_screen.dart`
- **Preconditions**: User là organizer
- **Steps**: 1. Vào /dashboard\n2. Quan sát OrganizerLiteSection
- **Expected**: Hiển thị tournament đang quản lý, có nút Xem
- **Edge cases**: Không có tournament nào, nhiều tournament

### TC-FLUTTER-DASH-004: RoleSection
- **Module**: dashboard
- **Screen**: `features/dashboard/screens/dashboard_screen.dart`
- **Preconditions**: User có nhiều role
- **Steps**: 1. Vào /dashboard\n2. Quan sát RoleSection
- **Expected**: Hiển thị organized, co-organizer, referee, participating counts
- **Edge cases**: Không có role nào

### TC-FLUTTER-DASH-005: TournamentSection (Giải của tôi)
- **Module**: dashboard
- **Screen**: `features/dashboard/screens/dashboard_screen.dart`
- **Preconditions**: Có tournament
- **Steps**: 1. Vào /dashboard\n2. Quan sát "Giải của tôi"
- **Expected**: Hiển thị visibleTournaments, mỗi tournament có nút Xem giải + Xem bracket
- **Edge cases**: Chưa có giải nào

### TC-FLUTTER-DASH-006: AssignedMatchesSection
- **Module**: dashboard
- **Screen**: `features/dashboard/screens/dashboard_screen.dart`
- **Preconditions**: User là referee
- **Steps**: 1. Vào /dashboard\n2. Quan sát match list
- **Expected**: Hiển thị referee matches kèm thông tin
- **Edge cases**: Chưa có match

### TC-FLUTTER-DASH-007: Loading state
- **Module**: dashboard
- **Screen**: `features/dashboard/screens/dashboard_screen.dart`
- **Preconditions**: API chậm
- **Steps**: 1. Vào /dashboard
- **Expected**: Hiển thị loading
- **Edge cases**: Timeout

## 3. UPLOAD (TC-FLUTTER-UPLOAD)

### TC-FLUTTER-UPLOAD-001: Upload avatar thành công
- **Module**: upload
- **Screen**: `features/profile/screens/profile_screen.dart`
- **Preconditions**: Đã login
- **Steps**: 1. Vào Profile\n2. Tap avatar\n3. Chọn ảnh từ gallery\n4. Chờ upload
- **Expected**: Avatar cập nhật, snackbar "Ảnh đại diện đã được cập nhật"
- **Edge cases**: Ảnh quá lớn, định dạng sai

### TC-FLUTTER-UPLOAD-002: Upload cover thành công
- **Module**: upload
- **Screen**: `features/profile/screens/profile_screen.dart`
- **Preconditions**: Đã login
- **Steps**: 1. Vào Profile\n2. Tap cover\n3. Chọn ảnh\n4. Chờ upload
- **Expected**: Cover cập nhật, snackbar xanh
- **Edge cases**: Hủy chọn ảnh

### TC-FLUTTER-UPLOAD-003: Upload thất bại
- **Module**: upload
- **Screen**: `features/profile/screens/profile_screen.dart`
- **Preconditions**: API lỗi
- **Steps**: 1. Chọn ảnh\n2. Upload
- **Expected**: Snackbar đỏ báo lỗi
- **Edge cases**: Network error

## 4. QR SCANNER (TC-FLUTTER-QR)

### TC-FLUTTER-QR-001: Màn hình QR Scanner
- **Module**: qr
- **Screen**: `features/home/screens/qr_scanner_screen.dart`
- **Preconditions**: Đã login
- **Steps**: 1. Vào /scan-qr\n2. Quan sát
- **Expected**: Hiển thị camera preview, có nút flash
- **Edge cases**: Chưa cấp quyền camera

### TC-FLUTTER-QR-002: Quét QR token thành công
- **Module**: qr
- **Screen**: `features/home/screens/qr_scanner_screen.dart`
- **Preconditions**: Có QR code hợp lệ
- **Steps**: 1. Quét QR\n2. Xử lý token
- **Expected**: Redirect đến màn hình tương ứng
- **Edge cases**: QR không hợp lệ

## 5. DASHBOARD LITE (TC-FLUTTER-OLITE)

### TC-FLUTTER-OLITE-001: OrganizerLiteScreen
- **Module**: olite
- **Screen**: `features/dashboard/screens/organizer_lite_screen.dart`
- **Preconditions**: User là organizer, tournament tồn tại
- **Steps**: 1. Vào /organizer-lite/:id\n2. Quan sát
- **Expected**: Hiển thị thông tin tournament đơn giản
- **Edge cases**: Tournament không tồn tại

### TC-FLUTTER-OLITE-002: Lite screen loading/error
- **Module**: olite
- **Screen**: `features/dashboard/screens/organizer_lite_screen.dart`
- **Preconditions**: API chậm
- **Steps**: 1. Vào /organizer-lite/:id
- **Expected**: Hiển thị loading, nếu lỗi hiển thị error
- **Edge cases**: Network error
