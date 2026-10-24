## Why

Khi Backend từ chối cập nhật điểm của trận thuộc giải chưa khai mạc bằng HTTP 409 `TOURNAMENT_NOT_STARTED`, App hiện biến lỗi thành chuỗi thường rồi hiểu nhầm là xung đột revision. Người dùng không được biết cần chờ giải khai mạc.

## What Changes

- Giữ mã `TOURNAMENT_NOT_STARTED` dưới dạng lỗi domain có kiểu qua repository.
- Score notifier nhận diện lỗi này trước nhánh 409 revision-conflict và hiển thị thông báo khai mạc đã bản địa hóa tiếng Việt/Anh.
- Thêm regression test notifier xác nhận thông báo riêng và không hiển thị thông báo revision conflict.

## Feature Impact Review

- **Route/screen:** Live score screen and score panel; no route change.
- **Role/permission:** Existing match authorization remains enforced by Backend before the not-started rejection; App does not grant or bypass permission.
- **State transition:** Score submission remains loading while pending; API rejection returns to the existing editable state with a dedicated tournament-not-started error. Network/unknown failures retain generic error handling.
- **Button behavior:** Existing score controls remain; no tournament-launch button. Existing submission guard continues preventing duplicate writes.
- **Negative cases:** Unauthorized writes remain Backend-denied; network errors remain generic; HTTP 409 with another code remains revision conflict; duplicate taps are covered by existing submitting guard.
- **Web/App parity:** Web and Backend changes are out of this App-only scope; App aligns with the shared `TOURNAMENT_NOT_STARTED` error code.
- **Decision:** GO for App error mapping, localized feedback and regression coverage.

## Out of scope

- Không thêm nút khai mạc trong App.
- Không đổi Web hoặc Backend, không đổi contract API.

## Source of truth

Backend error code `TOURNAMENT_NOT_STARTED` trong API response là căn cứ máy đọc; App chỉ ánh xạ mã này sang lỗi domain và chuỗi địa phương.