# Handoff — phu-test-app

## Mục tiêu
Phủ lại test cho App Flutter theo độ phủ đo được, chỉ thêm/sửa test và tài liệu OpenSpec; không sửa code production.

## Trạng thái
- Nhánh `cloud/danh3-phu-test-app`, đã commit hẹp (không `git add .`, không Co-Authored-By).
- Đo nền: 55,06% (54076/98206 dòng, loại file sinh). 3653 test xanh trước khi thêm.
- Đã thêm ~420 test mới trong 19 file (T1–T8 trong `tasks.md`), mỗi file chạy xanh riêng; `dart analyze` các file test đã thêm: no issues; `dart format` đã áp dụng.
- `openspec validate phu-test-app --strict`: pass (kiểm bên dưới).
- **Chưa làm**: đo lại độ phủ toàn repo (bị dừng vì thiếu RAM), mở PR, `cloud-xong phu-test-app`. Chưa chạy lại toàn bộ bộ test sau khi thêm (chỉ từng file mới); phần test cũ không bị sửa, chỉ `test/support/fake_api_adapter.dart` được mở rộng tương thích ngược (thêm `query`, `headers`, `FakeReply.networkError`).
- Findings nghi bug (không sửa production, test bỏ qua): F1–F5 trong `findings.md`.
- Reviewer `flutter-reviewer`: không P0/P1; đã sửa P2 `throwsA(anything)` và các mục format/lint.

## Đã thử (cách → kết quả → vì sao)
Kiểm "đỏ khi phá hành vi": sửa tạm file production bằng `sed`, chạy test, rồi `git checkout -- <file>` đúng file đó.
| Nhóm | File production phá thử | Test đỏ |
|---|---|---|
| T1 community repo | api_community_repository | 3 |
| T2 community social | api_community_social_repository | 4 |
| T3 team repo | api_team_repository | 3 |
| T4 social session repo / model | api_social_session_repository / social_session_model | 5 / 4 |
| T5 tournament repo | api_tournament_repository | 6 và 2 |
| T6 match repo | api_match_repository | 5 |
| T7 social_provider / lite notifier | social_provider / lite_management_notifier | 3 / 4 |
| score_validator | score_validator | 5 |
| user/ranking/auth/token repo | 4 file repo | 9 |
| vietnam_address_parser | vietnam_address_parser | 6 |
| user entities / elo log | user.dart, elo_history_log | 5 |
| club match session repo | api_club_match_session_repository | 4 |
Lần phá hỏng biên dịch (social_provider, lần đầu) đã làm lại bằng mutation hợp lệ.
- Lần đo nền đầu thất bại do worktree chưa `pub get` → chạy `cloud-flutter pub get` rồi đo lại, xanh.
- Test 401 bị interceptor refresh token của `DioClient` chặn (không phải logic repo) → dùng 400 cho case đó.
- `score_panel_notifier` bỏ qua có chủ ý: đã dày test, phần hổng là sync/timer, rủi ro flaky.

## Ràng buộc
- Máy 8 GB RAM, đĩa /data còn ~4,1 GB; mọi lệnh nặng qua `flock /tmp/qlgd-heavy.lock`.
- Không chạy integration_test/E2E trên máy này.
- Không commit thay đổi tự sinh ở `linux/`, `macos/`, `windows/` (không có thay đổi nào).

## Câu hỏi mở
1. Cho phép chạy lại phép đo độ phủ (có thể `-j 1` hoặc chia nhỏ theo thư mục) để hoàn tất `coverage-after.md`, rồi mở PR?
2. F3 (set 30-29 cầu lông bị `validateRallyPointSet` từ chối) và F4/F5 cần người xác nhận có phải bug.
