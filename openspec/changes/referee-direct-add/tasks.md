## 1. App: chữ, nút gỡ, thông báo

- [x] 1.1 Đổi mục Nhân sự sang thêm/gỡ trực tiếp và thêm icon/màu thông báo mới. Tiêu chí: `flutter test --no-pub test/features/tournament/utils/permission_rows_test.dart test/features/tournament/permissions_invite_section_test.dart test/domain/app_notification_route_test.dart` → exit 0 (TC-APP-REF-ADD-01..03, đỏ trước khi sửa)
  - Files: sửa `lib/features/tournament/utils/permission_rows.dart:3,56-60`; `lib/features/tournament/screens/tournament_management_people_section.dart` (:791, :839-858, :928-976); `lib/domain/entities/app_notification.dart` (:350-355, :403-410); `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (~5974-6000, 6076) + chạy `flutter gen-l10n`; test `test/features/tournament/utils/permission_rows_test.dart` (14-30), `test/features/tournament/permissions_invite_section_test.dart` (243 đổi: ACCEPTED có nút xóa), `test/domain/app_notification_route_test.dart`
  - Giao: `enum RefereeAction { none, revoke, resend, remove }` (ACCEPTED→remove) · Nhận: Backend `REFEREE_ADDED`, `REFEREE_REMOVED`; `POST /tournaments/:id/referees` trả `status: 'ACCEPTED'`; `DELETE .../referees/:refereeId` gỡ được `ACCEPTED`
  - Chủ file chung: 1.1 giữ `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_localizations*.dart`
  - Phụ thuộc: (không, hợp đồng Backend cố định ở trên)

## 2. Kiểm tra

- [x] 2.1 `flutter analyze` các file đã sửa và test liên quan. Tiêu chí: `flutter analyze <file đã sửa>` → 0 issues; lệnh test 1.1 → exit 0 (cloud run 42951741429: `flutter analyze` + full `flutter test` xanh)
