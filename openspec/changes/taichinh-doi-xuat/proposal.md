## Why

Ba màn quản lý giải trong App còn rối so với thiết kế đã duyệt (mục 19, 20, 21 của bản audit UI): form ngân hàng trải dài trên trang Tài chính, danh sách đội cắt tên và không tìm/lọc được, và chưa có chỗ xuất báo cáo nhiều sheet.

## What Changes

- Màn Tài chính: lệ phí + bảng tính ở trên, nút "Lưu lệ phí" cố định ở đáy; form ngân hàng vào bottom sheet mở từ dòng "Gửi yêu cầu thanh toán" (có hộp xác nhận, chặn bấm đúp); lịch sử thanh toán thành một dòng mở danh sách riêng. Không đổi API và quy tắc tiền.
- Màn Quản lý đội / VĐV (`TeamListScreen`, nguồn `teamsProvider`, KHÁC danh sách tab VĐV của hub): ô tìm, chip lọc trạng thái có số, tên cặp xuống 2 dòng, số thứ tự nhỏ, menu ⋮ gom Sửa/Xóa. Không đổi chỗ đặt màn.
- Xuất báo cáo: mục "Xuất báo cáo" trong menu ⋮ của hub mở sheet tick sheet cần xuất (Danh sách VĐV, Trận đấu), xuất một file Excel nhiều sheet bằng `ExcelExportService`.

## Impact

Không có endpoint mới, không thêm package. Sheet Lịch/Kết quả riêng, Tài chính, Hạng mục, Nhân sự chưa làm: App chưa có dữ liệu hoặc endpoint tương ứng (xem `tasks.md`).
