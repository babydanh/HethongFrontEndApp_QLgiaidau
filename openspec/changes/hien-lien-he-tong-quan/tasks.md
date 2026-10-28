## 1. Hàm thuần quyết định hiển thị

- [x] 1.1 Viết test đỏ rồi hàm `visibleContact` theo D1/D2. Tiêu chí: `flutter test --no-pub test/features/tournament/utils/tournament_contact_test.dart` → exit 0 (test phải đỏ trước khi có hàm)
  - Files: tạo `lib/features/tournament/utils/tournament_contact.dart`; test `test/features/tournament/utils/tournament_contact_test.dart`
  - Giao: `class TournamentContact { final String organizerName; final String phone; final String email; final bool hiddenFromViewers; }`; `TournamentContact? visibleContact(Map<String, dynamic>? info, {required bool isManager})` · Nhận: (không)
  - Chủ file chung: 1.1 giữ cả hai file
  - Phụ thuộc: (không)
  - Ca test (dữ liệu giả): null → null; MANUAL + tên + SĐT không cờ → tên + SĐT, email rỗng; PROFILE + `hidden:false` → SĐT + email; PROFILE không cờ, không quản lý → null; PROFILE `hidden:true`, quản lý → SĐT + email, `hiddenFromViewers = true`; `displayMode` chữ thường vẫn nhận; khoảng trắng và giá trị sai kiểu (số, bool) → rỗng → null

## 2. Chuỗi hiển thị

- [x] 2.1 Thêm key `tournamentContactTitle`, `tournamentContactPhone`, `tournamentContactEmail`, `tournamentContactHiddenHint` vào cả hai ARB rồi sinh lại. Tiêu chí: `flutter gen-l10n` → exit 0 và `flutter analyze --no-pub lib/l10n` → exit 0
  - Files: sửa `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`; sinh `lib/l10n/app_localizations*.dart` (không sửa tay)
  - Giao: bốn getter l10n cho 3.1 · Nhận: (không)
  - Chủ file chung: 2.1 giữ cả hai ARB
  - Phụ thuộc: (không)

## 3. Khối Liên hệ ở Tổng quan

- [x] 3.1 Viết widget test đỏ rồi thêm khối Liên hệ sau khối Ban tổ chức. Tiêu chí: `flutter test --no-pub test/features/tournament/overview_contact_block_test.dart` → exit 0 (đỏ trước), `flutter analyze --no-pub lib/features/tournament` → exit 0
  - Files: sửa `lib/features/tournament/widgets/overview_tab.dart` (chèn sau dòng ~947, trong cùng `Column`; không đổi dòng nào khác); test `test/features/tournament/overview_contact_block_test.dart`
  - Giao: (không) · Nhận: `visibleContact`/`TournamentContact` từ 1.1, getter l10n từ 2.1
  - Chủ file chung: 3.1 giữ `overview_tab.dart`
  - Phụ thuộc: sau 1.1, 2.1
  - Ca test: bốn scenario của spec (MANUAL, PROFILE công khai, PROFILE ẩn không có chữ SĐT trong cây widget, quản lý thấy kèm dòng gợi ý); `contactInfo` null không lỗi; email dài ở viewport 320 không overflow; các widget cũ (tên người tạo, con mắt) vẫn có mặt

## 4. Kiểm tổng

- [x] 4.1 (Đã kiểm 2026-10-28 trên nhánh tích hợp `e2e-xem-man-moi`: `flutter analyze --no-pub` trên `lib/features/tournament lib/features/bracket lib/core/router lib/providers lib/l10n` = 0 lỗi, 0 cảnh báo, 13 `info` cũ ở dòng nhánh không sửa nên lệnh thoát 1; 38 file test của nhánh = 409 test xanh, thoát 0; `overview_tab.dart` 0 dòng xoá; `flutter-reviewer` không P0/P1) Typecheck và chạy đúng test do ripwire `affected` chọn; `git diff -U0` giải thích mọi dòng `-` (kỳ vọng: không có dòng xoá ở `overview_tab.dart`); `flutter-reviewer` không còn P0/P1. Tiêu chí: `flutter analyze --no-pub lib/features/tournament lib/l10n` → exit 0 và `flutter test --no-pub` trên các file `affected` chọn → exit 0
  - Files: (không sửa mới)
  - Phụ thuộc: sau 3.1
