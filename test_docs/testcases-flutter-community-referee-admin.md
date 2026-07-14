# FLUTTER APP TEST CASES — Community, Referee, Admin, Teams, Register, Series, Profile

---

## MODULE: COMMUNITY (CLB)

---

### TC-FLUTTER-COMMUNITY-001: Xem danh sách câu lạc bộ với filter và search
- **Module**: community
- **Screen**: `community_provider.dart` — `communitiesProvider`
- **Preconditions**: Người dùng đã vào màn hình danh sách CLB.
- **Steps**:
  1. Mở màn hình danh sách CLB.
  2. Quan sát danh sách hiển thị.
  3. Nhập từ khóa tìm kiếm vào ô search.
  4. Chọn filter thể thao (nếu có).
- **Expected**:
  - Danh sách CLB được hiển thị với thông tin: tên, môn thể thao, số thành viên, địa điểm, trạng thái.
  - Khi nhập search, danh sách được lọc theo tên.
  - Khi chọn filter thể thao, chỉ hiển thị CLB thuộc môn đó.
  - Pull-to-refresh reload dữ liệu.
  - Hiển thị loading indicator khi đang tải.
  - Nếu không có CLB nào, hiển thị empty state.
  - Nếu lỗi API, hiển thị error state với nút thử lại.
- **Edge cases**:
  - Search không có kết quả.
  - Người dùng chưa đăng nhập: chỉ thấy CLB public.
  - API trả về danh sách rỗng.
  - Mất kết nối mạng.

---

### TC-FLUTTER-COMMUNITY-002: Xem danh sách CLB của tôi
- **Module**: community
- **Screen**: `community_provider.dart` — `myCommunitiesProvider`
- **Preconditions**: Người dùng đã đăng nhập và có/không có CLB.
- **Steps**:
  1. Vào tab CLB của tôi.
  2. Xem danh sách.
- **Expected**:
  - Chỉ hiển thị CLB mà user là thành viên (JOINED).
  - Nếu lỗi API, trả về danh sách rỗng (không crash).
  - Có pull-to-refresh.
- **Edge cases**:
  - User chưa tham gia CLB nào: empty state.
  - API lỗi: không crash, hiển thị danh sách rỗng.

---

### TC-FLUTTER-COMMUNITY-003: Xem chi tiết CLB — Club Detail Screen
- **Module**: community
- **Screen**: `club_detail_screen.dart`
- **Preconditions**: CLB tồn tại, có ID hợp lệ.
- **Steps**:
  1. Mở màn hình chi tiết CLB với `clubId`.
  2. Quan sát banner, logo, tên, mô tả, thông tin.
  3. Chuyển qua các tab: Giới thiệu, Giải đấu, Thành viên, Ảnh, Xếp hạng.
- **Expected**:
  - Banner hiển thị ảnh nếu có `bannerUrl`, nếu không hiển thị gradient.
  - Logo hiển thị ảnh nếu có `logoUrl`, nếu không hiển thị emoji trên gradient.
  - Tên CLB hiển thị IN HOA.
  - Hiển thị sport tag với màu tương ứng (badminton=blue, tennis=orange, pickleball=green).
  - Hiển thị join mode badge (Tự do, Xét duyệt, Chỉ mời) với màu tương ứng.
  - Hiển thị location và member count.
  - Nếu có description, hiển thị trong tab Giới thiệu.
  - Tab Giới thiệu hiển thị thông tin chi tiết: Số thành viên, Địa điểm, Hình thức tham gia, Môn thi đấu.
  - Tab Giải đấu hiển thị danh sách giải đấu hoặc empty state.
  - Tab Thành viên hiển thị danh sách thành viên.
  - Tab Ảnh hiển thị gallery grid.
  - Tab Xếp hạng hiển thị bảng xếp hạng ELO.
  - Nếu CLB null: hiển thị "Không tìm thấy câu lạc bộ".
  - Nếu lỗi API: hiển thị error state với nút "Thử lại".
  - Loading: CircularProgressIndicator.
- **Edge cases**:
  - clubId không tồn tại.
  - CLB bị xoá.
  - Banner/Logo URL lỗi (errorBuilder xử lý fallback).
  - Description rỗng: ẩn phần mô tả.
  - Sports list rỗng: mặc định "Thể thao".
  - Location null: mặc định "Việt Nam".
  - Tất cả các tab đều empty đúng cách.

---

### TC-FLUTTER-COMMUNITY-004: Join CLB — Nút tham gia
- **Module**: community
- **Screen**: `club_detail_screen.dart` — `_handleJoinAction`
- **Preconditions**: Đã vào màn hình chi tiết CLB.
- **Steps**:
  1. Nhấn nút "Tham gia câu lạc bộ".
  2. Chờ xử lý.
- **Expected**:
  - Nếu chưa đăng nhập: chuyển hướng đến màn hình login.
  - Nếu CLB mode OPEN: join ngay, hiển thị snackbar thành công, nút chuyển thành "Đã tham gia".
  - Nếu CLB mode APPROVAL: gửi yêu cầu, nút chuyển thành "Đang chờ duyệt".
  - Nếu CLB mode INVITE_ONLY: cần được mời, nút join không hoạt động hoặc thông báo.
  - Trong lúc xử lý: hiển thị loading trên nút, disabled.
  - Nếu đã là thành viên (JOINED) hoặc đang chờ (PENDING): nút bấm không làm gì.
  - Nếu API lỗi: hiển thị snackbar lỗi.
- **Edge cases**:
  - Bấm nút liên tục: chỉ xử lý một lần (dùng `_isJoinLoading` flag).
  - API timeout.
  - CLB đã đầy thành viên.

---

### TC-FLUTTER-COMMUNITY-005: Quản lý thành viên — Promote/Demote/Kick
- **Module**: community
- **Screen**: `club_detail_screen.dart` — `_buildMemberItem` / `_handleMemberAction`
- **Preconditions**: User là OWNER hoặc ADMIN của CLB.
- **Steps**:
  1. Vào tab Thành viên.
  2. Nhấn vào menu (3 chấm) của một member.
  3. Chọn "Set làm Admin", "Set làm Mod", "Hạ xuống Member", hoặc "Xoá khỏi CLB".
- **Expected**:
  - Menu chỉ hiển thị với OWNER/ADMIN.
  - OWNER/ADMIN không thấy menu trên chính mình.
  - OWNER/ADMIN không thấy menu trên OWNER.
  - Promote admin: gọi `updateMemberRole` với role ADMIN.
  - Promote mod: gọi `updateMemberRole` với role MODERATOR.
  - Demote: gọi `updateMemberRole` với role MEMBER.
  - Kick: hiện confirmation dialog, nếu đồng ý gọi `removeMember`.
  - Sau mỗi action: invalidate provider để refresh danh sách.
  - Hiển thị snackbar thành công hoặc lỗi.
- **Edge cases**:
  - OWNER không thể kick chính mình.
  - ADMIN không thể kick OWNER.
  - MODERATOR không thấy menu (only OWNER/ADMIN).
  - API lỗi khi promote/demote/kick.

---

### TC-FLUTTER-COMMUNITY-006: Duyệt yêu cầu tham gia CLB (Join Requests)
- **Module**: community
- **Screen**: `club_detail_screen.dart` — `_buildJoinRequestsSection` / `_buildJoinRequestCard`
- **Preconditions**: User là OWNER hoặc ADMIN. Có yêu cầu tham gia PENDING.
- **Steps**:
  1. Vào tab Thành viên.
  2. Xem phần "Yêu cầu tham gia".
  3. Nhấn "Duyệt" hoặc "Từ chối".
- **Expected**:
  - Chỉ OWNER/ADMIN thấy phần join requests.
  - Hiển thị số lượng yêu cầu pending.
  - Mỗi yêu cầu hiển thị tên + avatar + trạng thái "Đang chờ duyệt".
  - Nút "Duyệt" (xanh) gọi `reviewJoinRequest` với action APPROVE.
  - Nút "Từ chối" (viền) gọi `reviewJoinRequest` với action REJECT.
  - Sau khi duyệt: member xuất hiện trong danh sách thành viên.
  - Sau khi từ chối: request biến mất khỏi danh sách.
  - Hiển thị snackbar tương ứng.
  - Nếu không có pending requests: ẩn section.
- **Edge cases**:
  - Người dùng đã bị ban trước đó vẫn gửi request.
  - Approve/Reject API lỗi.
  - Nhiều request cùng lúc.

---

### TC-FLUTTER-COMMUNITY-007: Mời thành viên qua dialog tìm kiếm
- **Module**: community
- **Screen**: `club_detail_screen.dart` — `_showInviteDialog`
- **Preconditions**: User là OWNER/ADMIN của CLB.
- **Steps**:
  1. Nhấn nút "Mời thành viên" trong tab Thành viên.
  2. Nhập tên hoặc email (ít nhất 2 ký tự).
  3. Chọn user từ kết quả tìm kiếm.
- **Expected**:
  - Dialog mở ra với ô tìm kiếm.
  - Sau khi nhập >= 2 ký tự, gọi API `/users/search`.
  - Hiển thị kết quả với avatar, tên, email.
  - Khi bấm vào user: gọi `inviteMember`, đóng dialog.
  - Nếu tìm kiếm không có kết quả: hiển thị "Không tìm thấy người dùng".
  - Hiển thị loading khi đang search.
  - Snackbar thành công khi gửi lời mời.
- **Edge cases**:
  - Tìm kiếm với ít hơn 2 ký tự: không gọi API.
  - Người dùng đã là thành viên: API báo lỗi.
  - Nhập query quá nhanh: debounce không có, có thể gọi nhiều lần.
  - Dialog đóng trước khi API hoàn thành (kiểm tra mounted).

---

### TC-FLUTTER-COMMUNITY-008: Tạo CLB mới
- **Module**: community
- **Screen**: `create_club_screen.dart`
- **Preconditions**: Người dùng đã đăng nhập.
- **Steps**:
  1. Vào màn hình "Tạo câu lạc bộ".
  2. Nhập tên (tối thiểu 3 ký tự).
  3. Chọn môn thể thao (mặc định: Cầu lông).
  4. Nhập mô tả (không bắt buộc).
  5. Nhập địa điểm (không bắt buộc).
  6. Chọn hình thức tham gia (mặc định: Tự do).
  7. Nhấn "Tạo câu lạc bộ".
- **Expected**:
  - Validate tên: nếu < 3 ký tự, hiển thị lỗi "Tên phải ít nhất 3 ký tự".
  - Chọn môn thể thao: 3 lựa chọn (Cầu lông, Tennis, Pickleball), hiển thị active state.
  - Chọn hình thức tham gia: 3 lựa chọn (Tự do, Xét duyệt, Chỉ mời), hiển thị active state.
  - Submit gọi POST `/communities` với body hợp lệ.
  - Trong lúc submit: nút disabled, hiển thị loading, text "Đang tạo...".
  - Thành công: snackbar, invalidate communitiesProvider, chuyển đến ClubDetail.
  - Lỗi: snackbar với message lỗi.
- **Edge cases**:
  - Tên đã tồn tại.
  - Bỏ trống tất cả field không bắt buộc.
  - API timeout.
  - Submit khi đang loading blocked (nút disabled).

---

### TC-FLUTTER-COMMUNITY-009: Chỉnh sửa CLB
- **Module**: community
- **Screen**: `edit_club_screen.dart`
- **Preconditions**: User là OWNER hoặc ADMIN của CLB.
- **Steps**:
  1. Vào màn hình "Chỉnh sửa CLB" (từ Club Detail nút "Sửa").
  2. Quan sát dữ liệu được fill sẵn từ API.
  3. Thay đổi tên, mô tả, địa điểm, môn thể thao, hình thức tham gia.
  4. Nhập số thành viên tối đa và quy tắc (không bắt buộc).
  5. Nhấn "Lưu thay đổi".
- **Expected**:
  - Dữ liệu hiện tại được điền sẵn vào form.
  - Validate tên: tối thiểu 3 ký tự.
  - Có thể thay đổi logo/banner qua ImagePicker (camera/gallery).
  - Submit gọi `updateCommunity` với các field đã thay đổi.
  - Thành công: snackbar, invalidate detail + list provider, pop về detail.
  - Lỗi: snackbar với message.
  - Nếu không tải được dữ liệu CLB: hiển thị error state "Không thể tải thông tin CLB" + nút thử lại.
- **Edge cases**:
  - Không thay đổi gì vẫn bấm Lưu.
  - Nhập maxMembers là text không phải số: `int.tryParse` trả về null, không gửi field.
  - Logo/banner upload: TODO, chưa triển khai.
  - API PATCH lỗi validation.

---

### TC-FLUTTER-COMMUNITY-010: Club Management — Điều phối CLB
- **Module**: community
- **Screen**: `club_management_screen.dart`
- **Preconditions**: User là OWNER/ADMIN/MODERATOR. Đã vào màn hình từ Club Detail nút "QL".
- **Steps**:
  1. Quan sát stats row: Đang hoạt động, Chờ duyệt, Đã mời, Đã cấm.
  2. Xử lý join requests (Duyệt/Từ chối).
  3. Mời thành viên qua search + role selector.
  4. Xem danh sách đã mời, có thể huỷ lời mời.
  5. Xem danh sách bị cấm, có thể gỡ cấm.
- **Expected**:
  - Stats row hiển thị đúng số lượng từng loại.
  - Join requests: hiển thị pending requests với nút Duyệt/Từ chối.
  - Invite section: nếu là OWNER, có role selector (Thành viên/Quản trị viên). Nếu là ADMIN, chỉ mời được vai trò Thành viên.
  - Search users gọi API `/users/search`, loại trừ user đã trong CLB.
  - Invited section: danh sách INVITED, có nút "Huỷ" để thu hồi.
  - Banned section: danh sách BANNED, có nút "Gỡ cấm".
  - Pull-to-refresh reload toàn bộ dữ liệu.
- **Edge cases**:
  - Owner có thể mời MODERATOR, ADMIN chỉ mời được MEMBER.
  - User đã trong CLB không xuất hiện trong kết quả search.
  - Huỷ lời mời khi user đã accept (cần xử lý).
  - Banned list rỗng: ẩn section.
  - Invited list rỗng: ẩn section.
  - Không có join requests: ẩn section.

---

### TC-FLUTTER-COMMUNITY-011: Club Invites — Xem và xử lý lời mời CLB
- **Module**: community
- **Screen**: `club_invites_screen.dart`
- **Preconditions**: Người dùng có ít nhất một lời mời tham gia CLB.
- **Steps**:
  1. Mở màn hình "Lời mời CLB".
  2. Xem danh sách lời mời.
  3. Bấm "Chấp nhận" hoặc "Từ chối" trên một lời mời.
- **Expected**:
  - Mỗi lời mời hiển thị: logo CLB, tên CLB, người mời, badge "Chờ duyệt".
  - Chỉ hiển thị lời mời PENDING (isPending = true).
  - Chấp nhận: gọi `respondToInvite` với action 'accept', invalidate provider, snackbar thành công.
  - Từ chối: tương tự với action 'decline'.
  - Nếu không có lời mời: empty state với icon mail.
  - Nếu lỗi API: error state với nút thử lại.
  - Pull-to-refresh để reload.
- **Edge cases**:
  - Lời mời đã hết hạn.
  - CLB đã bị xoá khi đang xử lý lời mời.
  - Bấm Chấp nhận trên lời mời đã từ chối trước đó.
  - Lời mời từ CLB đã đầy.

---

### TC-FLUTTER-COMMUNITY-012: Club Tournaments — Xem danh sách giải đấu của CLB
- **Module**: community
- **Screen**: `club_tournaments_screen.dart`
- **Preconditions**: CLB tồn tại.
- **Steps**:
  1. Mở màn hình giải đấu của CLB.
  2. Xem danh sách giải đấu.
- **Expected**:
  - Danh sách giải đấu với tên, ngày tháng, trạng thái, border màu đỏ nếu đang diễn ra.
  - Mỗi card click được, đưa đến màn hình intro của giải.
  - Nếu không có giải đấu: empty state với nút "Tạo giải đấu".
  - Nút "+" trên appbar để tạo giải đấu mới.
  - Pull-to-refresh reload.
- **Edge cases**:
  - Ngày tháng parse lỗi.
  - Status không xác định.

---

### TC-FLUTTER-COMMUNITY-013: Tạo giải đấu Lite trong CLB
- **Module**: community
- **Screen**: `create_club_tournament_screen.dart`
- **Preconditions**: User có quyền tạo giải trong CLB.
- **Steps**:
  1. Mở màn hình "Tạo giải đấu trong CLB".
  2. Nhập tên giải (bắt buộc).
  3. Chọn môn thể thao (Cầu lông/Tennis/Pickleball/Bóng bàn).
  4. Chọn hình thức (Đánh đơn/Đánh đôi).
  5. Chọn thể thức (Loại trực tiếp/Loại kép/Vòng tròn).
  6. Nhập số đội tối đa (2-128, mặc định 16).
  7. Nhập mô tả (không bắt buộc).
  8. Nhấn "Tạo giải đấu".
- **Expected**:
  - Validate tên: không được để trống.
  - Validate số đội: từ 2-128.
  - Submit gọi POST `/tournaments/lite` với body hợp lệ.
  - Giải được tạo mặc định là PRIVATE (thông báo trong info box).
  - Thành công: snackbar, invalidate providers, pop về màn hình trước.
  - Lỗi: snackbar với message.
- **Edge cases**:
  - Số đội là 0 hoặc âm.
  - Số đội là text không parse được.
  - API trả về lỗi validation.

---

### TC-FLUTTER-COMMUNITY-014: Club Gallery — Xem ảnh CLB
- **Module**: community
- **Screen**: `club_detail_screen.dart` — `_buildGalleryTab`
- **Preconditions**: CLB tồn tại.
- **Steps**:
  1. Vào tab "Ảnh".
- **Expected**:
  - Gallery hiển thị dạng grid 3 cột.
  - Mỗi ảnh click được, mở preview dialog với InteractiveViewer.
  - Nếu ảnh lỗi: hiển thị icon broken image.
  - Nếu không có ảnh: empty state "Chưa có ảnh nào".
  - Loading: CircularProgressIndicator.
  - Lỗi API: error state.
- **Edge cases**:
  - Ảnh load lâu: hiển thị loading progress.
  - Ảnh URL không hợp lệ.
  - Preview với ảnh lỗi.

---

### TC-FLUTTER-COMMUNITY-015: Club Rankings — Xem bảng xếp hạng
- **Module**: community
- **Screen**: `club_detail_screen.dart` — `_buildRankingsTab`
- **Preconditions**: CLB tồn tại.
- **Steps**:
  1. Vào tab "Xếp hạng".
- **Expected**:
  - Danh sách xếp hạng theo ELO points.
  - Top 3 có màu: Vàng/Bạc/Đồng.
  - Mỗi item hiển thị: số thứ tự, avatar, tên, ELO points.
  - ELO >= 1000: màu vàng với icon diamond.
  - Nếu không có xếp hạng: empty state.
  - Lỗi API: error state.
- **Edge cases**:
  - Nhiều người cùng ELO.
  - ELO points rất lớn.
  - Tên rỗng (fullName empty).

---

## MODULE: REFEREE

---

### TC-FLUTTER-REFEREE-001: Xem danh sách lời mời trọng tài
- **Module**: referee
- **Screen**: `referee_invites_screen.dart`
- **Preconditions**: Người dùng đã đăng nhập, có/có không lời mời làm trọng tài.
- **Steps**:
  1. Mở màn hình "Lời mời trọng tài".
  2. Xem danh sách lời mời.
- **Expected**:
  - Mỗi lời mời hiển thị: icon gavel, tên giải, tên hạng mục, badge "Chờ phản hồi", ngày mời, trạng thái giải.
  - Chỉ hiển thị lời mời PENDING (isPending = true).
  - Có nút "Nhận nhiệm vụ" (xanh) và "Từ chối" (viền).
  - Nếu không có lời mời: empty state với icon mail.
  - Lỗi API: error state với nút thử lại.
  - Pull-to-refresh.
- **Edge cases**:
  - Nhiều lời mời cùng lúc.
  - Lời mời đã hết hạn.

---

### TC-FLUTTER-REFEREE-002: Accept/Decline lời mời trọng tài
- **Module**: referee
- **Screen**: `referee_invites_screen.dart` — `_handleAction`
- **Preconditions**: Có ít nhất một lời mời PENDING.
- **Steps**:
  1. Bấm "Nhận nhiệm vụ" hoặc "Từ chối".
- **Expected**:
  - Accept: gọi `respondToRefereeInvite` với action 'ACCEPT', snackbar "Đã nhận lời mời trọng tài" (xanh).
  - Decline: action 'DECLINE', snackbar "Đã từ chối lời mời trọng tài" (cảnh báo).
  - Khi gọi API, workspace provider thực hiện optimistic update: xoá invite khỏi danh sách pending, thêm vào accepted nếu accept.
  - Nếu API lỗi: rollback optimistic update, hiển thị snackbar lỗi.
- **Edge cases**:
  - Accept khi đã có accepted trước đó.
  - Mất mạng khi đang xử lý.
  - API timeout > optimistic update rollback.

---

### TC-FLUTTER-REFEREE-003: Tournament Workspace Provider — Refresh và respond
- **Module**: referee
- **Screen**: `my_tournament_workspace_provider.dart`
- **Preconditions**: Người dùng đã đăng nhập.
- **Steps**:
  1. Workspace build: gọi `getMyWorkspace`.
  2. Refresh: gọi lại API, state = AsyncLoading -> AsyncValue.
  3. Respond to invite: optimistic update -> API -> refresh/rollback.
- **Expected**:
  - Nếu chưa authenticated: trả về `TournamentWorkspace.empty`.
  - Refresh set state loading rồi guard.
  - Respond optimistic: cập nhật local ngay, nếu API fail thì rollback.
  - `myRefereeInvitesProvider` lọc đúng `refereeInvites` từ workspace.
- **Edge cases**:
  - Auth state thay đổi giữa chừng.
  - Workspace chứa nhiều dữ liệu lớn.
  - Chưa có tournament nào.

---

## MODULE: ADMIN

---

### TC-FLUTTER-ADMIN-001: Admin Clubs — Danh sách CLB với filter và search
- **Module**: admin
- **Screen**: `admin_clubs_screen.dart`
- **Preconditions**: User có role admin.
- **Steps**:
  1. Mở màn hình "Quản lý CLB".
  2. Sử dụng filter chips: Tất cả, Hoạt động, Chờ duyệt, Từ chối.
  3. Nhập từ khóa tìm kiếm.
  4. Xem stat row.
- **Expected**:
  - Search bar với debounce.
  - Filter chips horizontal scroll, chọn cái nào active cái đó.
  - Stat row: Tổng, Hoạt động, Chờ, Từ chối với màu tương ứng.
  - Danh sách CLB với avatar, tên, mô tả, status badge.
  - Mỗi card có action: Xem (chi tiết), Duyệt (nếu PENDING), Từ chối/Vô hiệu.
  - Nếu không có CLB với filter: empty state với message phù hợp.
  - Lỗi API: error state.
- **Edge cases**:
  - Filter chuyển đổi nhanh.
  - Search không có kết quả.
  - Status filter "all" hiển thị tất cả.

---

### TC-FLUTTER-ADMIN-002: Admin — Duyệt/Từ chối/Vô hiệu CLB
- **Module**: admin
- **Screen**: `admin_clubs_screen.dart` — `_handleAction` / `_showRejectDialog`
- **Preconditions**: User admin, CLB tồn tại.
- **Steps**:
  1. Bấm "Duyệt" trên CLB có status PENDING.
  2. Bấm "Từ chối" hoặc "Vô hiệu" trên CLB.
- **Expected**:
  - Duyệt: gọi `reviewCommunity` với status 'ACTIVE', snackbar thành công.
  - Từ chối/Vô hiệu: mở dialog yêu cầu nhập lý do (bắt buộc, tối đa 200 ký tự).
  - Nếu lý do rỗng: không cho submit.
  - Submit reject: gọi `reviewCommunity` với status 'REJECTED' + `rejectedReason`.
  - Thành công: invalidate provider, snackbar.
  - Lỗi: snackbar lỗi.
  - Nếu không phải PENDING: không hiển thị nút "Duyệt".
- **Edge cases**:
  - Lý do 200 ký tự.
  - API lỗi khi reject.

---

### TC-FLUTTER-ADMIN-003: Pending Clubs — Duyệt CLB mới
- **Module**: admin
- **Screen**: `pending_clubs_screen.dart`
- **Preconditions**: User admin.
- **Steps**:
  1. Mở màn hình "Duyệt CLB".
  2. Xem danh sách CLB PENDING.
  3. Bấm "Duyệt" hoặc "Từ chối".
- **Expected**:
  - Chỉ hiển thị CLB có status PENDING.
  - Mỗi CLB hiển thị: avatar, tên, mô tả, số thành viên, badge "Chờ duyệt".
  - Nút "Duyệt" (xanh) gọi `reviewCommunity` ACTIVE.
  - Nút "Từ chối" mở dialog yêu cầu lý do.
  - Nếu không có CLB pending: empty state "Không có CLB nào chờ duyệt".
  - Lỗi API: error state với nút thử lại.
- **Edge cases**:
  - Duyệt CLB đã được duyệt trước đó.
  - Từ chối không nhập lý do.

---

## MODULE: TEAMS

---

### TC-FLUTTER-TEAMS-001: Danh sách đội trong giải đấu
- **Module**: teams
- **Screen**: `team_list_screen.dart`
- **Preconditions**: Giải đấu tồn tại.
- **Steps**:
  1. Mở màn hình "Quản lý đội / VĐV".
  2. Xem danh sách đội.
- **Expected**:
  - Mỗi đội hiển thị: số thứ tự, tên đội, danh sách thành viên, badge "Da duyet" nếu đã duyệt.
  - Nếu giải đang diễn ra hoặc đã kết thúc (isLocked): ẩn nút thêm/xoá/sửa, hiển thị thông báo "Giai dang dien ra".
  - Nếu không locked: FAB "Thêm đội", app bar có import Excel và menu Xoá toàn bộ.
  - Nếu không có đội: empty state với nút thêm.
  - Edit: click icon edit -> `AddTeamScreen` với `teamToEdit`.
  - Delete: confirmation dialog -> gọi `deleteTeam`.
  - Loading: CircularProgressIndicator.
- **Edge cases**:
  - Giải đấu chưa bắt đầu (isLocked = false).
  - Đội có danh sách thành viên rỗng.
  - Xoá đội cuối cùng.

---

### TC-FLUTTER-TEAMS-002: Import đội từ file Excel
- **Module**: teams
- **Screen**: `team_list_screen.dart` — `_importExcel`
- **Preconditions**: Giải chưa locked.
- **Steps**:
  1. Bấm icon upload file.
  2. Chọn file .xlsx hoặc .xls.
- **Expected**:
  - File picker mở với filter xlsx/xls.
  - Parse file: mỗi dòng là một đội, cột 0 là tên đội, cột 1+ là thành viên.
  - Bỏ qua dòng tiêu đề (chứa "ten").
  - Bỏ qua dòng rỗng.
  - Gọi `importTeams` với danh sách teams.
  - Hiển thị snackbar số lượng đội import thành công.
  - Nếu không có dữ liệu hợp lệ: snackbar warning.
  - Nếu lỗi: snackbar error.
- **Edge cases**:
  - File không có dữ liệu.
  - File sai định dạng.
  - Tên đội bị trùng.
  - File có nhiều sheet.

---

### TC-FLUTTER-TEAMS-003: Xóa toàn bộ đội
- **Module**: teams
- **Screen**: `team_list_screen.dart` — `_deleteAllTeams`
- **Preconditions**: Có ít nhất một đội.
- **Steps**:
  1. Bấm menu -> "Xoá toàn bộ đội".
  2. Xác nhận trong dialog.
- **Expected**:
  - Dialog cảnh báo: "Xóa TOÀN BỘ các đội bóng? Hành động này cũng sẽ xóa toàn bộ sơ đồ/kết quả thi đấu."
  - Nếu confirm: gọi `deleteAllTeams`.
  - Snackbar thành công.
  - Nếu cancel: không làm gì.
- **Edge cases**:
  - Không có đội nào.
  - API lỗi.

---

### TC-FLUTTER-TEAMS-004: Thêm/Sửa đội
- **Module**: teams
- **Screen**: `add_team_screen.dart`
- **Preconditions**: Giải chưa locked.
- **Steps**:
  1. Mở màn hình thêm đội (hoặc sửa từ danh sách).
  2. Nhập tên đội (bắt buộc).
  3. Thêm/Xoá thành viên.
  4. Nhập email liên hệ (tuỳ chọn).
  5. Lưu.
- **Expected**:
  - Validate tên: không được để trống.
  - Mặc định có 1 field thành viên trống.
  - Có thể thêm nhiều field thành viên, xoá field nếu > 1.
  - Chế độ sửa: fill sẵn dữ liệu từ `teamToEdit`.
  - Thêm mới: tạo Team với UUID, qrCode = 'VDV_...', gọi `addTeam`.
  - Sửa: gọi `updateTeam` với `copyWith`.
  - Thành công: pop về danh sách.
  - Lỗi: snackbar.
- **Edge cases**:
  - Thêm đội mà không có thành viên nào.
  - Tên đội đã tồn tại.
  - Email không hợp lệ (không validate format).
  - Sửa đội thành tên trùng.

---

## MODULE: REGISTER

---

### TC-FLUTTER-REGISTER-001: Đăng ký tham gia giải đấu
- **Module**: register
- **Screen**: `tournament_register_screen.dart`
- **Preconditions**: Giải đấu tồn tại, chưa đầy.
- **Steps**:
  1. Mở màn hình đăng ký.
  2. Xem thông tin giải.
  3. Nhập tên đội (tối thiểu 3 ký tự).
  4. Chọn division (nếu có).
  5. Nhấn "Xác nhận đăng ký".
- **Expected**:
  - Header hiển thị tên giải, số đội tối đa.
  - Nếu có phí tham gia: hiển thị phí (warning box), sau khi đăng ký chuyển sang payment nếu fee > 0.
  - Nếu chưa đăng nhập: hiển thị login prompt.
  - Nếu có divisions: hiển thị danh sách để chọn (radio style).
  - Submit gọi POST `/tournaments/:id/register` với teamName, divisionId, inviteCode.
  - Thành công: màn hình success với animation, nút "Xem chi tiết".
  - Nếu có phí: tự động chuyển đến payment checkout.
  - Lỗi: snackbar.
- **Edge cases**:
  - Tên đội < 3 ký tự.
  - Division loading error.
  - Giải đã đầy.
  - API trả về lỗi validation.

---

### TC-FLUTTER-REGISTER-002: Tham gia giải đấu bằng mã mời
- **Module**: register
- **Screen**: `join_invite_screen.dart`
- **Preconditions**: Có mã mời hợp lệ.
- **Steps**:
  1. Mở link/mã mời.
  2. Hệ thống gọi API lấy thông tin giải.
  3. Nếu chưa login: nút "Đăng nhập để tiếp tục".
  4. Nếu đã login: nhập tên đội, nhấn "Xác nhận tham gia".
- **Expected**:
  - Gọi GET `/tournaments/join/:inviteCode` để lấy thông tin.
  - Hiển thị icon key, mã mời, tên giải.
  - Nếu chưa login: hướng dẫn đăng nhập.
  - Nếu đã login: form nhập tên đội.
  - Submit gọi POST `/tournaments/join/:inviteCode`.
  - Thành công: snackbar, navigate về home.
  - Lỗi: snackbar.
- **Edge cases**:
  - Mã mời không hợp lệ.
  - Mã mời đã hết hạn.
  - Giải đã đầy.
  - Tên đội < 3 ký tự.

---

### TC-FLUTTER-REGISTER-003: Tham gia đội (Join Team)
- **Module**: register
- **Screen**: `join_team_screen.dart`
- **Preconditions**: Có token mời tham gia đội (đánh đôi).
- **Steps**:
  1. Mở link mời tham gia đội.
  2. Nhấn "Xác nhận tham gia".
- **Expected**:
  - Hiển thị thông tin: icon group, "Lời mời tham gia đội", "Ban duoc moi vao mot doi danh doi".
  - Submit gọi POST `/tournaments/:id/join-team` với participantId + teamInviteToken.
  - Thành công: màn hình success với nút "Xem giải đấu".
  - Lỗi: snackbar.
- **Edge cases**:
  - Token không hợp lệ.
  - Đội đã đầy.
  - Participant đã ở đội khác.

---

## MODULE: SERIES

---

### TC-FLUTTER-SERIES-001: Xem danh sách chuỗi giải đấu
- **Module**: series
- **Screen**: `series_screen.dart`
- **Preconditions**: Có/không có chuỗi giải đấu.
- **Steps**:
  1. Mở màn hình "Chuỗi giải đấu".
- **Expected**:
  - Danh sách series với: icon, tên, status badge, ngày bắt đầu, số chặng, số VĐV.
  - Status: "Đang diễn ra" (đỏ border shadow), "Sắp diễn ra" (xanh), "Đã kết thúc" (xanh lá).
  - Mỗi card click được (TODO: detail).
  - Nếu không có series: empty state.
  - Pull-to-refresh.
  - Lỗi API: hiển thị lỗi.
- **Edge cases**:
  - Series có startDate null.
  - Status không xác định.
  - legCount = 0, participantCount = 0.

---

## MODULE: PROFILE / SETTINGS

---

### TC-FLUTTER-PROFILE-001: Settings — Tab Hồ sơ
- **Module**: profile
- **Screen**: `settings_screen.dart` — `_ProfileTab`
- **Preconditions**: Người dùng đã đăng nhập.
- **Steps**:
  1. Vào màn hình Cài đặt.
  2. Tab Hồ sơ.
  3. Xem và sửa thông tin.
  4. Nhấn "Lưu thay đổi".
- **Expected**:
  - Form với: Họ tên, Email (read-only), Số điện thoại, Giới tính (dropdown), Địa chỉ, Tỉnh/Thành (dropdown), Tiểu sử.
  - Dữ liệu được fill sẵn từ profile API.
  - Validate họ tên: không được để trống.
  - Email disabled, không thể sửa.
  - Submit gọi `updateProfile` với các field.
  - Thành công: snackbar, invalidate provider.
  - Lỗi: snackbar với message.
  - Profile loading: CircularProgressIndicator.
  - Profile error: error state với nút thử lại.
- **Edge cases**:
  - Bỏ trống số điện thoại.
  - Chọn giới tính "Khác".
  - API lỗi validation.

---

### TC-FLUTTER-PROFILE-002: Settings — Tab Ngân hàng
- **Module**: profile
- **Screen**: `settings_screen.dart` — `_BankTab`
- **Preconditions**: Người dùng đã đăng nhập.
- **Steps**:
  1. Vào tab Ngân hàng.
  2. Nhập tên ngân hàng, số tài khoản, tên chủ tài khoản.
  3. Lưu.
- **Expected**:
  - Info banner: thông tin ngân hàng dùng để nhận tiền thưởng, được bảo mật.
  - Form: Tên ngân hàng, Số tài khoản (number keyboard), Tên chủ tài khoản (capitalize).
  - Dữ liệu được fill sẵn.
  - Submit gọi `updateProfile` với bank fields.
  - Thành công/lỗi: snackbar.
- **Edge cases**:
  - Bỏ trống tất cả.
  - Nhập chữ vào số tài khoản (number keyboard hạn chế nhưng không validate).

---

### TC-FLUTTER-PROFILE-003: Settings — Tab Bảo mật
- **Module**: profile
- **Screen**: `settings_screen.dart` — `_SecurityTab`
- **Preconditions**: Người dùng đã đăng nhập.
- **Steps**:
  1. Vào tab Bảo mật.
- **Expected**:
  - Trạng thái xác thực: Email (verified/unverified), Số điện thoại.
  - Nút "Đổi mật khẩu" -> navigate đến ChangePasswordScreen.
  - Mật khẩu mạnh: info + icon check.
  - Phiên đăng nhập: "Thiết bị hiện tại - Online".
  - Profile loading: loading indicator.
  - Profile error: text "Không thể tải trạng thái".
- **Edge cases**:
  - Email chưa xác thực.
  - Số điện thoại chưa xác thực.
  - Profile null.

---

### TC-FLUTTER-PROFILE-004: Chỉnh sửa thông tin cá nhân (Edit Profile)
- **Module**: profile
- **Screen**: `edit_profile_screen.dart`
- **Preconditions**: Người dùng đã đăng nhập.
- **Steps**:
  1. Mở màn hình "Sửa thông tin".
  2. Xem và sửa: avatar, họ tên, email (read-only), số điện thoại, ngày sinh, giới tính, địa chỉ, tỉnh/thành, bio.
  3. Đổi avatar bằng camera/gallery.
  4. Lưu.
- **Expected**:
  - Avatar: click để đổi, bottom sheet chọn camera/gallery.
  - Upload avatar: gọi `uploadAvatar`, invalidate profile provider, snackbar.
  - Họ tên: validate không được để trống.
  - Email: read-only.
  - Số điện thoại: validate format Vietnam (+84|0)[3|5|7|8|9]\d{8}.
  - Ngày sinh: date picker, max = ngày hiện tại, min = 1900.
  - Giới tính: dropdown (Nam/Nữ/Khác).
  - Địa chỉ: validate không được để trống.
  - Tỉnh/Thành: dropdown load từ API `/regions/provinces`, fallback 5 tỉnh mặc định.
  - Bio: max 200 ký tự.
  - Submit gọi `updateProfile` với full data.
  - Thành công: snackbar, navigate về /profile.
  - Lỗi: snackbar.
  - Profile loading: CircularProgressIndicator.
  - Profile error: text lỗi.
- **Edge cases**:
  - Province API fail: dùng 5 tỉnh fallback.
  - Avatar upload file quá lớn.
  - Cancel chụp ảnh.
  - Ngày sinh trong tương lai (date picker giới hạn).
  - Số điện thoại không đúng format Vietnam.

---

### TC-FLUTTER-PROFILE-005: Đổi mật khẩu
- **Module**: profile
- **Screen**: `change_password_screen.dart`
- **Preconditions**: Người dùng đã đăng nhập.
- **Steps**:
  1. Mở màn hình "Đổi mật khẩu".
  2. Nhập mật khẩu hiện tại (bắt buộc).
  3. Nhập mật khẩu mới (tối thiểu 6 ký tự, có chữ hoa + số).
  4. Xác nhận mật khẩu mới (phải khớp).
  5. Nhấn "Đổi mật khẩu".
- **Expected**:
  - Password fields có toggle visibility.
  - Validate mật khẩu hiện tại: không để trống.
  - Validate mật khẩu mới: >= 6 ký tự.
  - Password requirements checklist realtime update: "Có ít nhất 6 ký tự", "Có ít nhất 1 chữ hoa", "Có ít nhất 1 chữ số".
  - Confirm password: phải khớp với mật khẩu mới.
  - Submit: simulated delay 1s (UI only, chưa gọi API thật).
  - Thành công: snackbar, navigate về /profile.
  - Loading: button disabled + spinner.
  - Info box: hướng dẫn bảo mật.
- **Edge cases**:
  - Mật khẩu mới giống mật khẩu hiện tại (không validate).
  - Clipboard paste password.
  - Toggle visibility nhiều lần.
  - Chưa nhập đủ requirement vẫn submit được (validation chỉ check length >= 6).

---

### TC-FLUTTER-PROFILE-006: Xem hồ sơ người dùng khác (User Profile)
- **Module**: profile
- **Screen**: `user_profile_screen.dart`
- **Preconditions**: Người dùng khác tồn tại, userId hợp lệ.
- **Steps**:
  1. Mở link xem hồ sơ người dùng khác.
- **Expected**:
  - Cover section: gradient mặc định hoặc ảnh cover.
  - Avatar + tên + gender icon + bio.
  - Verified badge nếu `isVerified`.
  - Stats overview: Bộ môn, Tổng trận, Thắng, Thua, Tỉ lệ.
  - Xếp hạng theo bộ môn: ELO points, rank name, win rate bar.
  - ELO màu theo tier (dùng TierPalette).
  - CLB đang tham gia: placeholder "Chưa tham gia câu lạc bộ".
  - Giải đấu đã tham gia: placeholder "Chưa có dữ liệu giải đấu".
  - Loading: shimmer effect.
  - Error: "Không thể tải thông tin" + nút "Về trang chủ".
- **Edge cases**:
  - userId không tồn tại.
  - ranks rỗng: "Chưa có dữ liệu xếp hạng".
  - avatarUrl null: fallback initials.
  - coverUrl null: gradient mặc định.
  - Tên dài: ellipsis.

---

### TC-FLUTTER-PROFILE-007: QR Scanner
- **Module**: profile
- **Screen**: `qr_scanner_screen.dart`
- **Preconditions**: Camera permission granted.
- **Steps**:
  1. Mở màn hình QR scanner.
  2. Quét mã QR hợp lệ.
- **Expected**:
  - Camera hiển thị với overlay (scan area có góc màu primary).
  - Xử lý barcode: trích xuất code từ URL nếu có `code=` param.
  - Gọi `authProvider.validateToken(code)`.
  - Loading overlay: "Đang xác thực...".
  - Thành công: invalidate providers, navigate theo role (admin -> admin, referee -> intro, viewer -> intro, others -> home).
  - Thất bại: snackbar lỗi "Mã QR không hợp lệ", chờ 2 giây để quét lại.
  - Bấm close: pop.
  - Debounce: `_isProcessing` flag ngăn quét nhiều lần.
- **Edge cases**:
  - Camera permission denied.
  - QR code không hợp lệ.
  - QR code là URL phức tạp.
  - Quét sai nhiều lần.
  - Token hết hạn.
