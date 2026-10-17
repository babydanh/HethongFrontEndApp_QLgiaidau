## 1. Đối chiếu trước khi sửa

- [x] 1.1 Chạy `git -C <worktree> grep -n "createBatch\|isPending\|REGISTER_OPEN\|e.toString)" -- lib` và đối chiếu với bằng chứng trong proposal. Xong khi: mỗi điểm còn đúng ở `b9e2367`; điểm nào đã lệch thì ghi lại và dừng để hỏi.
- [x] 1.2 Đọc `HethongBackendApi_QuanlyGiaiDau/src/modules/tournaments/dto/roster-import.dto.ts` (`IMPORT_SOURCES`) và chép đúng danh sách vào App. Xong khi: danh sách App khớp từng phần tử với backend. (Đã chép: `MANUAL_EMAIL`, `EXCEL`, `AI_EXCEL`, `GOOGLE_FORM` + `ORGANIZER_DIRECT`.)
- [x] 1.3 Đọc `auto_draw_screen.dart` để xác định `seedingType` và `divisionId`. Xong khi: ghi được giá trị sẽ gửi, hoặc ghi rõ thiếu nguồn. (Màn không có seeding; đã chọn `RANDOM`, `divisionId` = nội dung duy nhất. Ghi trong design.md.)

## 2. Test đỏ trước khi sửa

Trạng thái: đã chạy `flutter test --no-pub` trên 14 file liên quan (mục 4.3): 130/130 xanh. Tiêu chí "đỏ trước khi sửa" trên code cũ CHƯA được chạy; ghi rõ ở từng mục.

- [x] 2.1 Cập nhật `test/features/quick_tournament_format_mapping_test.dart`: `MIXED_DOUBLES` → `mixed_doubles`; `FOOTBALL_*` → `singles`; `MALE_*` không còn `genderRestriction` cấp giải; `OPEN_DOUBLES` → `{format: doubles}`. Xong khi: các test này đỏ trên code cũ (ghi rõ test nào đỏ và vì sao). Test khẳng định hành vi sai cũ được sửa, không xoá. (Xanh khi chạy; đỏ trên code cũ CHƯA kiểm chứng.)
- [x] 2.2 Thêm `test/features/lite_participant_pairing_test.dart`: khách `ORGANIZER_DIRECT` `PENDING_PARTNER` không roster → `isPending`; khách `EXCEL` có `player2Name` → `memberCount` 2; VĐV tự đăng ký một roster không đổi; `PENDING_APPROVAL` không `isPending`. Xong khi: đỏ trên code cũ. (Xanh khi chạy; đỏ trên code cũ CHƯA kiểm chứng.)
- [x] 2.3 Thêm `test/core/utils/status_helpers_registration_test.dart`: `REGISTRATION_OPEN` là mở; `PUBLISHED`, `ACTIVE`, `OPEN`, `REGISTRATION`, `REGISTER_OPEN` không là mở; `MY_OPEN_THING` không là mở và nhãn là nguyên văn; null → upcoming. Xong khi: đỏ trên code cũ. (Xanh khi chạy. Lỗi thật đã sửa: `REGISTRATION` từng thành `registration` trùng mã đang mở; nay thành `raw_registration`. Đỏ trên code cũ CHƯA kiểm chứng.)
- [x] 2.4 Thêm test repository `generateBracket` bằng `HttpClientAdapter` giả: đường dẫn, body `{divisionId, seedingType, allowReset: false}`, parse `autoPaired`/`unpairedNames`, thiếu trường → rỗng, 400 → ném lỗi. Xong khi: đỏ (method chưa có). (Đã viết `test/data/api_tournament_generate_bracket_test.dart`: 3/3 xanh; đỏ-trước-sửa CHƯA kiểm chứng.)
- [x] 2.5 Thêm test cho CLB: `resolveClubFormat` football → `singles`, `mixed_doubles` giữ nguyên. Xong khi: đỏ trên code cũ. (Đã viết `test/features/club_format_resolution_test.dart`; xanh khi chạy; đỏ trên code cũ CHƯA kiểm chứng.)
- [x] 2.6 Thêm test hàm thuần `unpairedDisplayNames(ids, namesById)` cho ghép ngẫu nhiên: id có tên → tên; id thiếu → `#<id>`; rỗng → không có dòng nào. Xong khi: đỏ (hàm chưa có). (Tên hàm thực tế là `unpairedDisplayNames`; case id có tên/thiếu tên và case rỗng `unpairedDisplayNames([], {})` đã có trong `lite_participant_pairing_test.dart`; xanh khi chạy.)

## 3. Sửa tối thiểu cho xanh

Ghi chú: mục 3.x đánh dấu khi code đã sửa. Xác nhận test xanh thuộc mục 4.3 và CHƯA chạy.

- [x] 3.1 `quick_tournament_format_mapping.dart`: đổi `format` và `matchType` theo bảng trong spec; `genderRestriction` cấp giải chỉ cho `MIXED`. Xong khi: test 2.1 xanh.
- [x] 3.2 `create_public_quick_tournament_screen.dart`: `_contentDrafts` mặc định `OPEN_DOUBLES`; dải nút chọn nội dung mặc định của môn vợt là `OPEN_DOUBLES`, `MIXED_DOUBLES`; payload không lấy `genderRestriction` cấp giải từ `MALE`/`FEMALE`. Không thêm nút chọn Đơn/Đôi. Xong khi: không còn `MALE_DOUBLES` làm mặc định trong file này (chỉ còn trong danh sách lựa chọn và nhãn).
- [x] 3.3 `create_club_tournament_screen.dart`: hàm thuần `resolveClubFormat`; `_submit` dùng để gán `resolvedFormat`. Xong khi: test 2.5 xanh.
- [x] 3.4 `lite_management_notifier.dart`: thêm `customResponses` vào `LiteParticipant`, getter `memberCount`, `isPending` và `isComplete` dùng `memberCount`, hằng số nhóm nhập của BTC. Xong khi: test 2.2 xanh.
- [x] 3.5 `lite_pairing_screen.dart` `_generateBracket`: gửi `{divisionId}` khi đúng một nội dung; đọc `unpairedNames`/`autoPaired` qua `bracket_generation_summary.dart`; hiện danh sách tên. Xong khi: không còn `dio.post(...bracket')` không body khi có đúng một nội dung.
- [x] 3.6 `lite_pairing_screen.dart` `_generatePairs`: thông báo người lẻ có tên (`unpairedDisplayNames`). Xong khi: snackbar có tên người lẻ thay vì chỉ số lượng. (Dùng khoá `lite_autoPairSuccessOdd` sẵn có, nối tên; không thêm khoá vì không chạy được gen-l10n.)
- [x] 3.7 `status_helpers.dart`: bỏ alias và nhánh chuỗi con theo spec; `getTournamentStatusLabel` trả nguyên văn cho giá trị lạ. Xong khi: test 2.3 xanh.
- [x] 3.8 Thêm `generateBracket` vào `ITournamentRepository` và triển khai API; `auto_draw_screen` gọi nó qua `_saveBracket`; xoá `createBatch` khỏi `IMatchRepository`, `ApiMatchRepository`, `PublishTournamentDrawUseCase` (đã xoá file và provider); `e.toString` đã thành `_errorText(e)`. Xong khi: test 2.4 xanh (3/3 khi chạy).
- [x] 3.9 Khoá i18n: không thêm khoá mới; `git diff -- lib/l10n` rỗng. Change tái dùng `lite_autoPairSuccess`, `lite_autoPairSuccessOdd`, `lite_bracketCreated`, `autoDraw_saved`, `autoDraw_error`.

## 4. Kiểm tra và đối chiếu

- [x] 4.1 Kiểm tra không kiểm giới tính trên luồng BTC: `grep -rn "genderRestriction\|gender" lib/features/organizer_ops lib/features/lite lib/data/repositories/api/api_tournament_management_repository.dart` không có kiểm chặn nào phía App. Xong khi: kết quả được ghi trong báo cáo. (Kết quả: organizer_ops, api mgmt repo, tab VĐV không có `gender`; lite chỉ suy ra kiểu hiển thị `MIXED_DOUBLES` từ `genderRestriction`, không chặn/lọc VĐV.)
- [x] 4.2 `flutter analyze --no-pub lib test` đã chạy LOCAL sau `pub get` (không chờ cloud): 0 error; 110 warning + 83 info toàn repo. Trong các file đã sửa chỉ có 1 warning (`tournament_management_hub_screen_test.dart` `iconRect` không dùng), có sẵn từ `b9e2367`. Xong khi: có kết quả thật.
- [x] 4.3 `flutter test --no-pub` 14 file mới/sửa + liên quan (lite, auto draw qua fake, CLB, quản lý giải): **130/130 xanh**, exit 0, chạy local sau `pub get`. Xong khi: có kết quả thật.
- [x] 4.4 `npx -y openspec validate fix-quick-doubles-pairing-app --strict`: "is valid", exit 0 (đã tách requirement dài trong `specs/lite-pairing-visibility/spec.md`). Xong khi: không lỗi.
