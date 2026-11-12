# Handoff ho-so-gon-xem-them (App)

## Đã làm
- App chưa có mục "Giải tôi tổ chức" ở hồ sơ nên thêm mới trong tab Giải đấu: `lib/features/profile/widgets/organized_tournaments_section.dart`, provider `lib/providers/organized_tournaments_provider.dart` (AsyncNotifier autoDispose, 4/trang, cờ `isLoadingMore` trong state chống bấm đúp, lỗi giữ danh sách + "Thử lại"), gắn ở `profile_screen.dart` (`_buildTournamentsTab`). Tái dùng `_tournamentRow` (logo, ngày, pill trạng thái màu).
- `getMyWorkspace` thêm `role` tuỳ chọn (interface + `api_tournament_repository.dart`), chỉ gửi khi có.
- l10n: `profOrgTitle`, `profOrgLoadMore`, `profOrgRetry` ở `app_vi.arb`/`app_en.arb`, chạy `flutter gen-l10n`.
- Kiểm lỗi kiểu `matchesWithUser`: App sinh method l10n có tham số bắt buộc nên không có lỗi tương tự.

## Lệnh test (thật)
- `flutter test --no-pub test/profile/organized_tournaments_section_test.dart` → exit 0, 6 pass (TC-PROFILE-ORG-01..06).
- `flutter test --no-pub test/profile test/data/api_tournament_repository_gaps_test.dart` → exit 0, 98 pass.
- `flutter analyze --no-pub <thư mục đã sửa>` → 0 error/warning, 16 info `deprecated_member_use` (SDK 3.50 cài tạm mới hơn repo).

## Chỗ chưa chắc
- Máy không có Flutter: đã cài SDK stable vào `/data/home/flutter-sdk` và chép `.env.example` thành `.env` (gitignored). `pubspec.lock` và 2 file `windows/flutter/*` bị `pub get` sửa nhưng KHÔNG commit.
- Chưa xem bằng mắt trên thiết bị/ảnh; chưa làm gọn thêm các khối khác của App vì App không có ô CLB/đối thủ giống Web.
