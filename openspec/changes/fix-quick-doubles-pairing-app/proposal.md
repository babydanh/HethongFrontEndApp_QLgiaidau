# Đề xuất: sửa ghép đôi, sơ đồ và tạo giải nhanh (App)

## Vì sao

BTC giải pickleball/cầu lông báo: tạo giải nhanh vào là ra đánh đôi nhưng không ghép được ai; không ghép được VĐV khách; không tạo được sơ đồ đôi; ghép ngẫu nhiên lỗi; thêm VĐV thì bị khoá giới tính. Đã đối chiếu code App (worktree từ `origin/main` `b9e2367`):

1. Giải nhanh mặc định nội dung `MALE_DOUBLES` và gửi `genderRestriction: MALE` cấp giải (`create_public_quick_tournament_screen.dart:175-181`, `quick_tournament_format_mapping.dart:20-26`). Đôi nam nữ và bóng đá gửi `format: doubles` (`quick_tournament_format_mapping.dart:23`), sai hợp đồng.
2. Màn ghép cặp chỉ coi là chờ ghép khi `PENDING_PARTNER` và có đúng một dòng `rosters` (`lite_management_notifier.dart:58-61`). Khách do BTC thêm không có dòng `rosters` và backend ghi `PENDING_APPROVAL` (`tournament-import.repository.ts:1041`), nên khách không nằm trong danh sách chờ lẫn danh sách đã ghép: BTC không ghép được khách.
3. "Lưu sơ đồ" từ bốc thăm gọi `createBatch`, luôn ném `UnimplementedError` (`api_match_repository.dart:94-99`, gọi từ `publish_tournament_draw_use_case.dart:16`). Thông báo lỗi dùng `e.toString` thiếu `()` (`auto_draw_screen.dart:117`).
4. App coi `PUBLISHED`, `ACTIVE`, `OPEN`, `REGISTRATION`, `REGISTER_OPEN` và mọi chuỗi chứa `REGIST`/`OPEN` là "Đang mở đăng ký" (`status_helpers.dart:14-19,31-32`). Backend chỉ có 7 trạng thái (`update-tournament.dto.ts:12-17`).
5. Giải CLB: bóng đá và đôi nam nữ đều gửi `format: doubles` (`create_club_tournament_screen.dart:144-148`).
6. "Tạo sơ đồ" Lite không gửi `divisionId` và bỏ qua `unpairedNames`/`autoPaired` (`lite_pairing_screen.dart:593`).

## Thay đổi

- `quick-tournament-create`: mặc định "Đôi linh hoạt" không giới tính; ánh xạ `format` và `genderRestriction` đúng hợp đồng; giải CLB đúng `format` theo môn.
- `lite-pairing-visibility`: khách do BTC thêm hiện trong danh sách ghép (đếm thành viên như backend); "Tạo sơ đồ" Lite gửi `divisionId` khi có một nội dung và hiện người không ghép được.
- `bracket-draw-publish`: bỏ `createBatch` (cutover, không shim); lưu sơ đồ qua `POST /tournaments/:id/generate-bracket`; sửa `e.toString()`.
- `tournament-status-mapping`: chỉ `REGISTRATION_OPEN` là đang mở đăng ký; bỏ suy đoán theo chuỗi con.

## Quyết định

- D1 (chốt cuối, người dùng): giải nhanh luôn ra "Đôi linh hoạt" (DOUBLES, không giới tính). Không thêm nút chọn Đơn/Đôi. Tên lấy từ key có sẵn `tournamentCategoryOpenDoubles` ("Đôi linh hoạt"), không đổi chữ.
- Diễn giải "luôn": áp dụng cho mặc định. Nút thêm nội dung thủ công hiện có được giữ để BTC chọn tường minh nội dung khác; đó không phải mặc định.
- Mặc định bóng đá giữ `FOOTBALL_MALE`: App không có nội dung bóng đá không giới tính. Đây là câu hỏi mở, không tự đổi.
- D3, D5: App không thêm kiểm giới tính và không gửi cờ phí. Đã kiểm `add_athlete_sheet.dart`, `roster_excel_parser.dart`, `api_tournament_management_repository.dart:281-299`: không có kiểm giới tính nào; body thêm trực tiếp chỉ có `name`, `email`, `tournamentDivisionId`.
- D2: App hiển thị `unpairedNames` và `autoPaired` khi backend trả; thiếu trường thì bỏ qua.

## Phụ thuộc Backend (lane khác)

App chịu được mọi trường thiếu. Các hành vi sau cần backend, không làm trong lane này:

1. `POST /tournaments/lite` thiếu `format` → `doubles`; giải không giới tính đặt tên "Đôi linh hoạt" (hiện giải CLB không gửi nội dung nên backend đặt "Đánh Đôi").
2. `POST /tournaments/:id/add-athletes/direct` của BTC: `teamStatus` = `PENDING_PARTNER`, đánh dấu đã đóng phí (D3). Hiện là `PENDING_APPROVAL` (`tournament-import.repository.ts:1041`). Nếu chưa đổi, khách vẫn không hiện trong ghép cặp dù App đã sửa.
3. `POST /tournaments/lite/:id/bracket` nhận `divisionId?`, trả `autoPaired?` và `unpairedNames?`.
4. `POST /tournaments/:id/generate-bracket` nhận `{divisionId, seedingType, allowReset}`, `allowReset` mặc định `false`.

## Ngoài phạm vi

- Form tạo nội dung thủ công phía Web (`MALE_DOUBLES` mặc định): lane WebFlow.
- Ghép ngẫu nhiên `POST /pairs/generate`: giữ nguyên hành vi.
- Ràng buộc giới tính của VĐV tự đăng ký: giữ nguyên.
- Đã kiểm trên App: không có kiểm giới tính trên luồng BTC thêm/ghép/Excel; không cần đổi.

## Câu hỏi mở

- Mặc định nội dung bóng đá (xem trên).
- Giải Lite nhiều nội dung: App không gửi `divisionId` và để backend trả lỗi; chưa có bộ chọn nội dung trên màn ghép cặp.
- Kiểm thử: worktree không có `.dart_tool` và `.env`; không chạy được `flutter test` cục bộ. Ghi rõ trong báo cáo.
