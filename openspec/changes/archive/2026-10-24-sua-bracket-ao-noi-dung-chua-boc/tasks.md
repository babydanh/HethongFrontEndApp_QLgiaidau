# Tasks

## 1. Truy vấn theo nội dung

- [x] 1.1 `ApiMatchRepository._fetchAllByTournament`: có `divisionId` thì gửi `strictDivisionScope=true`. Xong khi: `flutter test --no-pub test/data/api_match_repository_division_scope_test.dart` PASS (request có `divisionId` và `strictDivisionScope=true`).

## 2. Kiểm chứng

- [x] 2.1 Đo production: `/matches?tournamentId&divisionId&publicOnly=true&strictDivisionScope=true` trả 0 trận cho VNDC T4 "Đôi linh hoạt" (trước 15), VPSF "Đôi Nam" (trước 100), Vietcombank "Đơn nam trình cao" (trước 42); giải một nội dung bracket cũ (`adcf5102`, `51aa9d5d`) giữ nguyên số trận.
- [x] 2.2 `flutter analyze --no-pub` file sửa không lỗi; `flutter test --no-pub` các file `api_match_repository_*`, `api_match_schedule_repository_test.dart`, `tournament_bracket_inline_layout_test.dart` PASS.

## Workflow follow-up

- Smoke trên máy: giải VNDC T4 tab "Bảng đấu", mở "Đôi linh hoạt" thấy thông báo chưa có trận.
