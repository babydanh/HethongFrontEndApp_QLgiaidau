## 1. Luật dữ liệu (logic thuần)

- [x] 1.1 Viết test đỏ cho luật tên ghép và loại trùng. Tiêu chí: `flutter test --no-pub test/core/participants/participant_display_test.dart` → exit 1 trước khi sửa
  - Files: sửa `test/core/participants/participant_display_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: (không)
- [x] 1.2 Thêm `teamNameIsJoinedNames` vào `resolveParticipantDisplay` và hàm lọc trùng riêng (`userId`, khách theo tên chuẩn hoá) dùng trong ba adapter. Tiêu chí: `flutter test --no-pub test/core/participants/participant_display_test.dart` → exit 0
  - Files: sửa `lib/core/participants/participant_display.dart:103-226`
  - Giao: không đổi chữ ký công khai; `List<ParticipantPlayer> toParticipantPlayers(Map<dynamic, dynamic> json)` giữ nguyên · Nhận: (không)
  - Chủ file chung: 1.2 giữ `participant_display.dart`
  - Phụ thuộc: sau 1.1

## 2. Widget

- [x] 2.1 Viết test đỏ cho `ParticipantLabel`: một dòng `A / B`, tối đa 2 avatar, chữ cái đầu 1 ký tự. Tiêu chí: `flutter test --no-pub test/core/participants/participant_label_test.dart` → exit 1 trước khi sửa
  - Files: sửa `test/core/participants/participant_label_test.dart`
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: sau 1.2
- [x] 2.2 Đổi `ParticipantLabel` (nhánh PLAYERS) sang một Row: avatar chồng nhau + một Text nối " / "; `_initials` lấy 1 chữ. Tiêu chí: `flutter test --no-pub test/core/participants/participant_label_test.dart` → exit 0
  - Files: sửa `lib/core/participants/participant_display.dart:267-398`
  - Giao: constructor `ParticipantLabel` giữ nguyên tham số · Nhận: (không)
  - Chủ file chung: 1.2 giữ `participant_display.dart`, 2.2 sửa tiếp sau 1.2
  - Phụ thuộc: sau 2.1

## 3. Kiểm tra cuối

- [x] 3.1 Chọn test bị ảnh hưởng bằng ripwire `affected` trên các file đã đổi, sửa test cũ tìm từng dòng tên nếu vỡ do bố cục một dòng. Tiêu chí: các file test do `affected` trả về chạy `flutter test --no-pub <file>` → exit 0
  - Files: sửa test dưới `test/` mà `affected` chỉ ra (chưa biết trước)
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: sau 2.2
- [x] 3.2 Phân tích tĩnh. Tiêu chí: `flutter analyze --no-pub lib/core/participants` → exit 0
  - Files: (không sửa file)
  - Giao: (không) · Nhận: (không)
  - Chủ file chung: (không)
  - Phụ thuộc: sau 3.1
