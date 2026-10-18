# Proposal

## Why

Run `39120582151` (app ref `a1753c5d`, orchestrator `886ac23`): ca VĐV đăng ký đơn và đôi trên giải có xếp hạng bị `flutter test` ném assertion khi vẽ màn đăng ký: `ListTile background color or ink splashes may be invisible` (log `flutter-test.log`, dòng 202–214 và 378–390).

Nguyên nhân nằm ở `lib/features/register/screens/tournament_register_screen.dart`, khối đồng ý xếp hạng (dòng ~2140–2165). `CheckboxListTile` (`_rankingConsent`) nằm trong `Container` có `decoration` (nền `bgSurface`, viền, bo góc 12). `ListTile` vẽ ink lên Material gần nhất. Nền nằm giữa tile và Material đó khiến Flutter (chế độ debug) báo lỗi, và theo thông điệp của Flutter, nền này che hiệu ứng ink.

Khối này chỉ hiện khi `t.isRanked` (giải có xếp hạng). Giải E2E là giải có xếp hạng, nên ca VĐV đi qua đường này.

## What Changes

- `lib/features/register/screens/tournament_register_screen.dart`: bọc `CheckboxListTile` đồng ý xếp hạng bằng `Material(type: MaterialType.transparency)`, có chú thích tại chỗ. `ListTile` có Material riêng gần nhất, nên assertion không còn. Nền và viền vẫn do `Container`, giao diện không đổi.

### Out of scope (KHÔNG làm)

- Không đổi giao diện, chữ hiển thị, hay logic đăng ký.
- Không sửa `CheckboxListTile` của trường tùy chỉnh (`_buildCustomFields`, dòng ~299–312): đường đi này không nằm trong container có nền, nên không gặp lỗi.
- Không sửa test để né assertion. Lỗi tap và cuộn của test nằm trong `app-e2e-integration` (task 4.2 và 4.3), không thuộc change này.
