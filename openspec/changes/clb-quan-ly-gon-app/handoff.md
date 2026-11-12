# Handoff: clb-quan-ly-gon-app (App)

## Đã làm
- `lib/features/community/widgets/club_manage_session_card.dart`: bọc `SocialSessionCard` cho `ClubMatchSessionModel` (map sang `SocialSessionModel`, chip trạng thái ngắn, icon SVG môn mặc định `pickleball` vì API buổi CLB không có môn).
- `lib/features/community/widgets/club_manage_sessions_section.dart`: mục "Buổi giao lưu" trong màn quản lý, MỘT nút "Tạo buổi giao lưu", tối đa 3 thẻ + "Tất cả".
- `lib/features/social/widgets/social_session_card.dart`: thêm `badge`, `showStatIcons` (tuỳ chọn, Social không đổi); ẩn địa điểm/định dạng khi rỗng.
- `club_match_sessions_screen.dart`: danh sách dùng thẻ Social (bỏ ~290 dòng thẻ tự vẽ).
- `club_management_screen.dart`: thêm mục buổi giao lưu; mục giải gọn (bỏ mô tả, 1 dòng/giải, chạm để quản lý, icon xoá, "+" phụ); lịch định kỳ bỏ mô tả và ẩn khi rỗng (nút "Xem trang giải" bỏ, trang giải vẫn vào được từ chi tiết CLB).
- ARB vi/en: bỏ "(Cron)" ở `communityRecurringSchedulesTitle`; thêm `clubMatchSessionStatus*Short`, `clubManageSessionsTitle`; chạy `flutter gen-l10n`.

## Kiểm
- `flutter test --no-pub test/features/community/club_manage_sessions_test.dart` → exit 0 (5 test, TC-CLB-MANAGE-APP-01..05).
- `flutter test --no-pub test/features/community test/features/social/social_session_sport_icon_test.dart test/features/social/social_list_loading_test.dart` → exit 0 (41 test).
- `flutter analyze --no-pub lib/features/community lib/features/social/widgets test/features/community` → No issues.
- `openspec validate clb-quan-ly-gon-app --strict` → valid.
- Kiểm đột biến: đổi giới hạn inline 3→4 làm TC-02 đỏ, đã hoàn nguyên.

## Chưa chắc / ngã rẽ đã chọn
- Viết code trước test (lệch TDD), bù bằng kiểm đột biến ở trên.
- Không gộp `ClubTournamentsScreen` (danh sách phân trang có lọc); chọn gom buổi giao lưu vào màn quản lý thay vì xoá màn. Màn quản lý chưa có test riêng (nhiều provider); mục buổi giao lưu đã có test, phần giải/định kỳ chỉ qua analyze.
- Chạm thẻ buổi trong mục quản lý mở màn danh sách (nơi có socket vào phòng), không vào thẳng chi tiết.
- Icon môn luôn pickleball cho buổi CLB. Chưa có ảnh chụp (không chạy app trên máy này).
- Chạy `dart format` nhầm toàn thư mục, đã hoàn tác file ngoài phạm vi bằng `git apply -R`.
