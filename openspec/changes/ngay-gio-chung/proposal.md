## Why

Trang Đăng ký quản lý giải hiển thị mốc thời gian trong ô hẹp, nhãn và giá trị bị xuống dòng hoặc cắt chữ, lỗi thứ tự ngày chỉ hiện sau khi bấm Lưu và không chỉ ra ô sai. Việc chọn ngày giờ đang chép nhiều kiểu (hộp ngày rồi hộp giờ hệ thống) ở Đăng ký, Tạo giải nhanh (chép 4 lần) và cấu hình vòng đấu; hộp giờ không chọn được 23:59.

## What Changes

- Ô ngày giờ dùng chung: nhãn nhỏ ở trên, giá trị đầy đủ năm, không cắt chữ; có trạng thái lỗi (viền đỏ và lý do ngay dưới ô).
- `SocialDateTimePickerSheet` thêm tham số tuỳ chọn: dòng phụ dưới tiêu đề, `minDate`/`maxDate` (ngày ngoài khoảng bị mờ và không xác nhận được), chip "23:59".
- Trang Đăng ký: 4 mốc dùng ô chung và popup cuộn; lỗi thứ tự ngày hiện ngay dưới đúng ô sai và nút Lưu bị khoá khi còn lỗi (các luật kiểm giữ nguyên).
- Tạo giải nhanh: 4 mốc dùng ô chung và popup cuộn, bỏ 4 đoạn chép.
- Cấu hình vòng đấu: giờ mặc định dùng ô chung và popup cuộn.

## Out of scope

- Hộp đặt giờ trận (#53) và Tạo buổi chơi xã hội.
- Luật kiểm thứ tự ngày mới (chỉ đổi cách báo lỗi), thay đổi Backend.
- `pickTournamentManagementDeadline` (tournament_management_widgets.dart) và các màn chọn ngày khác.

## Capabilities

### New Capabilities
- `shared-date-time-field`: ô hiển thị ngày giờ và popup cuộn dùng chung.

### Modified Capabilities

## Impact

- `lib/features/social/widgets/create_edit_screen/social_date_time_picker_sheet.dart`
- `lib/shared/widgets/date_time_field.dart` (mới)
- `lib/features/tournament/screens/tournament_management_section_screen.dart`
- `lib/features/tournament/screens/create_public_quick_tournament_screen.dart`
- `lib/features/tournament/widgets/stage_round_config_sheet.dart`
- `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`
