# Lỗi app phát hiện bởi E2E App

Ghi lại các lỗi của app (không phải lỗi test) do `integration_test` phát hiện trên cloud. Theo proposal, change này KHÔNG sửa logic app. Test tương ứng được giữ đỏ, không skip để xanh.

## F1. Tài khoản BTC (ORGANIZER) đăng nhập bằng form bị gán role `viewer`

- **Tái hiện**: run `39099166857`, `integration_test/auth_flow_test.dart:52` ("BTC đăng nhập bằng form và có quyền BTC"). Đăng nhập `admin1@gmail.com` trả HTTP 200 (`POST /auth/mobile/login`), test kỳ vọng `UserRole.organizer`, thực tế `UserRole.viewer`.
- **Nguyên nhân (đọc code)**:
  - `lib/providers/auth_provider.dart:366-375`, hàm `_mapSessionRole`, chỉ nhận `ADMIN`/`admin` và `REFEREE`/`referee`. `ORGANIZER` rơi về `UserRole.viewer`.
  - `lib/data/repositories/api/api_auth_repository.dart:193,202` lấy `user.roles` dạng chuỗi.
  - Backend `src/modules/auth/auth.repository.ts:34` trả `roleName` dạng chuỗi (`ORGANIZER`). [INFERENCE] response login chứa `ORGANIZER`; log CI chỉ có `response_bytes`, chưa xác nhận nội dung.
- **Phạm vi ảnh hưởng**:
  - Màn tạo giải nhanh (`create_public_quick_tournament_screen.dart:328-330`) kiểm `userProfile.role`, không kiểm `AuthState.role`. Luồng tạo giải không bị chặn bởi lỗi này.
  - Ảnh hưởng tới `AuthState.role` (`isOrganizer`, `canScore` tại `auth_provider.dart:51-56`) chưa được kiểm trên app. [INFERENCE] các chỗ dùng `AuthState` cho quyền BTC sẽ thấy `viewer`.
- **Trạng thái**: đã sửa ở change `fix-organizer-role-mapping`, commit `dcb750f7` (nhánh `app-e2e-integration-20261017`). `AuthNotifier.mapSessionRole` (`lib/providers/auth_provider.dart:366-376`) ưu tiên ADMIN > REFEREE > ORGANIZER. Chờ cloud xác nhận `integration_test/auth_flow_test.dart:52` xanh (task 1.3 của change đó). Task 4.1 (phần BTC) chỉ tick khi có run id.

## F2. Kiểm quyền BTC chỉ dựa vào trường `role` đơn

- **Tái hiện**: run `39107055615` (ref `142dad4c`) và `39108355255` (ref `dbdd7fdd`), `integration_test/organizer_flow_test.dart` ("BTC tạo giải nhanh…"). Test bấm "Tạo giải nhanh" rồi bị đẩy khỏi màn tạo giải trước khi nhập form: `Bad state: No element` ở bước cuộn tới "Thêm nội dung".
- **Nguyên nhân (đọc code)**:
  - `create_public_quick_tournament_screen.dart` `_verifyOrganizerPermission` (~328-329) và `_submit` (~494-495) kiểm `role == 'ORGANIZER'`/`'ADMIN'` trên trường `role` đơn.
  - `profile_screen.dart:626-627` (nhãn vai trò hồ sơ) làm tương tự.
  - Backend `src/modules/users/users.repository.ts:392,725` đặt `role: rolesList[0] || 'PLAYER'`; `users.service.ts:59` đặt `PLAYER` đứng đầu. Một BTC có thể có `role = PLAYER` và `roles` chứa `ORGANIZER`. [INFERENCE] suy từ code; chưa đo body `/users/profile`. Dialog chặn (`showOrganizerRequiredDialog`) làm màn đóng là [INFERENCE] từ log, chưa đo nội dung dialog.
- **Sửa**: dùng `UserProfile.hasRole` (kiểm mảng `roles`, `lib/domain/entities/user.dart:98-101`) ở 3 chỗ tạo giải và ở nhãn hồ sơ. Unit test: `test/domain/user_profile_role_test.dart`.
- **Trạng thái**: đã commit `3817f7bf` (cùng commit có F3). Run `39115189414`: ca BTC qua được màn tạo giải và gửi `POST /tournaments/lite` (lần đầu tới bước này trên CI), nên bước kiểm quyền không chặn. [INFERENCE] vì dialog chặn không được ghi log.

## F3. ListTile nằm trong Container có nền gây assertion Material

- **Tái hiện**: run `39108355255`, log `%TEMP%/cloud-test-39108355255-117618971826.log` quanh dòng 3729-3760 (07:51:42, trong ca BTC). Lỗi debug "ListTile background color or ink splashes may be invisible ... wrapped in a DecoratedBox that has a background color", báo 2 lần.
- **Nguyên nhân (đọc code)**: `create_public_quick_tournament_screen.dart` bọc `SwitchListTile`/`ExpansionTile` bằng `Container(decoration: BoxDecoration(color: colors.bgSurface, border: colors.border))` ở 3 chỗ: khối phí tham gia (~1516), "Cài đặt nâng cao" (~1997), khối tuỳ chọn trong sheet "Thêm nội dung" (~2534). `ExpansionTile` có `tilePadding` `symmetric(horizontal: 12)`, khớp `contentPadding (12,0,12,0)` trong thông báo.
- **Sửa**: đổi 3 `Container` có decoration thành `Material(color, shape: RoundedRectangleBorder(...))` để Material nằm ngay trên ListTile. Màu nền và viền giữ nguyên.
- **Trạng thái**: đã commit `3817f7bf`. Run `39115189414`: tìm trên toàn log không có chuỗi `ListTile background` hay `DecoratedBox`. Mới là bằng chứng ở mức log; chưa có screenshot.

## F4. Socket `/live` bị server ngắt khi rỗng phòng, làm rơi `WebSocketConnectionClosed` (ca đơn đỏ)

- **Tái hiện**: run `39111478956` (ref `46c2d691`), ca `integration_test/tournament_player_flow_test.dart`. Log `%TEMP%/cloud-test-39111478956-117628371847.log` dòng 3644–3666: `WebSocketConnectionClosed` từ `IOWebSocket.close` (`web_socket-1.0.1/lib/src/io_web_socket.dart:103-117`), kích hoạt bởi `Socket.ondisconnect` (`socket_io_client-3.1.6/lib/src/socket.dart:559-563`).
- **Nguyên nhân (đọc code, [INFERENCE])**:
  - `lib/data/repositories/api/api_tournament_repository.dart:605` và `:1124`: `leaveTournament` gỡ phòng giải dù watcher khác còn giữ. Không có đếm tham chiếu trong `lib/core/services/match_socket_service.dart` (trước sửa).
  - Socket không ngắt khi rỗng phòng. Backend `HethongBackendApi_QuanlyGiaiDau/src/modules/matches/live-score.gateway.ts:104-123` ngắt client không ở phòng nào sau 30 giây bằng `client.disconnect(true)`, đóng cả kết nối engine.io dùng chung.
  - Thư viện ném lỗi Future không bắt được ở call site. Trigger chính xác (watcher hủy làm rỗng phòng hay lý do khác) chưa đo được vì CI không có log socket của app.
- **Sửa**: change `openspec/changes/fix-socket-error-handling/`: đếm tham chiếu phòng, ngắt socket khi rỗng phòng, bỏ `close()` thừa. Trạng thái: đã sửa trong commit `d6cf6356`. Run `39113523342` (ref `06ac57ca`): tìm trong toàn bộ log không có dòng `WebSocketConnectionClosed` nào. Ca vẫn đỏ vì lỗi khác (F7), không phải socket.

## F5. Test chờ nhãn "Đăng ký ngay" trên trang chi tiết giải (lỗi test, không phải app)

- **Tái hiện**: run `39111478956`, `tournament_player_flow_test.dart:75-79` chờ "Đăng ký ngay" trên trang chi tiết giải. Ca đỏ trước khi hết thời gian chờ do exception socket của F4.
- **Nguyên nhân (đọc code)**: "Đăng ký ngay" là `l10n.registerNow` (`lib/l10n/app_vi.arb:77`), chỉ có ở màn đăng nhập (`lib/features/auth/screens/login_register_screen.dart:617`) và hồ sơ (`lib/features/profile/screens/profile_screen.dart:2269`). CTA trang chi tiết là `l10n.register` = "Đăng ký" (`app_vi.arb:419`, `lib/features/tournament/widgets/tournament_register_bar.dart:73`), hiện qua `tournament_intro_screen.dart:329`.
- **Sửa**: test tìm `find.widgetWithText(FilledButton, 'Đăng ký')`. App đúng, test sai nhãn. Commit `06ac57ca` áp dụng cho cả ca đôi (`tournament_player_flow_test.dart:218-244`).

## F6. Ca BTC: test tìm nút theo thứ tự sai (cuộn và chọn thời gian trước khi tìm "Thêm nội dung")

- **Tái hiện**: run `39111478956`, `integration_test/organizer_flow_test.dart:60` (`scrollToText 'Thêm nội dung'`), `Bad state: No element` (`Iterable.single`, log dòng 3721–3738). Stack đi qua `WidgetController.dragUntilVisible` và `scrollToText` (`integration_test/support/app_driver.dart:101`).
- **Nguyên nhân (đọc code và log; cơ chế chính xác là [INFERENCE])**:
  - Test cũ cuộn xuống "Thời gian bắt đầu *" và chọn ngày giờ trước, rồi mới tìm "Thêm nội dung" ở phía trên. Sau khi chọn thời gian, `scrollToText` không còn tìm thấy nút này.
  - Giả thuyết cũ "ListView lazy" bị loại: form tạo giải dùng `ListView(children: [...])` (`create_public_quick_tournament_screen.dart:718-721`), dựng đủ mọi con. Vì sao nút biến mất sau khi chọn thời gian vẫn chưa xác định.
  - Nút "Thêm nội dung" (`_buildAddContentButton`, `:1951-1974`) không bị ẩn bởi điều kiện (môn mặc định pickleball, `hasMore` luôn true, `:1952-1954`).
- **Sửa**: test tìm "Thêm nội dung" trước, rồi mới tới thời gian (`integration_test/organizer_flow_test.dart:51-68`). Không đổi assertion, không đổi app.
- **Xác nhận**: run `39113523342` (ref `06ac57ca`) qua được cả bước "Thêm nội dung" và chọn thời gian. Lỗi `No element` chuyển sang bước tìm nút gửi, do nhãn sai (F8).
- **Liên quan F2**: F2 (`39107055615`, `39108355255`) báo cùng `No element` ở bước cuộn tới "Thêm nội dung". Chưa đối chiếu được cơ chế của F2 với run mới.

## F7. Thanh Đăng ký trang chi tiết không hiện cho giải đang mở (lỗi app: chuẩn hoá trạng thái hai lần)

- **Tái hiện**: run `39113523342` (ref `06ac57ca`), `tournament_player_flow_test.dart` ca đơn và ca đôi chờ nút "Đăng ký" trên thanh đăng ký và hết 30 giây (log dòng ~3671–3692 và ~3788–3809). Lúc đó `GET /tournaments/:id` trả 200 (log dòng ~3646), nên dữ liệu có, chỉ thanh không được dựng.
- **Nguyên nhân (đọc code, [INFERENCE] mạnh)**:
  - `Tournament.fromJson` lưu `status: mappedStatus` (`lib/domain/entities/tournament.dart:257-259, 380`): `REGISTRATION_OPEN` thành `registration`.
  - `_buildRegistrationAction` gọi `StatusHelper.isTournamentRegistration(tournament.status)` (`tournament_intro_screen.dart:308-310`). Hàm này chuẩn hoá lần hai (`status_helpers.dart:70`): `registration` thành `REGISTRATION`, không khớp nhánh nào.
  - Nhánh mặc định gọi `_unknownStatus('registration')` (`status_helpers.dart:22-23, 41`), trả `raw_registration` vì `registration` thuộc `_internalStatusCodes`. Kết quả: không dựng thanh đăng ký. Nhãn hiển thị cũng có thể thành `raw_registration`.
- **Sửa**: `normalizeTournamentStatus` trả nguyên mã nội bộ đã chuẩn hoá (`status_helpers.dart:26-31`). Change `openspec/changes/fix-registration-status-normalize/`, commit `f2aa0362`.
- **Trạng thái**: đã sửa, chờ run `39115189414` (ref `9d84bed7`) xác nhận ca đơn và ca đôi qua bước tìm nút.

## F8. Nhãn nút gửi tạo giải là chữ cứng, không qua l10n (chưa sửa, cần quyết định sản phẩm)

- **Tái hiện**: run `39113523342`, `organizer_flow_test.dart` tìm "Tạo giải nhanh" và không thấy nút (`No element`, dòng 70 khi đó).
- **Nguyên nhân (đọc code)**: nút gửi ở thanh dưới của `create_public_quick_tournament_screen.dart:1047-1070` có chữ cứng `'Tạo giải đấu'`. `l10n.quickCreateSubmit` = "Tạo giải nhanh" (`app_vi.arb:2929`) không dùng ở nút này. AGENTS.md của App yêu cầu chuỗi hiển thị qua `lib/l10n/app_vi.arb`.
- **Xử lý**: test dùng nhãn đang hiển thị "Tạo giải đấu" (`integration_test/organizer_flow_test.dart`, commit `9d84bed7`). KHÔNG đổi chữ hiển thị của app; đưa vào l10n cần quyết định giữa "Tạo giải đấu" và "Tạo giải nhanh".

## F9. Giờ bắt đầu giải tạo nhanh bị dịch vì gửi cả `startDate` UTC lẫn `startTime` (lỗi app, đã sửa; cơ chế nằm ở Backend)

- **Tái hiện**: run `39115189414` (ref `9d84bed7`), ca BTC. Log `%TEMP%/cloud-test-39115189414-117639458931.log` dòng 3844–3845: `POST /tournaments/lite request_bytes=924` rồi `status=400`. Test chờ "nút thêm VĐV" và hết 60 giây (dòng 3850).
- **Nguyên nhân (đọc code; [INFERENCE] mạnh vì body 400 không có trong log)**: app gửi `startDate` là mốc UTC (`create_public_quick_tournament_screen.dart:630`) cùng `startTime` theo giờ local (`:631-632`). Backend (`tournament-lite.service.ts:574-610`) khi có `startTime` lấy phần ngày UTC của `startDate`, ghép với giờ và coi là UTC+7. Hai kịch bản đều dẫn tới 400:
  - máy ở UTC: giờ bắt đầu thành `17:00Z` hôm trước, trước hạn đăng ký `23:59Z` (`:676-684`, và `:869` cho từng nội dung);
  - máy ở UTC+7, giờ bắt đầu 00:00–06:59: ngày lùi một ngày, giờ thành quá khứ (`:685-688`).
- **Phạm vi**: cùng mẫu ở `create_club_tournament_screen.dart:192-195` và `create_club_screen.dart:168-170` (mẫu lịch định kỳ, bọc `try/catch` nên lỗi bị nuốt, xem mục Quan sát).
- **Sửa**: bỏ `startTime` ở 3 màn, commit `d7d7c4f8`, change `openspec/changes/fix-quick-create-start-time/`. **Đã xác nhận** ở run `39116901048` (ref `d7b5dc01`): `POST /tournaments/lite` trả `status=201` (log dòng 3830–3831), lỗi 400 hết. Mức: xác nhận bằng log; cơ chế 400 vẫn là [INFERENCE] vì body lỗi cũ không có trong log.

## F10. Nút gửi đăng ký không khớp vì app ghép thêm phí hoặc "(Miễn phí)" (lỗi test, đã sửa)

- **Tái hiện**: run `39115189414`, log dòng 3678 (ca đơn: "Hết 30s mà chưa thấy: nút gửi đăng ký") và dòng 3801 (ca đôi: "nút gửi đăng ký nội dung đôi"). Trước đó hai ca đã qua bước CTA "Đăng ký" (F7 đã sửa).
- **Nguyên nhân (đọc code)**: nút gửi là `registerSubmitFree(label)` = "{label} (Miễn phí)" hoặc `registerSubmitFee(label, fee)` = "{label} • {fee}" (`tournament_register_screen.dart:2275-2292`, `app_vi.arb:852-853`). `Text.data` không bằng nhãn gốc nên `anyTextOf` không khớp. Các test trước đây chưa từng tới bước này trên CI.
- **Sửa**: `anyTextStartingWith` ở `integration_test/support/app_driver.dart` và dùng ở `tournament_player_flow_test.dart:84` và `:246` (commit `d7b5dc01`). Không đổi app. **Kết quả** run `39116901048`: vẫn không thấy nút gửi, xem F11.

## F11. Ca đơn và ca đôi không thấy nút gửi đăng ký vì hồ sơ VĐV thiếu họ tên và SĐT (lỗi test, đã sửa ở `a1753c5d`)

- **Tái hiện**: run `39116901048` (ref `d7b5dc01`), log dòng 3662 (đơn: "Hết 30s mà chưa thấy: nút gửi đăng ký") và dòng 3787 (đôi). Hai ca đã qua CTA "Đăng ký" (F7).
- **Quan sát log**: sau khi bấm "Đăng ký", app gọi `GET /tournaments/:id/my-registration` (dòng ~3650) rồi không có request nào của form đăng ký. Test không thấy nút gửi nào trong 30 giây.
- **Các nhánh có thể làm nút gửi không hiện** (đọc code, chưa xác nhận): nhãn `registerRegClosed` khi `isRegistrationClosed` hoặc `_isDivisionRegistrationExpired` (`tournament_register_screen.dart:2276-2278`); nhãn `registerDivisionFull` khi `_isSelectedDivisionFull` (`:2279-2280`, `isFull` ở `tournament_registration.dart:81`); spinner khi `_checkingRegistration` (`:897`). Nhánh đăng nhập `_buildLoginPrompt` (`:896`) loại trừ vì log có `GET /users/profile` 200 trước đó.
- **Chẩn đoán đã thêm**: `pumpUntilCondition` (`integration_test/support/app_driver.dart`, commit `95b2fc2c`) ghi thêm danh sách chữ đang hiện khi hết giờ. Trạng thái: chờ run `39118510032`.
- **Kết quả chẩn đoán** (run `39118510032`, log dòng 3701–3705 và 3826–3830): màn đăng ký hiện banner "Hồ sơ chưa hoàn thiện — Bạn cần cập nhật đầy đủ Họ tên, Số điện thoại…". Hồ sơ của VĐV test `user8@gmail.com` đang thiếu dữ liệu. Khi thiếu họ tên hoặc SĐT, `_register` mở dialog và không gửi (`tournament_register_screen.dart:601-624`). Countdown "06 Ngày 23 Giờ" là mốc dự phòng +7 ngày, nghĩa là giải không có hạn đăng ký. Danh sách chữ đang hiện bị cắt ở 40 phần tử, nên chưa kết luận được nút gửi bị ẩn hay chỉ nằm ngoài danh sách. Nhãn gửi đúng là `Gửi yêu cầu tham gia` hoặc `Xác nhận đăng ký` (`app_vi.arb:780-781`), khớp tiền tố test đang tìm.
- **Đã sửa** (`a1753c5d`, chỉ đổi test): test điền họ tên và SĐT cho `user8` qua `PATCH /users/profile` trước khi đăng nhập (`completePlayerProfile`, `preparePlayerProfile`). **Kết quả**: ca đôi pass ở run `39123946327`, `39125477525` và `39126812760`; ca đơn đã vào màn "Gửi yêu cầu thành công!" ở run `39125477525`. Banner hồ sơ là nguyên nhân đã được xác nhận bằng run.

## F12. Ca BTC chờ nút thêm VĐV ở sai màn và sai tab (lỗi test, đã sửa ở `95b2fc2c` và `a1753c5d`)

- **Tái hiện**: run `39116901048`: `POST /tournaments/lite` 201 (dòng 3830–3831), sau đó hết 60 giây ở "trang quản lý giải nhanh vừa tạo (nút thêm VĐV)" (dòng 3864).
- **Nguyên nhân (đọc code)**: sau khi tạo, app `pushReplacement('/lite-manage/<id>')` (`create_public_quick_tournament_screen.dart:675`). Route này dùng `TournamentManagementDispatcher` với `showLiteWorkspace = false` (`app_router.dart:1001-1010`), nên mở hub (`TournamentManagementHubScreen`), không mở `LiteManagementScreen`. Nút có key `organizer-ops-add-athlete` chỉ có ở `OrganizerOpsScreen` (`organizer_ops_screen.dart:544`, route `/organizer/tournaments/:id/ops`).
- **Sửa (lỗi test)**: test chờ KPI hub `tournament-overview-athletes-edit` (`tournament_management_header.dart:137`), rồi mở `/organizer/tournaments/<id>/ops` bằng router, như các bước sau của test. Không đổi app, không nới assertion. Trạng thái: đã sửa; xem kết quả bên dưới.
- **Đã sửa** (`a1753c5d`): bấm ChoiceChip "Danh sách tham gia" bằng `tapCentered` trước khi tìm `organizer-ops-add-athlete`. Chẩn đoán (run `39118510032`, log dòng 3942–3945): màn điều hành đã mở (thấy "Không gian vận hành" và các tab "Tổng quan | Trận đấu | Bracket | Danh sách tham gia | Hoạt động"). Nút thêm VĐV nằm trong tab "Danh sách tham gia" (`_selectedTab == 3`, `organizer_ops_screen.dart:327-334`, `_buildRosterSliver`), còn màn mở ở tab Trận đấu (`:77`). **Kết quả**: ca BTC qua bước thêm VĐV ở run `39126812760` (log dòng 352, `+2 -1`).

## F13. Ca đơn chờ sai chuỗi sau khi gửi đơn đăng ký (lỗi test, đã sửa ở `46bb88c2`)

- **Tái hiện**: run `39125477525`, log dòng 98–120: "Hết 30s mà chưa thấy: trạng thái sau khi gửi đăng ký". Chữ đang hiện gồm "Chờ BTC duyệt", "Đăng ký đang chờ duyệt", "Đơn đăng ký đang chờ Ban Tổ Chức xét duyệt"; không có chuỗi nào trong điều kiện chờ của test.
- **Nguyên nhân (đọc code)**: điều kiện chờ ở `tournament_player_flow_test.dart` (sau khi gửi đơn, trước khi BTC duyệt) chỉ có "Đang chờ Ban tổ chức duyệt", "Bạn đã đăng ký giải đấu này", "Đã đăng ký, chưa thanh toán" (`app_vi.arb:844-848`). Màn sau gửi đơn hiển thị `registerDetailsPendingApproval` = "Chờ BTC duyệt" (`app_vi.arb:3285`, dùng ở `tournament_register_screen.dart:1217`). Ghi nhận, chưa sửa (ngoài phạm vi): "Đơn đăng ký đang chờ Ban Tổ Chức xét duyệt" là chuỗi cứng ở `tournament_register_screen.dart:1061` và `:1345`.
- **Sửa (lỗi test)**: thêm "Chờ BTC duyệt" vào điều kiện chờ đó. Điều kiện vẫn yêu cầu trạng thái thật của app, không nới.
- **Kết quả**: run `39126812760` qua điều kiện chờ sau khi gửi đơn, bước 4 (trạng thái đã đăng ký sau khi BTC duyệt) và bước 5 (tạo nhánh bằng API), rồi dừng ở bước 6 (F15).

## F14. Ca BTC tạo nhánh 400 vì giải có hai nội dung (lỗi test, đã sửa ở `66ee37cd`)

- **Tái hiện**: run `39125477525`: `POST /tournaments/lite` 201, `POST /tournaments/:id/add-athletes/direct` 201, `POST /tournaments/:id/generate-bracket` 400 (`[DioClient] ... status=400`). Test lỗi ở `organizer_flow_test.dart:219` ("Sau Lưu & Bắt đầu giải phải có trận trên Backend").
- **Nguyên nhân (đọc code)**: form tạo giải nhanh tick sẵn nội dung "Đôi linh hoạt" (`OPEN_DOUBLES`, `create_public_quick_tournament_screen.dart:175-180`). Test thêm nội dung đơn nhưng không bỏ tick, nên giải có hai nội dung. App chỉ gửi `divisionId` khi có đúng một nội dung (`auto_draw_screen.dart:107-113`). Backend từ chối khi có nhiều nội dung mà thiếu `divisionId`: "Vui lòng chọn nội dung để tạo sơ đồ." (`tournament-bracket.service.ts:432-438`). Lỗi nằm ở test; app và backend đúng. [INFERENCE mạnh: thông điệp 400 khớp với nhánh này; log không ghi nội dung body.]
- **Sửa (lỗi test)**: bỏ tick "Đôi linh hoạt" trước khi thêm nội dung đơn, và khẳng định giải còn đúng một nội dung (`hasLength(1)`).
- **Kết quả**: run `39126812760`, ca BTC pass (log dòng 352, `+2 -1`).

## F15. Tab bảng đấu trên trang chi tiết là "Bảng đấu", không phải "Bảng thi đấu" (lỗi test, đã sửa ở `e90dccad`)

- **Tái hiện**: run `39126812760` (ca đơn): "Hết 30s mà chưa thấy: tab Bảng thi đấu trên trang chi tiết. Chữ đang hiện: Tổng quan | Giới thiệu | Danh sách đội | Bảng đấu | Lịch thi đấu | ★ ELO ...".
- **Nguyên nhân (đọc code)**: tab hiển thị là chuỗi cứng "Bảng đấu" (`tournament_intro_screen.dart:752`). Test dùng "Bảng thi đấu" (`app_vi.arb:437`, `tabBracket`), không khớp nhãn đang hiển thị. Ghi nhận, chưa sửa: nhãn tab là chuỗi cứng, không qua l10n. Tab "Kết quả" chỉ hiện khi có trận hoàn thành (`tournament_intro_screen.dart:696-697`), nên bước 8 của test giữ nguyên.
- **Sửa (lỗi test)**: đổi nhãn thành "Bảng đấu" và bấm tab bằng `tapCentered`.
- **Kết quả**: chờ run `39127908361`.

## Lỗi Backend phát hiện (chỉ ghi lại, không sửa Backend)

- **B1** `src/modules/tournaments/services/tournament-lite.service.ts:588-610`: khi có `startTime`, backend ghép phần ngày UTC của `startDate` với giờ rồi coi là UTC+7 (cứng). Sai với mọi client không ở UTC+7 hoặc khi gửi mốc ISO kèm `startTime` (F9). Đề xuất: khi `startDate` là mốc ISO có múi giờ thì dùng mốc đó, không ghép giờ.
- **B2** Log khởi động backend trên CI (run `39115189414`, dòng ~2659–2667): `[WARN] Ghi chú làm sạch dữ liệu cũ` với `DELETE FROM "wards" WHERE "district_code" IS NOT NULL` lỗi `column "district_code" does not exist`. Các dòng `ALTER TABLE ... DROP CONSTRAINT` báo "does not exist" (dòng ~4460–4493). Cảnh báo không chặn app, nhưng cho thấy migration/seed lệch schema trên DB CI. Chưa xác định nguyên nhân gốc (không sửa Backend).

## Quan sát (chưa sửa)

- `create_club_screen.dart`: khối tạo lịch định kỳ bọc `try { ... } catch (templateErr)` (dòng ~117–184). Lỗi 400 của tạo giải không hiện cho người dùng, chỉ được ghi log. Hành vi này ngoài phạm vi đã duyệt; cần quyết định riêng.
- `create_public_quick_tournament_screen.dart:1065`: nhãn nút gửi "Tạo giải đấu" là chữ cứng (F8).

