## Why

Sân vợt tennis trong bảng chấm điểm App (`RacketCourtPanel`, modal chấm chính thức) chỉ giữ một lựa chọn người giao cho cả trận (`RacketServePick`), chỉ trong phiên, và lệch luật ITF 2026 ở tennis đôi: chọn lại người giao mỗi set (Luật 14), đôi nhận giữ vị trí cả set rồi khoá (Luật 15), sửa sai 27c/27e, No-Ad đôi nhận chọn người đỡ điểm quyết định (Phụ lục VI). Bản thử Lavish đã được duyệt ngày 22/11/2026.

## What Changes

- Thêm service thuần `lib/domain/services/tennis_serve_state.dart`: model `TennisCourtState` (fromJson/toJson) và các hàm tính người giao/người nhận/ô/khoá theo set, thao tác chọn và sửa sai.
- Tennis đôi trong notifier dùng trạng thái này thay cho `RacketServePick` match-level: chọn người giao xong người đứng ô phải đội kia tự là người nhận; đổi được tới trước điểm nhận đầu của set.
- Bấm ô VĐV mở menu (như pickleball): mục đã khoá đổi thành "Sửa sai"; No-Ad 40-40 có mục chọn người đỡ điểm quyết định; dòng nhắc dễ hiểu.
- Lưu và khôi phục qua `PATCH /api/v1/matches/:id/court-state` (`MatchRepository.updateCourtState`), đọc `scoreDetails['courtState']` khi mở lại; lỗi lưu giữ trạng thái trên máy và thử lại lần sau.
- Key l10n mới ở `lib/l10n/app_vi.arb` và `app_en.arb`, chạy `flutter gen-l10n`.

## Out of scope

- Không đổi cầu lông và tennis đơn (vẫn `RacketServePick`).
- Không đổi cách ghi điểm, tie-break, super tie-break (vẫn lưu 7-6) hay nút ±.
- Không đổi sân pickleball.
- Không chặn ghi điểm khi chưa chọn (mặc định người 0 / đội 1, có dòng nhắc).

## Capabilities

### New Capabilities
- `tennis-doubles-serve`: luật giao/nhận tennis đôi trên sân vợt App, lưu qua court-state.

### Modified Capabilities
(không có)

## Impact

- App: `lib/domain/services/tennis_serve_state.dart` (mới), `lib/features/match/notifiers/score_panel_state.dart`, `score_panel_racket.dart`, `score_panel_notifier.dart`, `lib/features/match/utils/racket_court_drag.dart`, `lib/features/match/widgets/racket_court_panel.dart`, `racket_court_view.dart`, `lib/l10n/app_vi.arb`, `app_en.arb`.
- Backend (change `tennis-doi-giao-luat`): `PATCH /api/v1/matches/:id/court-state` nhận `TennisCourtState` cho trận `TENNIS`; gộp Backend trước để lưu không bị 400.
- Web Next.js: cùng hợp đồng, change riêng `tennis-doi-giao-luat`.
