## Why
Màn quản lý CLB trong App rải buổi giao lưu, giải và lịch định kỳ ở nhiều màn, có chữ mô tả dài, nhãn kỹ thuật "(Cron)", thẻ buổi giao lưu tự vẽ khác phần Social. Web đã làm gọn tương ứng (`communities/[id]/manage/tournaments`).

## What Changes
- Màn Quản lý CLB có mục "Buổi giao lưu" với MỘT nút chính "Tạo buổi giao lưu" và tối đa 3 buổi gần nhất (xem tất cả ở màn danh sách).
- Thẻ buổi giao lưu (mục này và màn danh sách) dùng lại `SocialSessionCard`: icon môn SVG, chip trạng thái ngắn, số liệu icon + số. `SocialSessionCard` thêm tham số tuỳ chọn `badge`, `showStatIcons`, và ẩn phần địa điểm/định dạng khi rỗng (Social giữ nguyên).
- Mục giải đấu: bỏ câu mô tả và tiêu đề phụ, mỗi giải một dòng gọn (chạm để quản lý, icon xoá), nút tạo giải thành icon "+" phụ.
- Lịch giải định kỳ: bỏ "(Cron)", bỏ câu mô tả; ẩn cả mục khi chưa có giải định kỳ.

## Out of scope
- Không đổi API/Backend. Không gộp `ClubTournamentsScreen` (danh sách phân trang giữ nguyên).

## Capabilities
### Modified Capabilities
- `club-manage-compact`: màn quản lý CLB gọn, một nút tạo buổi giao lưu.

## Impact
`lib/features/community/screens/club_management_screen.dart`, `club_match_sessions_screen.dart`, widget mới `club_manage_session_card.dart`, `club_manage_sessions_section.dart`, `lib/features/social/widgets/social_session_card.dart`, ARB vi/en; test `test/features/community/club_manage_sessions_test.dart`.
