## 1. Bộ lọc định dạng

- [x] 1.1 Thêm state `_matchType` và hàng chip Định dạng; gửi `matchType` thật, ẩn chip Nam/Nữ và bỏ `genderRestriction` khi Đôi nam nữ. Tiêu chí: `flutter test --no-pub test/features/rankings/leaderboard_format_filter_test.dart` → exit 0 (test viết trước, đỏ rồi xanh)
  - Files: sửa `lib/features/rankings/screens/leaderboard_screen.dart` (state dòng ~34; `_rankingQuery` ~52-57; `query` ~106-111; hiển thị chip ~128; `_buildGenderFilter` ~193-243); tạo `test/features/rankings/leaderboard_format_filter_test.dart` (override `rankingsProvider`, bắt `RankingQuery` được gọi)
  - Giao: `_matchType` ∈ `''|'SINGLES'|'DOUBLES'|'MIXED_DOUBLES'`; `RankingQuery.matchType` = `_matchType`, `genderRestriction` = `null` khi `MIXED_DOUBLES` · Nhận: `rankingsProvider`, `RankingQuery` (`lib/providers/ranking_provider.dart`, không đổi), `buildRankingQueryParams` bỏ trường rỗng/null (không đổi)
  - Chủ file chung: 1.1 giữ `leaderboard_screen.dart`
  - Phụ thuộc: không

## 2. Hiển thị tên cặp

- [x] 2.1 Podium dùng `ranking.displayName`; ô tìm kiếm thêm tên từng VĐV trong `players` và `teamName`. Tiêu chí: `flutter test --no-pub test/features/rankings/pair_ranking_display_test.dart` → exit 0 (test viết trước, đỏ rồi xanh)
  - Files: sửa `lib/features/rankings/widgets/podium_view.dart:176` (và kiểm `_buildPodiumAvatar` ~250 vẫn tách đúng cặp bằng `/`); sửa `lib/features/rankings/screens/leaderboard_screen.dart` `_buildRankingsList` (haystack, ~246+); tạo `test/features/rankings/pair_ranking_display_test.dart`
  - Giao: không · Nhận: `PlayerRanking.displayName`, `players`, `teamName` (`lib/domain/entities/ranking.dart`, không đổi)
  - Chủ file chung: 1.1 giữ `leaderboard_screen.dart`; 2.1 chỉ đụng haystack sau khi 1.1 xong
  - Phụ thuộc: sau 1.1

## 3. Kiểm tra cuối

- [x] 3.1 Phân tích tĩnh và test liên quan. Tiêu chí: `flutter analyze --no-pub lib/features/rankings` → exit 0, không issue mới; `flutter test --no-pub test/features/rankings test/rankings` → exit 0
  - Files: không sửa file mới
  - Giao: không · Nhận: kết quả 1.1, 2.1
  - Chủ file chung: không
  - Phụ thuộc: sau 1.1, 2.1
