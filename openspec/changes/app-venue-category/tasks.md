## 1. Repository
- [x] 1.1 Test đỏ: query có/không `categoryId`, `isVerified`, sắp theo khoảng cách (TC-VENUE-01..04)
- [x] 1.2 `categoryId` tuỳ chọn ở interface, 3 repo, fake test
- [x] 1.3 `SocialPlace.isVerified`, sắp xếp ưu tiên xác minh dưới 200 m

## 2. UI
- [x] 2.1 Truyền `categoryId` từ `create_social_screen` xuống `SocialLocationFlow`, tìm lại khi đổi môn
- [x] 2.2 Nhãn "Đã xác minh" (arb vi/en, gen-l10n); kiểm © OpenStreetMap vẫn hiện

## 3. Kiểm tra
- [x] 3.1 `flutter test --no-pub` các file liên quan
