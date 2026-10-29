## Why

Popup "Thêm VĐV" của App thua Web: header có dòng mô tả và tên giải thừa, form nhập tay chỉ có tên và email (Web còn SĐT, điểm + loại điểm, ghi chú), và chỉ thêm được từng người một (Web có hàng chờ "Thêm vào danh sách" rồi thêm cả loạt). Backend `POST /tournaments/:id/add-athletes/direct` đã nhận đủ `phone`, `notes`, `elo` + `eloSource` nhưng App không gửi.

## What Changes

- Header chỉ còn tiêu đề "Thêm VĐV" (bỏ dòng mô tả và dòng tên giải · nội dung).
- Form tab "Nhập tên": thêm SĐT, Điểm, Loại điểm (ELO/DUPR), Ghi chú; gửi đúng tên trường của Backend.
- Tab "Nhập tên" có hàng chờ: nút "Thêm vào danh sách" đưa người đang nhập vào hàng chờ (mới nhất nằm trên cùng, chặn trùng email), nút xoá từng dòng; nút chính "Thêm (N)" gửi tuần tự từng người, dòng lỗi giữ lại kèm lý do.
- `addAthleteDirect` nhận thêm `phone`, `notes`, `elo`, `eloSource`.

## Out of scope

- Backend và hợp đồng API (đã đủ trường).
- "Thêm lên đầu danh sách giải": Backend không có trường vị trí, Web cũng không có; cần Backend nếu muốn.
- Hàng chờ chung giữa tab "Bạn bè & CLB" và "Nhập tên" (tab Bạn bè & CLB vốn đã chọn nhiều).
- Suy tên từ email khi bỏ trống tên (App vẫn bắt buộc nhập tên).

## Capabilities

### New Capabilities
- `add-athlete-multi`: header gọn, form đủ trường theo Backend, thêm nhiều VĐV nhập tay qua hàng chờ.

### Modified Capabilities
(không)

## Impact

- `lib/features/organizer_ops/screens/add_athlete_sheet.dart`
- `lib/domain/repositories/tournament_management_repository.dart`, `lib/data/repositories/api/api_tournament_management_repository.dart`
- `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb` (+ file sinh)
- `test/organizer_ops/add_athlete_entry_test.dart`, `test/features/tournament_management_hub_screen_test.dart` (fake repo), `test/tournament_management_repository_api_test.dart`
