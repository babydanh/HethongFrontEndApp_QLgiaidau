# Lite Tournament Plan

## 1. Mục Tiêu

Lite Tournament là luồng tạo và vận hành giải nhanh dành cho player có cộng đồng/CLB.

Mục tiêu của lite:

- Tạo giải trong vài thao tác, không bắt cấu hình sâu như organizer full.
- Có preset sẵn theo từng môn để người tạo không phải hiểu nhiều setting kỹ thuật.
- Người chơi tham gia bằng QR/link, đăng nhập xong có thể bấm tham gia.
- Nếu người quét QR chưa nằm trong CLB thì xử lý vào CLB theo setting cộng đồng.
- Bracket có thể random, seed theo ELO, hoặc kéo thả xếp tay.
- Có sơ đồ bracket rõ ràng ngay trong app và web.
- Ban tổ chức quản lý nhẹ, không copy toàn bộ organizer full.
- Người chơi trong giải có thể được gán làm trọng tài.

Lite không thay thế organizer full. Organizer full vẫn dùng cho giải lớn, giải công khai, nhiều nội dung, phí, duyệt ELO, vận hành chuyên nghiệp.

## 2. Nguyên Tắc Sản Phẩm

- Đơn giản trước, tùy biến sau.
- Mặc định dùng được ngay.
- Mọi hành động quan trọng phải có kết quả nhìn thấy: tạo xong có QR, tham gia xong có tên trong danh sách, random xong có sơ đồ.
- Lite không cần hệ thống phân quyền riêng phức tạp.
- Chỉ ban tổ chức được quản lý giải.
- Người chơi có thể được gán làm trọng tài trong từng trận nếu ban tổ chức muốn.
- App và web dùng chung API, không để lệch logic.

## 3. Vai Trò

### Ban Tổ Chức

Ban tổ chức là người tạo giải lite và các thành viên được thêm vào ban tổ chức nếu sau này cần mở rộng.

Quyền của ban tổ chức:

- Tạo giải lite.
- Chia sẻ QR/link tham gia.
- Xem danh sách người tham gia.
- Duyệt hoặc từ chối nếu mode tham gia cần duyệt.
- Random bracket.
- Seed theo ELO.
- Kéo thả xếp bracket thủ công.
- Tạo lại bracket nếu giải chưa bắt đầu.
- Gán người chơi làm trọng tài cho trận.
- Mở trận đấu và chấm điểm nếu cần.
- Đóng/mở đăng ký lite.

### Người Chơi

Người chơi là thành viên CLB/cộng đồng hoặc người tham gia qua QR/link hợp lệ.

Quyền của người chơi:

- Xem giải nếu là thành viên CLB hoặc đã tham gia giải.
- Bấm tham gia giải.
- Xem bracket, lịch thi đấu, kết quả.
- Nếu được gán làm trọng tài, có thể vào trận được gán để chấm điểm.

### Trọng Tài Lite

Trọng tài lite không phải role riêng tách khỏi người chơi.

Nguyên tắc:

- Một người chơi trong giải hoặc thành viên CLB có thể được BTC gán làm trọng tài cho một trận.
- Khi được gán, người đó có quyền chấm điểm trận được gán.
- Hết trận hoặc bị gỡ gán, quyền chấm điểm của người đó không còn trên trận đó.
- Không cần màn hình phân quyền trọng tài phức tạp cho lite.

## 4. Ai Được Xem

Mặc định:

- Ban tổ chức xem và quản lý.
- Người đã tham gia giải xem được.
- Thành viên CLB/cộng đồng chưa tham gia cũng xem được nếu giải không ở chế độ ẩn.

Tùy chọn lite nên có:

- Hiện trong CLB: thành viên CLB xem được.
- Chỉ người có link/QR: ai có link xem landing join, nhưng phải đăng nhập để tham gia.
- Ẩn tạm thời: chỉ BTC xem trong khi setup.

Không nên thêm quá nhiều cấp xem cho lite.

## 5. Luồng Tạo Giải Lite

### Bước 1: Chọn Tạo Giải Nhanh

Vị trí:

- App: trong màn hình CLB/cộng đồng.
- Web: trong trang quản lý tournament của cộng đồng.

CTA:

- Tạo giải nhanh
- Tạo bằng QR

### Bước 2: Nhập Thông Tin Tối Thiểu

Field cần có:

- Tên giải.
- Môn thi đấu.
- Hình thức: Đơn/Đôi.
- Số đội tối đa: 4, 8, 16, 32, hoặc nhập nhanh.
- Kiểu bracket: Loại trực tiếp, vòng tròn, vòng bảng + playoff.

Field optional:

- Mô tả ngắn.
- Địa điểm.
- Thời gian bắt đầu.
- Banner/logo nếu có.

Không bắt người dùng nhập:

- Category UUID.
- Luật điểm chi tiết.
- Multi division.
- Phí và cấu hình thanh toán.
- Staff/permission phức tạp.

### Bước 3: Chọn Kiểu Tham Gia

Ba mode:

- Mở cho thành viên CLB: thành viên CLB bấm là vào.
- Cần BTC duyệt: thành viên gửi yêu cầu, BTC duyệt.
- Chỉ QR/link mời: người có QR/link hợp lệ mới vào luồng tham gia.

Nếu người quét QR chưa là thành viên CLB:

- CLB OPEN: đăng nhập xong tự động join CLB và tham gia giải.
- CLB APPROVAL: đăng nhập xong gửi yêu cầu vào CLB, sau khi duyệt mới tham gia giải.
- CLB INVITE_ONLY: chỉ vào được nếu QR/link kèm invite hợp lệ hoặc có lời mời CLB.

### Bước 4: Chọn Kiểu Xếp Bracket Mặc Định

Lựa chọn:

- Random ngay khi đủ số người.
- Seed theo ELO khi đủ số người.
- Tự xếp tay.
- Chưa xếp, để BTC bấm sau.

Khuyến nghị mặc định:

- Giải giao hữu: random.
- Giải có ranking: seed theo ELO.
- Giải nhỏ tự phát: tự xếp tay.

### Bước 5: Tạo Thành Công

Sau khi tạo xong hiện ngay:

- QR tham gia.
- Link tham gia.
- Nút copy link.
- Nút chia sẻ.
- Nút vào quản lý lite.
- Nút xem trang giải.

## 6. Preset Theo Môn

Preset là cấu hình mặc định trong backend/app/web. Người dùng lite chỉ thấy label để hiểu, không cần thấy JSON.

### Pickleball

- Format điểm: BO3.
- Điểm mỗi set: 11.
- Thắng cách 2.
- Phù hợp: đôi, mixed, giao hữu CLB.

### Cầu Lông

- Format điểm: BO3.
- Điểm mỗi set: 21.
- Thắng cách 2.
- Giới hạn set theo luật cầu lông thông dụng.

### Bóng Bàn

- Format điểm: BO5.
- Điểm mỗi set: 11.
- Thắng cách 2.

### Tennis

- Lite nên có 2 preset:
- Super tie-break: nhanh, phù hợp giải nội bộ.
- Short set BO3: nếu cần đấu nghiêm túc hơn.

## 7. Luồng Tham Gia Bằng QR/Link

### Link Chuẩn

Deep link/web link nên thống nhất:

```text
/lite/tournaments/join/{inviteCode}
```

Hoặc nếu muốn gắn với tournament id:

```text
/lite/tournaments/{id}/join?invite={inviteCode}
```

Khuyến nghị dùng inviteCode làm entry chính để QR gọn hơn.

### App Đã Cài

1. Người dùng quét QR.
2. Mở app vào màn hình join lite.
3. Nếu chưa đăng nhập, chuyển login.
4. Login xong quay lại join lite.
5. App kiểm tra CLB membership.
6. Nếu hợp lệ, hiện nút Tham gia.
7. Bấm Tham gia.
8. Hiện thành công và link tới bracket/trang giải.

### Chưa Có App

1. Người dùng quét QR.
2. Mở web lite.
3. Nếu chưa đăng nhập, bắt đăng nhập/đăng ký.
4. Đăng nhập xong quay lại web join.
5. Nếu hợp lệ, bấm Tham gia.
6. Web hiện QR tải app hoặc tiếp tục xem bracket trên web.

### Xử Lý Trạng Thái

Cần có thông báo rõ:

- Bạn đã tham gia giải này.
- Giải đã đầy.
- Đang chờ BTC duyệt.
- Bạn chưa là thành viên CLB.
- Yêu cầu vào CLB đang chờ duyệt.
- Mã mời không hợp lệ hoặc hết hạn.
- Giải đã đóng đăng ký.

## 8. Đăng Ký Lite

Đăng ký lite nên là một chạm.

### Đơn

Nếu profile đủ thông tin:

- Bấm Tham gia.
- Tạo participant theo tên user.
- Nếu mode approval thì status PENDING_APPROVAL.
- Nếu open thì COMPLETE.

Nếu profile thiếu:

- Hiện sheet cập nhật nhanh: tên, SĐT, giới tính nếu cần.
- Cập nhật xong quay lại tham gia.

### Đôi

Lựa chọn đơn giản:

- Tham gia một mình trước, mời đồng đội sau.
- Nhập email/SĐT đồng đội.
- Chọn đồng đội trong CLB nếu có.

Trạng thái:

- PENDING_PARTNER nếu chưa có đồng đội.
- COMPLETE nếu đủ cặp và mode open.
- PENDING_APPROVAL nếu mode cần duyệt.

## 9. Quản Lý Lite

Màn quản lý lite nên gồm 4 tab.

### Tổng Quan

Hiện:

- Số người/đội đã tham gia.
- Trạng thái đăng ký.
- Số trận đã tạo.
- QR/link tham gia.
- Nút mở/đóng đăng ký.
- Nút xem trang giải.

### Người Tham Gia

Chức năng:

- Xem danh sách người/đội.
- Lọc: tất cả, chờ duyệt, đã vào, chờ đồng đội.
- Duyệt/từ chối nếu mode approval.
- Xóa khỏi giải nếu bracket chưa bắt đầu.
- Gán seed thủ công.

Không cần UI tài chính phức tạp trong lite.

### Bracket

Chức năng:

- Chọn random.
- Seed theo ELO.
- Kéo thả seed.
- Tạo bracket.
- Xem sơ đồ bracket.
- Reset bracket nếu chưa có trận bắt đầu.

Quy tắc:

- Nếu đã có trận đang live/completed thì không cho reset tự do.
- Nếu reset cần cảnh báo rõ: lịch/trận cũ sẽ bị tạo lại.

### Trận Đấu

Chức năng:

- Xem lịch trận.
- Mở trận để chấm điểm.
- Gán trọng tài là người chơi/thành viên CLB.
- Đổi sân/giờ nhanh.
- Hiện trạng thái: chưa đấu, đang đấu, đã xong.

## 10. Bracket Lite

Lite cần ưu tiên sơ đồ đẹp và dễ hiểu.

Loại bracket nên hỗ trợ trước:

- Single elimination.
- Round robin.
- Group stage + knockout.

Double elimination có thể để phase sau vì phức tạp hơn.

### Random

Input:

- Danh sách participant COMPLETE.

Output:

- Match/stage được tạo.
- Sơ đồ bracket hiện ngay.

### Seed Theo ELO

Input:

- Participant + ELO theo môn.

Output:

- Seed từ cao đến thấp.
- Phân nhánh theo logic tránh đội mạnh gặp sớm.

### Kéo Thả Xếp Tay

Cần có:

- Danh sách người/đội bên trái.
- Slot bracket bên phải.
- Kéo thả hoặc bấm chọn slot.
- Nút lưu seed.
- Nút tạo bracket.

## 11. Web Lite

Web lite bắt buộc có vì QR có thể được quét bởi người chưa cài app.

Route đề xuất:

```text
/communities/[id]/lite/create
/lite/tournaments/[id]
/lite/tournaments/join/[inviteCode]
/lite/tournaments/[id]/manage
```

Trang web lite cần có:

- Landing join bằng QR/link.
- Bắt đăng nhập trước khi tham gia.
- Hiện trạng thái CLB membership.
- Nút tham gia.
- Xem bracket.
- Quản lý lite cho BTC.

Web lite không nên dùng layout organizer full quá nặng.

## 12. App Lite

Màn app cần có:

- CreateLiteTournamentScreen mới hoặc refactor CreateClubTournamentScreen.
- LiteJoinScreen cho QR/deep link.
- LiteManageScreen gọn.
- LiteBracketSeedScreen.
- LiteQrShareSheet.

Luôn giữ UI tiếng Việt rõ ràng.

## 13. API Đề Xuất

Có thể dùng lại service hiện có bên trong, nhưng nên có endpoint lite riêng để contract gọn.

### Tournament Lite

```text
POST /tournaments/lite
GET /tournaments/lite/:id
PATCH /tournaments/lite/:id
POST /tournaments/lite/:id/publish
POST /tournaments/lite/:id/close-registration
POST /tournaments/lite/:id/open-registration
```

### Join Lite

```text
GET /tournaments/lite/join/:inviteCode
POST /tournaments/lite/join/:inviteCode
POST /tournaments/lite/:id/regenerate-invite
```

### Participants Lite

```text
GET /tournaments/lite/:id/participants
PATCH /tournaments/lite/:id/participants/:participantId/status
DELETE /tournaments/lite/:id/participants/:participantId
PATCH /tournaments/lite/:id/participants/:participantId/seed
```

### Bracket Lite

```text
POST /tournaments/lite/:id/bracket/random
POST /tournaments/lite/:id/bracket/seeded
PATCH /tournaments/lite/:id/bracket/seeds
POST /tournaments/lite/:id/bracket/generate
POST /tournaments/lite/:id/bracket/reset
GET /tournaments/lite/:id/bracket
```

### Match Lite

```text
GET /tournaments/lite/:id/matches
PATCH /matches/:matchId/lite-schedule
PATCH /matches/:matchId/lite-referee
POST /matches/:matchId/lite-start
PATCH /matches/:matchId/lite-score
POST /matches/:matchId/lite-complete
```

## 14. Data Cần Thêm Hoặc Chuẩn Hóa

Trong `tournamentConfig`:

```json
{
  "mode": "LITE",
  "sportPreset": "PICKLEBALL_STANDARD",
  "registrationMode": "OPEN",
  "liteJoinPolicy": "COMMUNITY_MEMBERS",
  "liteVisibility": "COMMUNITY",
  "bracketSetupMode": "RANDOM",
  "allowPlayerReferee": true,
  "hideAdvancedSettings": true
}
```

Trong participant:

```json
{
  "seed": 1,
  "teamStatus": "COMPLETE",
  "isLiteParticipant": true
}
```

Trong match:

```json
{
  "liteRefereeUserId": "user-id",
  "liteRefereeSource": "PLAYER"
}
```

## 15. Edge Cases Cần Bắt Chuẩn

- Quét QR nhưng chưa đăng nhập.
- Login xong mất return URL.
- Chưa là thành viên CLB.
- CLB cần duyệt.
- CLB chỉ mời.
- Giải đầy.
- Giải đã đóng đăng ký.
- Người dùng đã tham gia rồi.
- Đội thiếu đồng đội.
- Đồng đội đã tham gia giải.
- Random bracket khi chưa đủ 2 người.
- Reset bracket khi đã có trận completed.
- Gán trọng tài là người không có trong CLB/giải.
- Trọng tài đang là người chơi của chính trận đó: cần cho phép hay cần cảnh báo tùy setting.

Khuyến nghị:

- Lite cho phép người chơi làm trọng tài, nhưng nếu trọng tài là người trong trận đó thì hiện cảnh báo: "Người này đang thi đấu trong trận này".

## 16. Phase Triển Khai

### Phase 1: Chuẩn Hóa Contract Lite

- Chuẩn hóa payload `POST /tournaments/lite`.
- Lưu `mode=LITE` trong `tournamentConfig`.
- Thêm preset theo môn ở backend.
- Trả về `inviteCode`, `joinUrl`, `qrPayload`.
- Đảm bảo app và web cùng parse một contract.

### Phase 2: Tạo Giải Lite Mới

- App refactor màn tạo giải CLB thành create lite dùng preset.
- Web tạo route create lite riêng.
- Tạo xong hiện QR/link.
- Không đưa người dùng vào organizer full.

### Phase 3: Join Lite Bằng QR/Web

- App thêm `LiteJoinScreen`.
- Web thêm `/lite/tournaments/join/[inviteCode]`.
- Bắt đăng nhập trước khi tham gia.
- Xử lý membership CLB theo OPEN/APPROVAL/INVITE_ONLY.
- Một chạm tham gia nếu hợp lệ.

### Phase 4: Quản Lý Người Tham Gia Lite

- Tab người tham gia.
- Duyệt/từ chối nếu approval.
- Xóa participant khi chưa bắt đầu.
- Gán seed thủ công.

### Phase 5: Bracket Lite

- Random bracket.
- Seed theo ELO.
- Kéo thả xếp tay.
- Sơ đồ bracket trong app và web.
- Reset bracket có điều kiện an toàn.

### Phase 6: Trận Đấu Và Trọng Tài Lite

- Gán người chơi/thành viên CLB làm trọng tài.
- Mở trận/chấm điểm nhanh.
- Lịch trận đơn giản.
- Cập nhật kết quả/bracket realtime hoặc refresh nhanh.

### Phase 7: Polish UI/UX

- QR share sheet đẹp.
- Landing join web gọn.
- Empty state rõ.
- Lỗi API thân thiện.
- Copy đúng ngôn ngữ: "Tham gia", "Chờ duyệt", "Đã vào giải", "Tạo sơ đồ".

## 17. Việc Không Làm Trong Lite

- Không làm multi-division phức tạp trong phase đầu.
- Không làm thanh toán/phí nặng.
- Không làm ops audit đầy đủ như web full.
- Không làm permission matrix riêng.
- Không bắt cấu hình luật điểm quá sâu.
- Không copy nguyên trang organizer manage full.

## 18. Kết Luận

Lite Tournament nên là sản phẩm riêng: nhanh, để mọi người tham gia, bracket nhìn được ngay, BTC quản lý vừa đủ. Web full giữ vai trò hệ thống chuyên nghiệp; app/web lite giữ vai trò giải CLB giao hữu, nội bộ, vận hành nhẹ.
