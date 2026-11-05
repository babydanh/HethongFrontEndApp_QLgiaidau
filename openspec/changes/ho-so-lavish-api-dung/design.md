## Khuôn

Dùng bộ Lavish có sẵn (`features/tournament/widgets/lavish_kit.dart`) làm khuôn chung, đúng vibe trang quản lý giải đấu: nền `LavishSurface`, nhóm `LavishGroupHeader`, hàng phẳng `LavishRow` + `LavishIconBox`, pill trạng thái, nút `LavishButton`. Màu lấy từ `LavishColors.of(context)` (đã có sáng/tối).

Bổ sung widget chung trong `lavish_kit_extras.dart` (không sửa API cũ của kit):
`LavishScaffold` (AppBar back + title + actions, `LavishSurface`, bottom bar), `LavishTextField`, `LavishStickyBar` (thanh lưu dính đáy + lỗi), `LavishStat` / `LavishStatGrid` (ô số liệu), `LavishEmptyState`, `LavishErrorState` (message tham số, nút thử lại), `LavishRowSkeleton`.

## Quyết định

- Giữ hai nguồn màu: Lavish cho nội dung, `context.colors` cho nền Scaffold, như trang quản lý giải đấu hiện tại. Không gộp.
- Ít chữ: mỗi màn bỏ câu giải thích dài, giữ nhãn ngắn; chuỗi mới vào cả hai file `.arb`.
- Lỗi mạng không còn bị nuốt về danh sách rỗng: provider ném lỗi, màn hiện `LavishErrorState`.
- Sửa API ngay tại màn, dùng repository có sẵn nếu có (`ApiUserRepository.changePassword`).
- Chia việc theo file để chạy song song; `.arb` và router chỉ thêm dòng, không sắp xếp lại.

## Phương án đã bỏ

- Dùng `FormSection`/`StatusSegment`/`AppActionButton` cũ: là phong cách Card cũ, lệch khuôn.
- Dựng design system mới: trùng với Lavish, tốn công.
- Thêm route Backend tương thích: ngoài phạm vi, App sửa theo route Backend hiện có.
