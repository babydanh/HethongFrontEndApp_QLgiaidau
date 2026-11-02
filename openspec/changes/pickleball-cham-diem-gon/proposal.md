## Why

Màn chấm điểm pickleball của App đang dùng quá nhiều nút và chữ: thanh điểm nằm ngoài sân, khối số lớn thứ hai bên dưới (điểm hiện hai lần), hàng ba icon công cụ, thanh nút chữ "Ngoại lệ / Xử thắng / CHỐT SET / CHỐT TRẬN ĐẤU", hai nút chữ "Đổi lượt giao" và "Mất quyền giao". Sân luôn vẽ ngang 2:1 kể cả khi cầm dọc nên chiếm nửa màn hình, phần còn lại trống. Trọng tài khó thao tác nhanh bằng một tay.

Bản mẫu Lavish (`pickleball-app-flutter.html`, đã duyệt qua nhiều vòng với người dùng) cho thấy hướng gọn hơn: điểm nằm trong sân, nút là icon, một nút cúp mở popup chọn đội thắng, sân dựng dọc khi cầm dọc.

## What Changes

- **Điểm trong sân:** `−`, số điểm, `+` của mỗi đội nằm trong dải bếp của nửa sân đó (giống Web). Bỏ thanh điểm phía trên sân và bỏ khối số lớn (`PickleballPanel`, `RallyScorePanel`) ở tab Tính điểm khi có sân.
- **Sân dựng dọc khi cầm dọc:** đội trên / đội dưới, lưới nằm ngang; cầm ngang giữ sân ngang 2:1. Ô phải/trái và bếp xoay theo hướng nhìn của từng đội. Kéo thả chip và trái bóng giữ nguyên.
- **Cột/dải lưới toàn icon:** lời hô (vd. `11-0-2`), nút ⋯, nút ✓ chốt set, nút cúp thắng trận, nút mất giao. Không còn nút chữ nào trong vùng chấm điểm.
- **Nút cúp:** bấm mở popup "Chọn đội thắng" với hai nút tên đội; chạm tên đội là lưu trận.
- **Menu ⋯:** Đổi sân, Hoàn tác chỉnh sân, Khôi phục tự động, Tự đổi sân (bật/tắt), Ngoại lệ (chỉ Strict), Xử thắng (khi nơi gọi cung cấp).
- **Bỏ thanh nút dưới cùng** của màn chấm điểm đối với pickleball có sân; lý do ngoại lệ nhập ngay trong popup chốt set / chọn đội thắng.
- **Preset Lite hiển thị sân:** chạy kiểu rally, không có Mất giao / số giao, không có Ngoại lệ (giống Web: Lite không áp luật Strict).
- Mất giao hợp một nút: người giao 1 thua pha thì chuyển cho đồng đội (người giao 2), người giao 2 thua pha thì mất giao sang đội kia.

## Out of scope

- Không đổi luật tính điểm, luật side-out, luật set Strict, API hay dữ liệu lưu server (`courtState`, `sideOutState` giữ nguyên).
- Không đổi màn của môn khác (tennis, cầu lông, bóng bàn, bóng đá) và thanh nút dưới của các môn đó.
- Không đổi tab "Phạm lỗi" ngoài việc tab vẫn hoạt động như cũ.
- Không sửa Web/Backend. Chênh lệch App–Web về số giao sau mỗi điểm (App đặt lại về 1) và cờ "đội giao đầu chỉ một lượt" ghi vào `design.md` để người dùng quyết, không sửa trong change này.
- Không chạy thử trên thiết bị thật; kiểm bằng widget test và ảnh chụp mô phỏng.

## Capabilities

### New Capabilities
- `pickleball-court-scoring`: bố cục và thao tác chấm điểm pickleball trên sân (điểm trong sân, sân dọc/ngang, nút icon, popup chọn đội thắng, menu ⋯, preset Lite).

### Modified Capabilities
(không có: chưa có spec chung cho màn này)

## Impact

- Sửa: `lib/features/match/widgets/pickleball_court_view.dart`, `pickleball_court_panel.dart`, `official_score_modal.dart`; xoá `court_score_layout.dart` (không còn dùng).
- Sửa `lib/features/match/notifiers/pickleball_court_notifier.dart` (Lite chạy rally).
- Thêm chuỗi vào `lib/l10n/app_vi.arb` và `app_en.arb`, rồi `flutter gen-l10n`.
- Test: cập nhật `test/match/pickleball_court_widget_test.dart`, thêm test mới cho sân dọc, menu, popup thắng.
- Repo khác: không bị ảnh hưởng (không đổi API).
