## 1. App ẩn tên giải ở thẻ nổi bật
- [x] 1.1 Model đọc cờ và thẻ ẩn tên giải. Tiêu chí: `flutter test --no-pub test/features/featured_card_hide_text_test.dart` → exit 0
  - Files: sửa `lib/data/models/home_projection.dart`, `lib/features/home/widgets/featured_tournament_banner_card.dart`; test `test/features/featured_card_hide_text_test.dart`
  - Giao: `HomeFeaturedTournament.hideFeaturedCardText: bool` · Nhận: field `hideFeaturedCardText` trong `featuredTournaments` của `GET /tournaments/home` (change cùng tên ở Backend)
  - Chủ file chung: 1.1 giữ cả ba file
  - Phụ thuộc: (không; thiếu cờ thì giữ hành vi cũ)
