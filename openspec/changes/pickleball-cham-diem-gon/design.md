## Context

Màn chấm điểm là `OfficialScorePage` (`official_score_modal.dart`). Tab "Tính điểm" của pickleball ghép `PickleballCourtPanel` (sân, nối notifier) với một panel số điểm (`PickleballPanel` side-out hoặc `RallyScorePanel`) bằng `CourtScoreLayout`. Thanh nút dưới (Ngoại lệ, Xử thắng, CHỐT SET, CHỐT TRẬN) nằm trong modal và dùng chung cho mọi môn.

## Hướng chọn

1. **Điểm vào dải bếp.** `PickleballCourtView` vẽ `−`/số/`+` trong dải bếp mỗi nửa sân, bỏ `_ScoreBar` và `_CourtTools`. Callback `onScoreChange` giữ nguyên chữ ký.
2. **Hai hướng sân.** Thêm `Axis courtAxis` cho view. Dọc: hai nửa xếp trên/dưới, mỗi nửa là `Column[ô, bếp]` (nửa trên) hoặc `Column[bếp, ô]` (nửa dưới); hai ô của một nửa nằm cạnh nhau. Nhìn về lưới: nửa trên phải = bên trái màn hình, nửa dưới phải = bên phải màn hình. Ngang: giữ nguyên bố cục hiện tại (nửa trái: ô trái ở trên; nửa phải: ô phải ở trên). Modal chọn hướng theo `Orientation`.
3. **Icon ở lưới.** `_NetControls` là cột (ngang) hoặc hàng (dọc) nằm trong dải lưới, thứ tự: ⋯, lời hô, ✓ chốt set, cúp, mất giao. Mỗi icon có tooltip và `Semantics` đọc được; vùng chạm tối thiểu 44dp.
4. **Logic chốt set / thắng trận nằm ở `PickleballCourtPanel`.** Panel đã có `params`, `ref` và notifier nên dựng các hộp thoại ở đây (chốt set, chọn đội thắng, lý do ngoại lệ) thay vì kéo ra thanh nút của modal. View chỉ nhận callback (`onFinishSet`, `onPickWinner`, `onLoseServe`, `onForceWin`, `onToggleOverride`).
5. **Modal.** Với pickleball có sân: không dựng panel số điểm và không dựng thanh nút dưới. Các môn khác không đổi. Cầm ngang gộp dải set đã chốt vào hàng tiêu đề để nhường chiều cao cho sân.
6. **Lite.** Modal truyền `isLite` cho `PickleballCourtPanel`; panel tắt side-out (không số giao, không Mất giao), ẩn Ngoại lệ. `pickleballCourtContextProvider` coi Lite là rally.

## Phương án đã loại

- **Xoay sân ngang 90° bằng `RotatedBox`/`Transform`:** chữ và chip bị quay ngang, kéo thả và vùng chạm lệch. Loại.
- **Giữ thanh nút dưới, chỉ đổi thành icon:** vẫn chiếm một hàng cao và lặp việc với nút trên sân. Loại.
- **Đặt menu ⋯ ở tiêu đề modal:** menu cần gọi hành động sân qua hàng đợi ghi server của `PickleballCourtPanel`; đặt trong view thì dùng thẳng callback có sẵn. Chọn đặt trong dải lưới.

## Chênh lệch App–Web cần người dùng quyết (không làm trong change này)

| Điểm | Web | App hiện tại |
|---|---|---|
| Số giao sau mỗi điểm | giữ theo lượt | đặt lại về 1 (`pickleballAwardPoint`) |
| Đội giao đầu | cờ "chỉ một lượt" mở màn, mất giao đầu đổi đội ngay | không có cờ, nút "đổi lượt giao" luôn cho 1→2 |
| Chọn đội thắng ở Lite | chọn đội nào cũng được | `canCompleteAs` yêu cầu đội đó dẫn số set |

Popup chọn đội thắng dùng `canCompleteAs` của App (nút của đội chưa đủ điều kiện bị khoá và có dòng giải thích), tức giữ hành vi App hiện tại.

## Rủi ro

- Test widget hiện có 1394 dòng gắn với thanh điểm và hàng công cụ; phải cập nhật theo bố cục mới.
- Sân dọc làm lệch hướng "ô phải/trái": có test riêng cho từng hướng.
- Màn ngang thấp: ngang chỉ ~200dp cao cho sân; dải lưới 5 icon cần vừa chiều cao đó (đo bằng test 800x360).
