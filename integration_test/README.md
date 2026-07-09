# Flutter Integration Tests

Test thật với backend NestJS — không mock.

## File Excel testcases

```
test_docs/testcases.xlsx  ← 195 test cases Flutter
test_docs/testcases.json  ← JSON cho test runner
```

## Cách chạy

```bash
# 1. Start backend
cd backend-api_qlgiaidau
pnpm start:dev

# 2. Chạy test + xuất kết quả JSON
cd app_quanly_giaidau
flutter test integration_test/ --machine > results.json

# 3. Cập nhật kết quả vào Excel
python test_docs/update-results.py results.json
```

## Chụp ảnh màn hình

Test tự động chụp ảnh khi chạy, lưu tại `test_screenshots/`:
- Mỗi bước đều có screenshot
- Khi test fail → screenshot có prefix `FAIL_`
- Ảnh được tham chiếu trong Excel (cột Screenshot)

## Test files

| File | Test cases |
|------|-----------|
| `flow_auth_test.dart` | Login, register, logout |
| `flow_club_lite_test.dart` | Tạo Lite tournament, xem CLB |
| `flow_profile_test.dart` | Profile, xoá giải |
| `helpers/test_utils.dart` | Helper login, logout, screenshot |

## Structure

```
app_quanly_giaidau/
  ├── integration_test/
  │   ├── flow_auth_test.dart
  │   ├── flow_club_lite_test.dart
  │   ├── flow_profile_test.dart
  │   └── helpers/test_utils.dart
  ├── test_docs/                  ← Test cases + script
  │   ├── testcases.xlsx          ← Excel master (195 tests)
  │   ├── testcases.json          ← JSON cho test runner
  │   └── update-results.py       ← Ghi kết quả vào Excel
  └── test_screenshots/           ← Screenshots (auto tạo)
```

## Mock note

- Không mock — test thật với backend
- Google Sign-In cần mock (không test được tự động)
- Token invite (ADM-xxx) cần tạo thủ công qua database
