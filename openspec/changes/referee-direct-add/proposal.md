## Why
Backend (change `referee-direct-add`) đổi nghiệp vụ: BTC thêm trọng tài là có quyền ngay (`ACCEPTED`), có thông báo `REFEREE_ADDED`/`REFEREE_REMOVED`, và gỡ được trọng tài đã thêm. App còn chữ "Gửi lời mời / Đã mời" và trọng tài `ACCEPTED` không có nút gỡ.

## What Changes
- `permission_rows.dart`: `RefereeAction.remove` cho `ACCEPTED`; mục Nhân sự mở sheet "Xóa" → xác nhận → `removeReferee(tournamentId, refereeId)` → snackbar `tournamentManagementRefereeRemoved`.
- Chữ ARB: "Đã thêm trọng tài.", nút "Thêm", "Thêm lại" cho `DECLINED`, mô tả mục Trọng tài.
- `AppNotification`: icon/màu cho `REFEREE_ADDED`, `REFEREE_REMOVED`; không coi là lời mời (không nút Nhận/Từ chối); bấm vào mở `/intro/<id>` qua `redirectUrl`.

## Out of scope
- Màn/ thẻ lời mời đang chờ ở Dashboard (dữ liệu `INVITED` cũ tự hết).
