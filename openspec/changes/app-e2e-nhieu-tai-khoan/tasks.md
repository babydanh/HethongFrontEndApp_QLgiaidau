## 0. Allure cho E2E App (repo `babydanh/agent-orchestrator`, độc lập với nhóm 1–2)

- [ ] 0.1 Script đổi JSON của `flutter test --reporter json` ra `allure-results`. Tiêu chí: `python -m pytest scripts/e2e/test_flutter_json_to_allure.py` → exit 0
  - Files: tạo `scripts/e2e/flutter_json_to_allure.py`, `scripts/e2e/test_flutter_json_to_allure.py` (fixture JSON giả có 1 ca đạt, 1 ca đỏ, 1 ca skip, 1 dòng `[[SHOT ...]]`)
  - Giao: `python3 scripts/e2e/flutter_json_to_allure.py <flutter-test.json> <allure-results-dir>`: mỗi ca (bỏ ca `hidden` và ca loading của file) một `<uuid>-result.json` có `name`, `fullName`, `status` (passed|failed|broken|skipped), `statusDetails.message/trace`, `start`/`stop`, nhãn `suite`=file, `story`=mã TC đầu tên ca nếu có; mỗi `[[SHOT name]]<base64>` thành file PNG `<uuid>-attachment.png` và mục `attachments`. Exit 0 kể cả khi có ca đỏ; exit 2 khi file vào không đọc được
  - Phụ thuộc: không. TDD: test đỏ trước
- [ ] 0.2 Sửa job `test-app-e2e` trong `.github/workflows/test-runner.yml`. Tiêu chí: lượt `cloud-test-runner.py run --target app-e2e --specs integration_test/smoke_test.dart` (dispatch bằng `--ref <nhánh orchestrator>`) xong, và `cloud-test-runner.py ds --project qlgd-app-e2e` có lượt đó; `xem <run_id>` mở được, thấy ảnh trong ca
  - Files: sửa `.github/workflows/test-runner.yml` (chỉ job `test-app-e2e`)
  - Việc: chạy thêm `--reporter json` (ghi `app-e2e-report/flutter-test.json`) mà vẫn giữ log chữ `flutter-test.log` và dòng `Tests: ...` mà `cloud-test-runner.py` đọc; bước `if: always()` đổi JSON → `allure-results` → `npx --yes allure-commandline@2.46.1 generate` → `allure_archive.py publish --project qlgd-app-e2e` (`GH_TOKEN: ${{ secrets.GH_PAT }}`, `continue-on-error: true`), làm giống các bước Web dòng ~440–540. KHÔNG thêm `upload-artifact` cho Allure/ảnh/JSON; artifact công khai sẵn có không được chứa `flutter-test.json` hay ảnh
  - Kiểm `cloud-test-runner.py` (`~/.omp/scripts`, máy local) có nhận `--project qlgd-app-e2e` ở `ds`/`xem` không; thiếu thì ghi vào handoff, không tự sửa
  - Phụ thuộc: sau 0.1. Gộp: PR vào `main` orchestrator (repo không có deploy), rồi các lượt app-e2e sau dùng `main`

## 1. Hợp đồng chung (phiên chính, Opus)

- [ ] 1.1 Tạo `actors.dart` và mở rộng `backend_api.dart`. Tiêu chí: `flutter analyze --no-pub integration_test/support` → exit 0
  - Files: tạo `integration_test/support/actors.dart`; sửa `integration_test/support/backend_api.dart` (thêm hàm cuối class `BackendApi`); sửa `integration_test/support/social_journey.dart` (thay `signInAs` cục bộ bằng bản trong `actors.dart`)
  - Giao:
    - `class E2eActor { final String role; final String email; final String userId; final String token; }`
    - `Future<Map<String, E2eActor>> createActors(BackendApi api, {required String chain, required List<String> roles})`, trong đó `roles` thuộc `organizer|player|referee|coOrganizer|viewer|clubOwner|member`
    - `Future<void> signInAs(WidgetTester tester, E2eActor actor)`
    - `Future<void> expectBlocked(WidgetTester tester, String route)`
    - `Future<void> pumpUntil(WidgetTester tester, Finder finder, {Duration timeout})`
    - `BackendApi`: `addReferee(tournamentId, email)`, `respondReferee(tournamentId, refereeId, accept, token)`, `addStaff(tournamentId, email, role)`, `followTournament(id, token)`, `createCommunity(...)`, `joinCommunity(id, token)`, `reviewJoinRequest(id, memberId, approve)`, `inviteCommunityMember(id, userId)`, `sendChatMessage(roomId, text, token)`, `listNotifications(token)`, `inviteSeriesStaff(seriesId, email)`, `acceptSeriesInvitation(id, token)`
    - Endpoint đối chiếu với `~/.omp/api-map/QuanLyGiaiDau.md`: `/tournaments/:id/referees`, `/tournaments/:id/staff`, `/communities/:id/join|join-requests|invite`, `/chat/messages`, `/notifications`, `/organizer/series/:id/invitations`
  - Nhận: (không)
  - Chủ file chung: 1.1 giữ `backend_api.dart`, `actors.dart`, `social_journey.dart`. Task sau cần thêm hàm thì báo phiên chính, không tự sửa.
  - Phụ thuộc: không
- [ ] 1.2 Commit hợp đồng lên nhánh `app-e2e-nhieu-tai-khoan`. Tiêu chí: `git log -1 --stat` có đúng 3 file trên
  - Phụ thuộc: sau 1.1

## 2. Tám chuỗi hành trình (song song, mỗi chuỗi một worktree con, Sonnet)

Mỗi task: tạo đúng một file test; chỉ dùng hàm của 1.1; mỗi bước có `shot()`; có nhóm ca phân quyền âm. Tiêu chí của mỗi task:
- `flutter analyze --no-pub <file>` → exit 0
- `cloud-test-runner.py run --target app-e2e --app-ref <nhánh chuỗi> --specs <file>` → không có ca đỏ ngoài các ca `skip: 'BUG-...'`. Tối đa 3 vòng sửa.

- [ ] 2.1 Chuỗi A: trọng tài, đồng BTC, người xem live. Tiêu chí: như trên với `integration_test/multi_referee_live_journey_test.dart`
  - Files: tạo `integration_test/multi_referee_live_journey_test.dart` (TC-MULTI-A-01..20)
  - Giao: (không) · Nhận: toàn bộ `Giao` của 1.1
  - Ca chính: mời trọng tài → nhận lời mời (kiểm BUG-REF-01) → chấm → người xem thấy tỉ số live; mời đồng BTC → người nhận thấy giải trong dashboard và quản lý được; chat trận; xem lại; ADMIN mở trận (BUG-ADMIN-02)
  - Phụ thuộc: sau 1.2
- [ ] 2.2 Chuỗi B: VĐV đầy đủ. Tiêu chí: như trên với `integration_test/multi_player_journey_test.dart`
  - Files: tạo `integration_test/multi_player_journey_test.dart` (TC-MULTI-B-01..20)
  - Nhận: 1.1
  - Ca chính: đăng ký đơn, đôi, đội; mã mời `/join/:code`; `/join-team`; `/lite-join/:code`; theo dõi giải; thanh toán tới màn cổng; dashboard; sửa hồ sơ; đổi mật khẩu rồi đăng nhập lại; xếp hạng (dữ liệu seed); VĐV mở màn quản lý giải người khác (BUG-PERM-01)
  - Phụ thuộc: sau 1.2
- [ ] 2.3 Chuỗi C: CLB, chat, thông báo. Tiêu chí: như trên với `integration_test/multi_club_chat_notify_journey_test.dart`
  - Files: tạo `integration_test/multi_club_chat_notify_journey_test.dart` (TC-MULTI-C-01..20)
  - Nhận: 1.1
  - Ca chính: chủ tạo CLB → thành viên xin vào → chủ duyệt → thành viên nhận thông báo; mời thành viên; chat CLB hai chiều; chat 1-1; đọc và đọc hết thông báo; thành viên thường không thấy nút quản lý CLB; thoát màn chat khi socket đóng (BUG-CHAT-01)
  - Phụ thuộc: sau 1.2
- [ ] 2.4 Chuỗi D: Social chéo tài khoản. Tiêu chí: như trên với `integration_test/multi_social_cross_journey_test.dart`
  - Files: tạo `integration_test/multi_social_cross_journey_test.dart` (TC-MULTI-D-01..12); sửa số TC trùng trong `integration_test/social_chat_journey_test.dart` (đổi TC-SOCIAL-APP-13 của file này thành 19)
  - Nhận: 1.1
  - Ca chính: host thêm tài khoản → người đó nhận thông báo và thấy kèo; host đánh dấu ĐÃ THU → người chơi thấy; người chơi báo cáo kèo
  - Phụ thuộc: sau 1.2
- [ ] 2.5 Chuỗi E: admin, khách, auth. Tiêu chí: như trên với `integration_test/multi_admin_guest_journey_test.dart`
  - Files: tạo `integration_test/multi_admin_guest_journey_test.dart` (TC-MULTI-E-01..20)
  - Nhận: 1.1
  - Ca chính: đăng ký tài khoản mới trên giao diện; quên mật khẩu tới bước gửi; admin đăng nhập (BUG-ADMIN-01); admin duyệt giải và CLB, change-request, tranh chấp, xác minh trên giao diện; khách xem trang chủ, giải, bracket, live; khách mở `/chat`, `/club-create`, `/profile`, `/dashboard` (BUG-GUEST-01); khách mở link mời rồi đăng ký (BUG-GUEST-02)
  - Phụ thuộc: sau 1.2
- [ ] 2.6 Chuỗi F: chuỗi giải, `/ops`, Lite. Tiêu chí: như trên với `integration_test/multi_series_ops_lite_journey_test.dart`
  - Files: tạo `integration_test/multi_series_ops_lite_journey_test.dart` (TC-MULTI-F-01..15)
  - Nhận: 1.1
  - Ca chính: BTC tạo, sửa, xóa chuỗi; mời nhân sự chuỗi → người nhận chấp nhận; màn `/organizer/tournaments/:id/ops`; Lite: tạo, VĐV vào bằng mã, ghép cặp, quản lý
  - Phụ thuộc: sau 1.2

- [ ] 2.7 Chuỗi G: khám phá và xem. Tiêu chí: như trên với `integration_test/multi_discover_view_journey_test.dart`
  - Files: tạo `integration_test/multi_discover_view_journey_test.dart` (TC-MULTI-G-01..15)
  - Nhận: 1.1
  - Ca chính: tìm và lọc giải theo môn/trạng thái/tỉnh; trang sân; `/rankings` (dữ liệu seed); hồ sơ VĐV và ELO; bracket loại trực tiếp, vòng tròn, vòng bảng (giải seed); xem lại trận đã xong; khách và VĐV thấy cùng dữ liệu công khai
  - Phụ thuộc: sau 1.2
- [ ] 2.8 Chuỗi H: ma trận quyền qua API. Tiêu chí: như trên với `integration_test/multi_permission_matrix_test.dart`
  - Files: tạo `integration_test/multi_permission_matrix_test.dart` (TC-MULTI-H-01..)
  - Nhận: 1.1
  - Ca chính: bảng vai × endpoint nhạy cảm (sửa/xoá giải, duyệt VĐV, sinh bracket, chấm điểm, mời trọng tài/đồng BTC, duyệt CLB, admin duyệt giải, sửa hồ sơ người khác, xoá tin chat người khác); mỗi ô kỳ vọng 2xx hoặc 401/403; ô lệch thì ca đó `skip: 'BUG-PERM-xx'` và ghi Phát hiện. Endpoint đối chiếu `~/.omp/api-map/QuanLyGiaiDau.md` hoặc `lib/data/repositories/api/`
  - Phụ thuộc: sau 1.2

## 3. Tích hợp và báo cáo (phiên chính)

- [ ] 3.1 Gộp 8 nhánh chuỗi vào `app-e2e-nhieu-tai-khoan` bằng `git merge --no-ff`, xem diff từng nhánh. Tiêu chí: `flutter analyze --no-pub integration_test` → exit 0
  - Phụ thuộc: sau 2.1–2.8
- [ ] 3.2 Cập nhật bảng file, cách chạy song song và danh sách BUG trong `integration_test/ORGANIZER_JOURNEYS.md`; tạo `integration_test/COVERAGE.md` (chức năng → mã TC, ô trống); cập nhật mục "Phát hiện" trong `design.md` theo kết quả chạy thật. Tiêu chí: `openspec validate app-e2e-nhieu-tai-khoan --strict` → exit 0
  - Files: sửa `integration_test/ORGANIZER_JOURNEYS.md`; tạo `integration_test/COVERAGE.md`; sửa `openspec/changes/app-e2e-nhieu-tai-khoan/design.md`
  - Chủ file chung: 3.2 giữ `ORGANIZER_JOURNEYS.md`
  - Phụ thuộc: sau 3.1
- [ ] 3.3 Chạy lại 8 file trên cloud trên nhánh đã gộp (8 lượt song song, có Allure nếu 0.2 đã gộp), review theo vai trò. Tiêu chí: 8 lượt không có ca đỏ ngoài các ca `skip: 'BUG-...'`; gộp qua `merge-lane.py --check "python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py" --push` → exit 0
  - Phụ thuộc: sau 3.2 và 0.2
