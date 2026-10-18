# Proposal

## Why

Run `39122493011` (app ref `a1753c5d` + `b0e41bb6`, orchestrator `886ac23`): ca VĐV đôi báo `ListTile background color or ink splashes may be invisible` (log `flutter-test.log`, dòng ~240–262) ở bước tìm đồng đội theo email.

Nguyên nhân nằm ở `lib/features/register/screens/doubles_registration_screen.dart` (dòng ~1092–1143). Danh sách kết quả tìm đồng đội là `Container` có `decoration` (nền `bgCard`, viền, bo góc 12) bao `ListView.separated`, và mỗi dòng là `ListTile(dense: true)`. `ListTile` vẽ ink lên Material gần nhất, mà giữa tile và Material đó có `DecoratedBox` của Container. Flutter (chế độ debug) báo lỗi và nền che hiệu ứng ink.

Cùng lớp lỗi với `fix-register-consent-listtile`, nhưng ở màn đôi và danh sách nhiều dòng.

## What Changes

- `lib/features/register/screens/doubles_registration_screen.dart`: bọc `ListView.separated` trong `Material(type: MaterialType.transparency)` đặt bên trong `Container`, có chú thích tại chỗ. Mọi `ListTile` của danh sách có Material gần nhất nằm trong decoration. `Container`, viền, bo góc, `maxHeight` và giao diện giữ nguyên.

### Out of scope (KHÔNG làm)

- Không đổi logic tìm kiếm, chọn đồng đội, hay giới hạn chiều cao 200.
- Không sửa `CheckboxListTile` của `football_team_register_screen.dart` và các chỗ khác không nằm trong Container có nền.
- Không sửa test để né assertion.
