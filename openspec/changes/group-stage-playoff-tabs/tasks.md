# Tasks

## 1. Tab nội dung vòng bảng và playoff

- [x] 1.1 Thêm hai tab con cho thể thức vòng bảng + playoff, mặc định chọn Bảng; cập nhật `test/features/public_bracket_view_test.dart` để xác nhận mặc định, chuyển tab, chỉ hiện trận knockout ở Playoff và vẫn có hai tab rỗng khi chưa có trận.
- [x] 1.2 Nối tab Bảng với bảng xếp hạng theo `divisionId`; kiểm tra giải có thể thức chung vòng tròn nhưng hạng mục là vòng bảng + playoff, xác nhận dùng thể thức hạng mục khi đánh dấu đội đi tiếp; kiểm tra một giai đoạn rỗng không làm hỏng tab còn lại.
- [x] 1.3 Giữ giao diện không có tab mới cho thể thức chỉ vòng bảng hoặc chỉ loại trực tiếp; thêm kiểm thử hồi quy cho cả hai thể thức.

## 2. Nhãn và ngôn ngữ

- [x] 2.1 Dùng khóa dịch sẵn có nếu đúng nghĩa; nếu chưa có, thêm khóa tương ứng cho nhãn Bảng/Playoff vào `lib/l10n/app_vi.arb` và `lib/l10n/app_en.arb`, chạy `flutter gen-l10n` và xác nhận hai tệp có cùng khóa.

## 3. Kiểm tra tích hợp

- [x] 3.1 Chạy `flutter analyze --no-pub lib/features/bracket/widgets` và `flutter test --no-pub test/features/public_bracket_view_test.dart`; chạy thêm test hạng mục giải bị ảnh hưởng và xác nhận toàn bộ ca chuyển tab, rỗng dữ liệu, thể thức đơn đều đạt.