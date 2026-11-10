## Why

Người dùng không thấy giao diện đổi tay (Giao 1 <-> Giao 2) và đổi giao: hiện chỉ là nhãn "Giao N" kéo/chạm trên sân, dễ bỏ sót. Người dùng muốn MỘT nút duy nhất nằm giữa hai cụm −/+ ở thanh dưới (2026-11-09), căn giữa đúng.

## What Changes

- Thêm một nút "Đổi giao" ở giữa thanh dưới của bảng điểm sân (ngang và dọc). Bấm một lần = một bước mất giao, dùng đúng bước của "+" bên nhận: Giao 1 -> Giao 2 -> đội kia (đánh đơn: sang đội kia ngay), điểm giữ nguyên, một lần hoàn tác trả lại.
- Một nút, tên theo bước kế tiếp: đang Giao 1 (đôi, sau lượt mở đầu) ghi "Đổi tay"; còn lại ghi "Đổi giao" (2026-11-10).
- Nút ẩn với người xem và khi chưa chọn đội giao.
- Nút nằm đúng giữa chiều ngang màn hình, cùng hàng với −/+.

## Out of scope

- Không đổi luật tự chuyển giao, không đổi chạm VĐV/kéo trái bóng.
- Không sửa Backend. Web làm ở nhánh Web riêng.

## Capabilities

### Modified Capabilities
- `pickleball-court-scoring`: nút đổi giao ở giữa thanh dưới.
