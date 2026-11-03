## Phân loại

Bounded: đổi một luồng đã có (hub quản lý), không đổi hợp đồng API. Làm tuần tự trong một worktree vì các task cùng chạm `tournament_management_hub_screen.dart` và hai file arb (không chia agent song song).

## Hiện trạng đã đọc (Web `origin/main`, App `e39f1f84`)

| Nội dung | Web | App |
|---|---|---|
| Tab Kết quả | `?tab=results`, `ResultsBoard` (`manage/components/operations/ResultsBoard.tsx`): 7 chip lọc, ô tìm, "Tới vòng", hộp theo vòng gập được, nhập điểm ngay trên dòng | Chưa có trong hub. `ResultsMatchBoard` (579 dòng) đã cùng khuôn nhưng chỉ có 4 chip, dùng ở `LiveTab` của màn công khai |
| Dữ liệu trận | `GET /tournaments/:id/manage/matches?activeStageOnly=true` | `_fetchManagedByTournament` gọi đúng endpoint này; `matchesProvider` gọi qua `watchByTournament` (điều kiện chọn nguồn quản lý sẽ xác nhận ở task 1.2) |
| Thanh tiến trình | `TournamentStepper`, 4 bước, bấm mở `StepDetailDialog` | `LifecycleStepBar(status)`: không bấm được |
| Số liệu từng bước | `buildStepSummary` (~970 dòng TS, tính ở client từ giải, nội dung, VĐV, trận) | Chưa có. Có sẵn `TournamentEndChecklist` (chỉ cho bước kết thúc) |
| Khung popup | `StepDetailDialog` | `TournamentEditSheet` + `showTournamentEditPopup` (đã vào main) |

## Quyết định

**D1. Tab Kết quả dùng lại `ResultsMatchBoard` (chọn).** Mở rộng bộ lọc và thêm tham số `initialFilter`, bọc trong tab mới ở hub. Phương án loại: viết bảng mới (trùng 579 dòng), hoặc dùng `LiveTab` (hướng người xem, không có quyền quản lý).

**D2. Số liệu bước là hàm thuần Dart `buildStepSummary` (chọn).** Không gọi endpoint mới; nhận giải, nội dung, VĐV (`getOrganizerParticipants`), trận (`matchesProvider`) và giờ hiện tại, trả `StepSummary`. Hàm thuần nên test được từng luật. Phương án loại: để Backend tính (đổi hợp đồng, ngoài phạm vi); nhét logic vào widget (không test được).

**D3. Popup dùng `TournamentEditSheet` (chọn).** Cùng khung với popup Tổng quan đã có, đúng yêu cầu "popup chung". Phương án loại: dialog giữa màn (không đồng bộ với popup hiện có).

**D4. "Đi tới" là một giá trị `StepTarget`, hub tự điều hướng (chọn).** Popup không biết cấu trúc hub, chỉ trả `StepTarget { hubTab, resultsFilter?, divisionId? }`; hub đổi tab và đặt bộ lọc. Phương án loại: popup tự gọi `TabController` (khóa chặt vào hub).

## Chuỗi hiển thị

Lấy từ Web `messages/vi.json`: `OrganizerManage.resultsBoard.*` và `OrganizerTournamentStepper.*` (gồm `summary.*`). Key App đặt theo mẫu hiện có: `tournamentManagementTabResults`, `resultsBoard_*`, `stepPopup_*`, `stepSummary_*`. Tên chính xác chốt ở task 0.1, vi là template, en bắt buộc có đủ.

## Rủi ro và kiểm soát

- Luật "Trễ giờ", "Tranh chấp", "Thiếu nội dung" lệch Web: mỗi luật có test đối chiếu số liệu Web (`results.ts`, `tournament-step-summary*.ts`).
- Hub đã dài (trên 1000 dòng): chỉ thêm đúng 3 điểm (enum, `Tab`, `TabBarView`) và một hàm `_goTo(StepTarget)`; không dọn code lân cận.
- Mạng rớt / dữ liệu null: popup hiện "Đang tải số liệu" hoặc nút "Tải lại" như Web; trận hoặc VĐV rỗng cho ra số 0, không lỗi.
