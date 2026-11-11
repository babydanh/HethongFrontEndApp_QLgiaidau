## 1. Chia đội vào bảng
- [x] 1.1 Hàm thuần chia rắn theo ELO / ngẫu nhiên và ghép vào `roundConfig`. Tiêu chí: `flutter test --no-pub test/bracket_group_draw_test.dart test/features/group_stage_config_test.dart` → exit 0
  - Files: tạo `lib/features/bracket/utils/bracket_group_draw.dart`; sửa `lib/features/bracket/utils/group_stage_config.dart`; test `test/bracket_group_draw_test.dart`
  - Giao: `List<List<String>> drawBracketGroups({teams, numGroups, byElo, random})`, `Map<String,dynamic> withDrawnGroups(roundConfig, groups)` · Nhận: (không)
  - Phụ thuộc: không

## 2. Nối vào nút Tạo bracket
- [x] 2.1 `_create()` xếp đội trước khi lưu cấu hình, thử lại không kèm bảng khi Backend trả 400. Tiêu chí: `flutter test --no-pub test/features/bracket_management_bar_test.dart` → exit 0
  - Files: sửa `lib/features/bracket/widgets/bracket_management_bar.dart`; test `test/features/bracket_management_bar_test.dart`
  - Giao: (không) · Nhận: `drawBracketGroups`, `withDrawnGroups`
  - Phụ thuộc: sau 1.1

## 3. E2E
- [ ] 3.1 TC-53 kiểm không còn làn "Chưa xếp". Tiêu chí: `cloud-test-runner.py run --target app-e2e --specs integration_test/organizer_formats_journey_test.dart` → xanh (chạy trên cloud)
  - Files: sửa `integration_test/organizer_formats_journey_test.dart`
  - Phụ thuộc: sau 2.1
