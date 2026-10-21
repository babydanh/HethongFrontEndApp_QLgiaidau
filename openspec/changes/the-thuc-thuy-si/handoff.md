# Bàn giao: the-thuc-thuy-si (App)

## Mục tiêu
App Flutter hỗ trợ thể thức Thụy Sĩ: nhãn và chọn thể thức, cấu hình (số vòng, tiebreak kéo sắp, ghép vòng 1), xem (bảng xếp hạng phẳng theo `rank` Backend, lịch trận theo vòng, BYE), và màn Ghép cặp vòng N cho BTC (máy đề xuất → nhấn giữ kéo hoặc chọn từ bảng chọn → xác nhận, hoàn tác). Backend và Web có change cùng tên, cùng hợp đồng (`design.md`).

## Trạng thái
Plan xong (proposal, design, 3 specs, tasks); chưa viết mã. Nhánh `thuy-si-20261021` từ `origin/main`. Làm tuần tự 1.1 → 6.1.

## Đã thử: cách → kết quả → vì sao
- Tự tính Buchholz ở client → loại → lệch Backend; tin `rank` do Backend trả.
- Mỗi bàn là một `Card` có avatar → loại → người dùng yêu cầu phẳng, không khung lồng khung, ít icon.
- Dùng `lib/data/api_service.dart` → loại → file sinh, không được app import, bị ghi đè khi sinh lại.
- Nhét `roundConfig` vào `MatchModel` → loại → phình mô hình dùng chung; dùng `swissStageProvider` riêng.

## Ràng buộc đang có
- Agent KHÔNG push `main`; không `git add -A`.
- Worktree không có `.env`: không đọc/in/chép `.env`; chỉ chạy test không cần `.env`.
- Mọi chuỗi qua `app_vi.arb` + `app_en.arb` rồi `flutter gen-l10n`; không sửa tay file sinh.
- Không thêm package. Test nặng/E2E chạy trên cloud (skill `cloud-test-runner`), không cục bộ.
- Hợp đồng Backend ở `design.md` KHÔNG đổi tùy tiện; cần đổi thì ghi "Câu hỏi còn mở" và báo người dùng.
- Chỉ đánh `- [x]` sau khi tiêu chí task pass.

## Ràng buộc thay đổi lần này
Thêm mới: luật UI phẳng (không Card trong Card, ≤ 1 loại icon) và hợp đồng Swiss.

## Câu hỏi còn mở
- Chưa biết trận Swiss từ `/bracket` có `groupName` không; task 1.3 ưu tiên `stageType == 'SWISS'` nên không phụ thuộc.
- Cách phân biệt "người quản lý" trong `bracket_view_screen.dart` phải đọc từ code thật ở task 5.3.
- Task 4.1 cần `updateDivisionConfig` và API sinh sơ đồ sẵn có; nếu chữ ký khác dự kiến thì ghi lại ở đây.
- `lib/data/api_service.dart` do `scripts/sync-api-clients.js` sinh (ngoài repo), không được app dùng; không cần sinh lại cho change này.
