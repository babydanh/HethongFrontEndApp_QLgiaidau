# Tasks

## 1. Chẩn đoán

- [x] 1.1 Đọc log run `39120582151` (`flutter-test.log` dòng 202–214 và 378–390): assertion `ListTile background color or ink splashes may be invisible`; tile có `contentPadding: zero`, `onTap: _handleValueChange`, bên trong `DecoratedBox` nền `F8FAFC` viền bo góc 12. Khớp `CheckboxListTile` tại `tournament_register_screen.dart:2147`.
- [x] 1.2 Xác nhận đường đi: khối đồng ý chỉ hiện khi `t.isRanked`; log có dòng "Giải có xếp hạng" trên màn đăng ký giải E2E.

## 2. Sửa

- [x] 2.1 Bọc `CheckboxListTile` đồng ý xếp hạng trong `Material(type: MaterialType.transparency)`, có chú thích. Xong khi: `dart analyze lib/features/register/screens/tournament_register_screen.dart` sạch.

## 3. Kiểm trên cloud

- [ ] 3.1 Run `app-e2e` trên head chứa sửa: log không còn assertion `ListTile background color`, và ca VĐV đơn và đôi qua bước gửi đăng ký. Xong khi: có run id và log.
- [ ] 3.2 Run `app` trên cùng head: job analyze và widget success. Xong khi: có run id.
- [ ] 3.3 `npx openspec validate fix-register-consent-listtile --strict` exit 0. Xong khi: có exit code.
