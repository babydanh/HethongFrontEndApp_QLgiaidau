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

## 2. Sáu chuỗi hành trình (song song, mỗi chuỗi một worktree con, Sonnet)

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

## 3. Tích hợp và báo cáo (phiên chính)

- [ ] 3.1 Gộp 6 nhánh chuỗi vào `app-e2e-nhieu-tai-khoan` bằng `git merge --no-ff`, xem diff từng nhánh. Tiêu chí: `flutter analyze --no-pub integration_test` → exit 0
  - Phụ thuộc: sau 2.1–2.6
- [ ] 3.2 Cập nhật bảng file, cách chạy song song và danh sách BUG trong `integration_test/ORGANIZER_JOURNEYS.md`; cập nhật mục "Phát hiện" trong `design.md` theo kết quả chạy thật. Tiêu chí: `openspec validate app-e2e-nhieu-tai-khoan --strict` → exit 0
  - Files: sửa `integration_test/ORGANIZER_JOURNEYS.md`, `openspec/changes/app-e2e-nhieu-tai-khoan/design.md`
  - Chủ file chung: 3.2 giữ `ORGANIZER_JOURNEYS.md`
  - Phụ thuộc: sau 3.1
- [ ] 3.3 Chạy lại 6 file trên cloud trên nhánh đã gộp (6 lượt song song), review theo vai trò. Tiêu chí: 6 lượt không có ca đỏ ngoài các ca `skip: 'BUG-...'`; gộp qua `merge-lane.py --check "python C:/Users/GIGABYTE/.omp/scripts/openspec-gate.py" --push` → exit 0
  - Phụ thuộc: sau 3.2
