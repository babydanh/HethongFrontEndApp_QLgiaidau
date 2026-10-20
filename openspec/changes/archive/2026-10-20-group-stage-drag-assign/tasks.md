# Tasks

## 1. Mô hình và cấu hình

- [x] 1.1 Viết unit test đỏ cho resolver: fallback division/tournament/default, cấu hình null/sai dạng, ba/bốn nhóm, participant lẻ và lựa chọn luôn chứa số nhóm hiện tại; chạy `flutter test --no-pub test/features/group_stage_config_test.dart`.
- [x] 1.2 Thêm parse `TournamentDivision.roundConfig`, resolver và phép đổi số nhóm bảo toàn assignment; chạy lại `flutter test --no-pub test/features/group_stage_config_test.dart`.
- [x] 1.3 Thêm test PATCH với payload `isConfigOverride` và `roundConfig.groupsConfig` chính xác; chạy `flutter test --no-pub test/tournament_management_repository_api_test.dart`.

## 2. Màn phân bảng

- [x] 2.1 Viết widget test đỏ cho bốn nhóm đã lưu, đổi 4→2, kéo đội chưa xếp vào nhóm, kéo A→B có vị trí chèn, khóa trận đã bắt đầu và rollback khi PATCH lỗi; chạy `flutter test --no-pub test/features/group_stage_assignment_test.dart`.
- [x] 2.2 Thêm route quản trị và màn phân bảng responsive; hỗ trợ kéo-thả/auto-scroll/menu, khóa theo trạng thái trận, lưu PATCH, sinh lại sơ đồ chưa đấu, xử lý lỗi và invalidate provider; chạy lại `flutter test --no-pub test/features/group_stage_assignment_test.dart` ở chiều rộng 360px.
- [x] 2.3 Bổ sung key localization tiếng Việt/Anh cho màn phân bảng và entry point từ tab vòng bảng kể cả khi chưa có trận; chạy `flutter gen-l10n` và widget test liên quan.

## 3. Chọn division khi bốc thăm

- [x] 3.1 Viết widget test đỏ cho giải nhiều division: chưa chọn thì không gọi API, chọn division thì gửi đúng ID; chạy `flutter test --no-pub test/features/auto_draw_save_bracket_test.dart`.
- [x] 3.2 Truyền division đang chọn qua route và thêm bộ chọn tường minh khi chưa có division trong AutoDraw; chạy lại `flutter test --no-pub test/features/auto_draw_save_bracket_test.dart`.

## 4. Kiểm tra tích hợp

- [x] 4.1 Chạy `flutter analyze --no-pub` trên các thư mục Dart đã sửa và chạy toàn bộ test file liên quan: resolver, repository PATCH, màn phân bảng, AutoDraw và test bracket hiện có; sửa lỗi mới trước khi kết thúc.
  - Khôi phục từ session cloud (2026-10-20): `flutter analyze --no-pub lib/features/bracket lib/core/router lib/domain/entities` chỉ còn 1 info có sẵn (`tournament.dart:654`, change không đụng); 5 file test mục tiêu 80/80 (`--no-test-assets`, máy không có `.env`); bộ đầy đủ trên cloud-test-runner `--target app` run 39355714396 success.
- [x] 4.2 Chạy `openspec validate --change group-stage-drag-assign --strict`, kiểm tra các checkbox task đã hoàn tất và xác minh artifact archive giữ nguyên capability hiện có.
  - Strict pass sau khi giữ lại kịch bản "Giải nhiều nội dung thiếu nội dung" trong khối MODIFIED.

## Workflow follow-up

- Archive change sau khi kiểm tra strict và các test liên quan đạt.
- Gộp từ worktree `khoi-phuc-issue-19` qua `merge-lane.py`; không push thẳng `main`.
