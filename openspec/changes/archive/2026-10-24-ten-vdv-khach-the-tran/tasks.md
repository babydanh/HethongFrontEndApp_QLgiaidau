# Tasks

## 1. VĐV khách trong dữ liệu trận

- [x] 1.1 Helper nối `participantN.guestNames` (bỏ chuỗi rỗng) sau `members` thành `MatchMemberInfo(fullName)`; dùng ở `api_match_repository.dart` và `match.dart`. Xong khi: unit test parse trận có `members: []`, `guestNames` 2 tên → `team1MemberInfos` đúng 2 tên đúng thứ tự; không có `guestNames` → như cũ.

## 2. Hiển thị

- [x] 2.1 Thẻ trận Trang chủ: đội khách hiện 2 vòng tròn chữ viết tắt theo tên từng VĐV. Xong khi: test widget `live_tournament_with_matches_card_test.dart` ca cặp khách thấy "MA", "QB", không thấy "CP".
- [x] 2.2 Chi tiết trận: đội khách hiện 2 vòng tròn dưới tên đội, nhãn "ELO Đôi", ô khách không bấm được (vẽ bằng `CircleAvatar`, không phải `UserAvatarTap`). Xong khi: `test/match/live_score_team_athletes_test.dart` ca cặp khách thấy "N", "T" trong `CircleAvatar` và "Doubles ELO".
- [x] 2.3 Nhãn bảng giống Web: "Bảng B • Lượt 1" (ngắn "Bảng B"); "Bảng A" không lặp chữ; lượt về "Lượt 2". Key l10n ở `app_vi.arb`, `app_en.arb`, chạy `flutter gen-l10n`. Xong khi: unit test `MatchRoundLabel` 3 ca trong spec PASS.
- [x] 2.4 Tên đội "A / B" không kèm VĐV hiện 2 vòng tròn như Web (thẻ Trang chủ và Chi tiết trận tách theo "/"). Xong khi: test widget thẻ trận ca "Phan Anh Khoa / Hồ Minh Trí" thấy "AK", "MT", không thấy "PA"; `live_score_team_athletes_test.dart` thấy "P", "H".

## 3. Kiểm chứng

- [x] 3.1 `flutter analyze --no-pub` các file sửa không lỗi; `flutter test --no-pub` test mới và test liên quan PASS.

## Workflow follow-up (sau khi Backend `guest-names-tran-dau` deploy, không chặn gộp)

- Smoke trên máy: Trang chủ "Giải Thứ 4 giao lưu VNDC" và Chi tiết trận CLB Pickleball Sài Gòn – Biên Hòa Pickleball hiện 2 vòng tròn VĐV mỗi đội (ảnh chụp). Trước khi Backend deploy, App hiện như cũ với đội khách.
