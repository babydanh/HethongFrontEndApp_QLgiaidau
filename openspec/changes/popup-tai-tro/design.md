## Quyết định

1. **Nhà tài trợ thiếu logo vẫn hiện.** Web dùng `SponsorLogo` với chữ cái đầu khi không có ảnh; App đã có `_buildFallbackInitials` nhưng hai chỗ dữ liệu lọc `logoUrl.isNotEmpty` nên thẻ không bao giờ tới được widget. Bỏ điều kiện logo, giữ điều kiện tên (tên rỗng vẫn bị bỏ).
2. **Một theme, không sửa từng popup.** `app_theme.dart` đã có `dialogTheme` (bo 20, viền mảnh) và `bottomSheetTheme` (bo 24). Thay vì thêm theme mới, gỡ phần nhái ở chỗ gọi (cùng màu `bgCard`, bo 16/20/24) để popup ăn theme.
3. **Tay kéo.** ui-ux-pro-max không có mục riêng cho Flutter dialog; áp nguyên tắc chung (nhãn "chung"): sheet phải có điểm bám để đóng bằng tay, vùng chạm ≥ 48 dp. Chỉ thêm tay kéo cho sheet ăn theme; sheet nền trong suốt tự dựng khung giữ nguyên để không vẽ tay kéo lên nền trong.
4. **Không đặt `showDragHandle` vào theme.** Làm vậy sẽ hiện hai tay kéo ở sheet đã tự vẽ (30 chỗ) và tay kéo nổi trên nền trong suốt.
5. **Giữ ngoại lệ.** `tournament_management_athletes_tab.dart:708` dùng `c.surface` và `surfaceTintColor` riêng nên không đụng.

6. **Podium theo tông huy chương.** Ảnh E2E cloud cho thấy thẻ Á quân (nền xám) chữ cam và thẻ hạng Ba (nền đào) chữ xanh dương, lệch với huy chương. Đổi `_PodiumSlot._ink`: vàng 93370D, bạc 344054, đồng B54708 (đều ≥ 4.5:1 trên nền của thẻ).
7. **E2E cũ hỏng vì bảng Kết quả đổi nguồn.** Bảng quản lý đọc `managedMatchesWithDivisionProvider` và mở xếp lịch bằng dòng giờ/sân; test cũ override `matchesProvider` và bấm icon lịch nên thấy bảng trống rồi không tìm được nút. Sửa test chứ không sửa app.

## Phương án đã loại
- Sửa từng popup bằng tay (khoảng 200 chỗ): quá rộng, dễ vỡ, không có ảnh để chọn cái nào xấu.
- Thêm `dialogTheme` mới: đã có từ change `tong-quan-popup-chung`.

## Rủi ro
- Dialog `official_score_modal.dart`, `penalty_input_dialog.dart` đổi bo và có viền mảnh; nội dung giữ nguyên.
- Ảnh E2E trên cloud là cơ sở so sánh; chưa chụp trên điện thoại thật.
