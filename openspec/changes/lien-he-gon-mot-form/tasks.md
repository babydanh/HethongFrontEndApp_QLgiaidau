## 1. Form liên hệ gọn
- [x] 1.1 Viết lại `TournamentContactForm` theo bản B (công tắc nguồn, thẻ hồ sơ, hàng icon loại liên kết, ô giá trị có ✓, danh sách liên kết icon + ✕), nhận `profileName`/`profileAvatarUrl` từ màn cha, bỏ công tắc hiện người sáng lập, bỏ khoá l10n không còn dùng. Tiêu chí: `flutter test --no-pub test/features/tournament/tournament_contact_form_test.dart` → exit 0 (10 test TC-CONTACT xanh)
  - Files: sửa `lib/features/tournament/widgets/tournament_contact_form.dart`; `lib/features/tournament/screens/tournament_management_section_screen.dart` (`_contactForm`); `lib/l10n/app_vi.arb`, `app_en.arb`; test `test/features/tournament/tournament_contact_form_test.dart`
  - Giao: `TournamentContactForm({initial, onChanged, profileName?, profileAvatarUrl?})` · Nhận: `userProfileProvider` (đã có)
  - Chủ file chung: 1.1 giữ `app_vi.arb`, `app_en.arb`
  - Phụ thuộc: không

## 2. Kiểm tra
- [x] 2.1 Sửa test hub cho hợp form mới, `flutter analyze --no-pub` file đã sửa, chạy test hẹp. Tiêu chí: `flutter test --no-pub test/features/tournament_management_hub_screen_test.dart` → exit 0 (134 test liên quan xanh, analyze file sửa sạch; test hub không cần sửa vì khoá `info-contact-mode` vẫn còn). Ghi chú: CHƯA xem trên điện thoại thật
  - Files: sửa `test/features/tournament_management_hub_screen_test.dart`
  - Phụ thuộc: sau 1.1
