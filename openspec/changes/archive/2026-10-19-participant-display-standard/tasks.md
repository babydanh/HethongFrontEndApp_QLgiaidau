## 1. Helper dùng chung và test

- [x] 1.1 Thêm `lib/core/participants/participant_display.dart` (ParticipantPlayer, toParticipantPlayers, resolveParticipantDisplay, abbreviateName, participantLabel, ParticipantLabel). Kiểm chứng: `flutter test --no-pub --no-test-assets test/core/participants/participant_display_test.dart` không có test lỗi.
- [x] 1.2 Test widget `ParticipantLabel` compact/full/TEAM/fallback/cắt chữ. Kiểm chứng: `flutter test --no-pub --no-test-assets test/core/participants/participant_label_test.dart` không có test lỗi.

## 2. Thẻ trận, bracket, lịch, overlay (chỗ hẹp viết tắt)

- [x] 2.1 Thẻ trận live, match card compact/detail/live, bracket, double-elim, bảng vòng tròn, lịch sân công khai và BTC, điều khiển tỉ số, overlay: dùng ParticipantLabel compact, bỏ tách tên. Kiểm chứng: `dart analyze` các file đã sửa không có lỗi hoặc cảnh báo mới so với origin/main.
- [x] 2.2 Xoá `overlay_team_name.dart` và `schedule_team_label.dart`, cùng test cũ của chúng. Kiểm chứng: không còn tham chiếu `shortTeamName`/`scheduleShortTeamName` trong `lib/` và `test/` (grep rỗng); `test/core/widgets/match_card_typography_overflow_test.dart` pass trong lượt chạy 110 file test liên quan.

## 3. Giải đấu, bảng xếp hạng, kết quả, Excel (chỗ rộng đầy đủ)

- [x] 3.1 Thẻ đội giải (`tournament_team_card.dart`): bỏ tách tên theo ký tự phân cách; đôi xác định bằng số VĐV. Kiểm chứng: `dart analyze` file đã sửa không có lỗi mới.
- [x] 3.2 Parser và entity (`api_team_repository.dart`, `api_match_repository.dart`, `api_tournament_repository.dart`, `Team`, `Standing`, `OrganizerOpsParticipant`, `PaymentModel`): bỏ nhãn fabricate, đọc `players`. Kiểm chứng: `flutter test --no-pub --no-test-assets test/models/team_test.dart test/models/standing_test.dart test/organizer_ops/organizer_ops_models_test.dart test/data/api_tournament_generate_bracket_test.dart` không có test lỗi.
- [x] 3.3 Bảng xếp hạng và standings: gom nhóm theo ID. Kiểm chứng: `test/features/public_bracket_view_test.dart` pass trong lượt chạy 110 file test liên quan.
- [x] 3.4 Kết quả và giải thưởng (`results_tab.dart`, `leaderboard_view.dart`): tên đầy đủ, không tổng hợp tên. Kiểm chứng: `dart analyze` file đã sửa không có lỗi mới.
- [x] 3.5 Excel (`core/services/excel_export_service.dart`): nhãn qua `matchSideLabel`/`participantLabel`, không còn hàm trùng. Kiểm chứng: `dart analyze` không có lỗi mới; `test/features/schedule_excel_matrix_test.dart` không có test lỗi. (Đường dẫn cũ `test/features/match/excel_export_service_test.dart` không tồn tại.)

## 4. Lite, đăng ký, nhập roster

- [x] 4.1 Ghép cặp Lite và bracket: nối ' / ', không gửi tên người làm `teamName`. Kiểm chứng: `flutter test --no-pub --no-test-assets test/core/utils/pair_generation_summary_test.dart test/core/utils/bracket_generation_summary_test.dart test/providers/lite_management_pairing_request_test.dart` không có test lỗi. `test/features/lite/lite_pairing_screen_request_test.dart`: 5 test pass, 1 test lỗi do thiếu shader asset môi trường (CHƯA xác minh).
- [x] 4.2 Đăng ký đôi, thêm VĐV, nhập roster: giữ `teamName` rỗng hợp lệ, không ghép tên người vào `teamName`. Kiểm chứng: `dart analyze` các file đã sửa không có lỗi mới.

## 5. Kiểm chứng cuối

- [x] 5.1 `dart analyze` trên 60 file lib/test đã sửa hoặc mới: 0 lỗi mới. Còn 18 vấn đề, đối chiếu đều nằm ngoài hunk đã đổi, tức có sẵn từ origin/main.
- [x] 5.2 `flutter test --no-pub` trên 110 file test import file `lib/` đã đổi (2026-10-19, `.env` mẫu từ `.env.example`, đã xoá sau khi chạy): 741 pass, 2 fail do kỳ vọng kiểu viết tắt cũ; sau khi sửa 2 test đó (`live_score_header_scoring_test.dart`, `tournament_schedule_tab_test.dart`): 30/30 pass.
- [x] 5.3 `openspec validate participant-display-standard --strict` pass.
