# Bàn giao: the-thuc-thuy-si (App)
Cập nhật: 2026-10-21 · bởi: omp · nhánh: thuy-si-20261021 · OpenSpec: the-thuc-thuy-si

## Mục tiêu
App Flutter hỗ trợ thể thức Thụy Sĩ: nhãn và chọn thể thức, cấu hình (số vòng, tiebreak kéo sắp, ghép vòng 1), xem (bảng xếp hạng phẳng theo `rank` Backend, lịch trận theo vòng, BYE), và màn Ghép cặp vòng N cho BTC (máy đề xuất → nhấn giữ kéo hoặc chọn từ bảng chọn → xác nhận, hoàn tác). Backend và Web có change cùng tên, cùng hợp đồng (`design.md`).

## Trạng thái
Hoàn tất task 1.1–1.2; dừng trước 1.3 vì mâu thuẫn đặc tả ở map thể thức. Task 1.1: 21 test Swiss pass bằng `--no-test-assets` do thiếu asset `.env`; task 1.2: sinh l10n thành công, 70 khóa Swiss đủ và đồng nhất. Checkbox 1.1–1.2 đã đánh dấu; không sửa task 1.3.

## Đã thử: cách → kết quả → vì sao
- Tự tính Buchholz ở client → loại → lệch Backend; tin `rank` do Backend trả.
- Mỗi bàn là một `Card` có avatar → loại → người dùng yêu cầu phẳng, không khung lồng khung, ít icon.
- Dùng `lib/data/api_service.dart` → loại → file sinh, không được app import, bị ghi đè khi sinh lại.
- Nhét `roundConfig` vào `MatchModel` → loại → phình mô hình dùng chung; dùng `swissStageProvider` riêng.
- Kiểm kê 194 test cũ đã hoàn tất từ phiên trước; không lặp lại. Sau khi tiếp tục, task 1.1 đã xác nhận đỏ do ba file sản phẩm chưa tồn tại, rồi xanh với 21 test qua `flutter test --no-pub --no-test-assets ...`; bỏ qua bundling assets vì worktree không có `.env`.
- `app_constants.dart:126-150` định nghĩa các map thể thức; không có caller trong mã nguồn `lib/`. `TournamentCardV2` hiện dùng `l10n.bracketDisplayName` (`tournament_card_v2.dart:26`).
- Đã xác minh điều kiện quản lý trong `bracket_view_screen.dart` và API `updateDivisionConfig`; hai câu hỏi tương ứng ở handoff trước đã được giải quyết bằng code thật.
- Task 1.1: tạo `swiss.dart`, `swiss_round_state.dart`, `swiss_pairing_draft.dart`; bổ sung parser `fromJson` cho các DTO, request và ngoại lệ Swiss theo hợp đồng; test thuần chạy 21/21. `flutter analyze --no-pub lib/domain/entities lib/features/bracket/utils` không báo lỗi trong file mới, nhưng lệnh exit 1 vì info có sẵn tại `lib/domain/entities/tournament.dart:654` (`prefer_if_null_operators`).
- Task 1.2: thêm 70 khóa `swiss*` + tên thể thức Swiss vào hai ARB, chạy `flutter gen-l10n`; script scratchpad xác nhận 70/70 khóa khớp design và hai locale bằng nhau. File script tạm đã xóa.
- Ripwire `quality_delta` (HEAD `c13355c73` + dirty): `api-new-surface=0`, `sa=[]`; 173 `new-symbol` là DTO/hàm/khóa Swiss chưa được nối ở các task sau, 34 `preexisting-worse` là nền có sẵn. 28 finding gating đều thuộc `dead-code`/so trùng cấu trúc; `GroupStageConfig.moveParticipant` là hàm cũ, đã đọc và khác chữ ký/ngữ nghĩa với hàm Swiss. Các so trùng DTO, helper ngắn và chuỗi l10n giữ riêng theo contract; không thấy regression mới cần sửa.

## Ràng buộc đang có
- Agent KHÔNG push `main`; không `git add -A`.
- Worktree không có `.env`: không đọc/in/chép/tạo `.env`; `flutter test` chạy với `--no-test-assets` để không đóng gói asset không cần thiết.
- Mọi chuỗi qua `app_vi.arb` + `app_en.arb` rồi `flutter gen-l10n`; không sửa tay file sinh.
- Không thêm package. Test nặng/E2E chạy trên cloud (skill `cloud-test-runner`), không cục bộ.
- Hợp đồng Backend ở `design.md` KHÔNG đổi tùy tiện; cần đổi thì ghi "Câu hỏi còn mở" và báo người dùng.
- Chỉ đánh `- [x]` sau khi tiêu chí task pass.

## Ràng buộc thay đổi lần này
So với lần trước: đã hoàn thành task 1.1–1.2, thêm mã thực thể/hàm thuần và l10n 70 khóa, cập nhật checkbox tương ứng. Ràng buộc khác giữ nguyên; chưa đụng task 1.3 do mâu thuẫn hardcode và i18n.

## Câu hỏi còn mở
- Cần người dùng chốt task 1.3: `tasks.md:1` cấm hardcode chữ trong `.dart`, nhưng `tasks.md:17` yêu cầu thêm tên/mô tả/chi tiết tiếng Việt vào `AppConstants.bracketType*`. Các map hiện không có caller trong `lib/`; nhãn hiển thị dùng `bracketDisplayName`/l10n. Chọn: bỏ map entries để giữ i18n, hoặc cập nhật task để cho phép map lưu key l10n thay vì chữ hiển thị. Chưa sửa phần này.
- Chưa xác minh payload `/bracket` có `groupName`; thiết kế không phụ thuộc vì ưu tiên `stageType == 'SWISS'`.
- OpenSpec CLI `status`/`instructions apply` đã được thử nhưng không có JSON kết quả hiển thị trong runner; artifacts local đã đọc đầy đủ, plan không bị sửa.
