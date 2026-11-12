# Handoff social-nut-bam-diem (App)

## Đã làm
- `social_match_tab.dart`: sau khi tạo trận, hộp thoại kết quả truyền `showScoreboardAction` theo cùng điều kiện với chạm thẻ (`_canScoreStatus`: chưa COMPLETED và đã đăng nhập); chọn "Mở bảng điểm" thì mở thẳng bảng bấm điểm live của trận vừa tạo.
- Thẻ trận có lại nút "Bấm điểm" (icon scoreboard, cao 44, một dòng không tràn ở 360px) khi trận chưa COMPLETED và đã đăng nhập; mở thẳng `OfficialScorePage`, có cờ chống bấm đúp. Chạm thẻ vẫn mở hộp thoại kết quả.
- i18n: key mới `social_matchScoreNow` ở `app_vi.arb` ("Bấm điểm") và `app_en.arb` ("Score live"), đã `flutter gen-l10n`.
- Test: thêm TC-SOCIAL-SCORE-01..07 trong `test/features/social/social_match_tab_test.dart`; TC-SOC-CARD-02 bỏ khẳng định "thẻ không có nút" (chỉ còn không có "Nhập nhanh"/OutlinedButton); TC-SOCIAL-APP-11 (integration) đổi thành thẻ có đúng một nút "Bấm điểm". Thêm tham số `@visibleForTesting createMatchLauncher` để test luồng sau khi tạo trận.
- Cần `.env` để chạy test: đã tạo từ `.env.example` (gitignored, không commit).

## Test (chạy thật)
- `flutter test --no-pub test/features/social/social_match_tab_test.dart`: đỏ trước (4 test fail: 01, 02, 05, 06), sau đó 23 pass, exit 0.
- `flutter test --no-pub test/features/social test/features/community`: 89 pass, exit 0.
- `flutter analyze --no-pub lib/features/social`: No issues found. `flutter analyze --no-pub integration_test/social_run_journey_test.dart`: No issues found.
- `openspec validate social-nut-bam-diem --strict`: exit 0.

## Còn thiếu
- Chưa chạy integration test TC-SOCIAL-APP-11 trên emulator (chỉ chạy cloud).
- Quyền không đổi: Backend là chốt (MATCH_SCORE_PERMISSION_REQUIRED hiện trong bảng bấm điểm); nút hiện cho mọi người đã đăng nhập.
- Comment cũ trong `club_standalone_match_result_dialog.dart` (nói Social đặt `false`) đã lỗi thời, chưa sửa vì ngoài phạm vi.
