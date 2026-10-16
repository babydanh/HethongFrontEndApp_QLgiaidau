# Kế hoạch test

Cột "Kết quả" ghi kết quả đã quan sát. Mục chưa chạy được ghi rõ lý do.

## Parser Excel (P1) — `test/features/organizer_ops/roster_excel_parser_test.dart`
- Header tiếng Việt và tiếng Anh nhận đúng cột.
- Sheet có dòng tiêu đề phụ phía trên → tìm đúng header row (quét tối đa 10 dòng).
- Dòng trống (name/team/email/phone đều rỗng) bị bỏ; `sourceRowIndex` đúng.
- Thiếu cả tên lẫn email → `MISSING_NAME`; thiếu email → `MISSING_EMAIL`; email sai → `INVALID_EMAIL`.
- Trùng email trong file → `DUPLICATE_IN_FILE`.
- Elo "1,250" → 1250; "12.5" → 12.5; chuỗi không phải số → null.
- Một cột không gán cho hai slot.
- Cột `notes` (Ghi chú) đọc vào `RosterParsedRow.notes`.
- Kết quả: 20/20 pass ở lần chạy đầu. Thêm 1 test `Notes` tiếng Anh; cả nhóm 3 file: 111/111 pass. Chưa có pha RED riêng (test và code viết cùng lượt).

## Repository — `test/tournament_management_repository_api_test.dart`
- Idempotency key: cùng body → cùng key; body khác → key khác; key có dạng `roster:<id>:<sha256>`.
- Commit gửi `teamName`, `sourceRowIndex`, `sourceSheetName` theo đúng wire.
- `addAthleteDirect` gửi `email` khi có.
- `searchAddAthleteCandidates` parse `items`; `addAthletePairs` parse `pairs`.
- Kết quả: 45/45 pass ở lần chạy đầu. Thêm test `customResponses.notes` (chỉ dòng có ghi chú mới gửi khóa này; dòng trống không có khóa); cả nhóm 3 file: 111/111 pass. Implementation có trước test, không có pha RED.

## Thêm VĐV (P3) — `test/organizer_ops/add_athlete_entry_test.dart`, `test/features/tournament_management_hub_screen_test.dart`
- Cập nhật fake có tham số `email` và `divisionMatchType`.
- Kết quả: nằm trong nhóm 81/81 pass (6 file gộp). Chưa có test UI mới cho nhánh tìm theo email và cặp đôi; kiểm bằng analyze và đọc code, chưa chạy trên máy.
- Hub (test mới): hàng VĐV mở ra có `athletes-import-excel` và `athletes-download-template`; bấm Nhập Excel mở sheet có tiêu đề `rosterImportTitle`. Cả nhóm 3 file: 111/111 pass.

## Overlay pan (P4)
- Không có widget test khả thi mà không refactor lớn (`_buildBracketOverlay` là method private trong `State` cần provider).
- Kiểm bằng probe tạm trên bản sao cấu hình: cấu hình mới pan được (translation.x < -50), cấu hình có scroll lồng không pan (≈ 0). Probe đã xoá.
- **Chưa chứng minh trên màn hình thật.** Cần user kiểm: `INJECT_EVENTS` bị từ chối trên `aa785b1a`.

## Live overlay và live score (hồi quy)
- `test/features/match/live_overlay_controls_test.dart`: 11/11 pass.
- `test/match/live_score_no_fake_elo_test.dart`: 2/2 pass.
- `test/match/live_score_member_profile_link_test.dart`: 1/1 pass.
- `test/features/live_overlay_short_name_test.dart`: 8/8 pass.

## Lệnh đã chạy
- `dart analyze <file>` cho các file đã sửa: không có lỗi. 1 warning và 2 info đều có sẵn hoặc nằm ngoài phần email (xem `12-release-evidence.md`).
- `flutter test --no-pub --concurrency=1 <file>`: từng file, sau đó nhóm liên quan.
- `flutter build apk --debug --no-pub`: thành công (xem `12-release-evidence.md`).

## Chưa có
- Kiểm trên máy: luồng nhập Excel, thêm VĐV theo email và cặp đôi, pan sơ đồ nhánh đấu.
- Test RED cho parser và repository: không có log, test viết cùng code.
