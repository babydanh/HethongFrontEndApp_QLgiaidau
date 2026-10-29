# Proposal

## Why

Backend và Web đã có (change cùng tên `moc-dupr-noi-dung`): BTC pickleball đặt mốc DUPR cho nội dung, Backend chặn đăng ký ngoài mốc bằng lỗi `DUPR_LIMIT_VIOLATION` (400). App hiện chỉ biết ELO: VĐV đăng ký bằng App vào nội dung có mốc DUPR sẽ nhận 400 mà không thấy mốc, không khai được điểm DUPR (App chưa có màn hay API gọi `/users/me/external-ratings`), và BTC dùng App không đặt được mốc.

## What Changes

- Hàm thuần `checkDuprAgainstLimit`, `formatDuprRange`, danh sách mốc 2.0 → 6.0 bước 0.5, và `minDupr`/`maxDupr` (`double?`) trong `TournamentDivisionOption`.
- Sheet tạo/sửa nội dung (`DivisionEditorSheet`): khi nội dung là pickleball, thêm mục "Trình DUPR" với hai ô chọn Từ/Đến (Đến là mốc bao gồm), gửi `minDupr`/`maxDupr` (số hoặc `null`).
- Repository điểm quốc tế mới: đọc điểm DUPR của mình (`GET /api/v1/users/me/external-ratings`) và khai điểm (`PUT /api/v1/users/me/external-ratings`).
- Màn đăng ký (đơn và đôi): dòng nội dung hiện mốc DUPR; chọn nội dung có mốc thì kiểm điểm DUPR của người dùng, hiện hợp lệ/thấp/cao/chưa khai, có ô khai điểm, khoá nút đăng ký khi chưa hợp lệ.
- Lỗi `DUPR_LIMIT_VIOLATION` từ Backend (đăng ký, vào đội) hiện đúng thông báo của Backend.
- Chuỗi giao diện ở `app_vi.arb` và `app_en.arb`.

## Capabilities

### New Capabilities

- `division-dupr-limit-app`: chọn mốc DUPR ở editor nội dung, hiển thị và kiểm mốc, khai điểm DUPR ở màn đăng ký của App.

### Modified Capabilities

(không có; kiểm ELO giữ nguyên, hai giới hạn cùng tồn tại)

## Out of scope

- Tổng điểm cặp, dung sai, hạn khiếu nại, BTC duyệt/chuyển hạng.
- Màn quản lý điểm quốc tế trong hồ sơ (chỉ có ô khai tại màn đăng ký).
- UTR, WTN; chỉ DUPR.
- Dialog giải nhanh công khai (`create_public_quick_tournament_screen.dart`), thêm VĐV bởi BTC (`add_athlete_sheet.dart`), thẻ nội dung ở quản lý giải, lọc theo trình.
- Giới hạn DUPR cấp cả giải; đổi hành vi kiểm ELO.

## Impact

- Backend (đã có, phải apply trước): `minDupr`, `maxDupr` trên `POST /tournaments/:id/divisions`, `PATCH /tournaments/divisions/:id` và `GET /tournaments/:id/divisions`; lỗi 400 `DUPR_LIMIT_VIOLATION` ở `POST /tournaments/:id/register` và `POST /tournaments/:id/join-team` (body lỗi: `code`, `message`, `details {reason, minDupr, maxDupr, value}`); `GET/PUT /users/me/external-ratings` (đã có sẵn).
- Web: không.
- App: `lib/domain/entities/tournament_registration.dart`, `lib/features/tournament/widgets/division_editor_sheet.dart`, `lib/features/register/screens/tournament_register_screen.dart`, `doubles_registration_screen.dart`, `join_team_screen.dart`, `lib/core/utils/error_parser.dart` (chỉ nếu cần), `lib/core/di/repository_providers.dart`, repository mới, `lib/l10n/app_vi.arb`, `app_en.arb` (+ sinh lại), test mới.
- Một change khác đụng `division_editor_sheet.dart` (`quan-ly-giai-web-parity`, task 2.1 còn mở); chỉ thêm mục DUPR, không tái cấu trúc để giảm xung đột khi gộp.
