# Tasks

- [x] Thêm model `MatchReplay`/`MatchReplaySegment` parse an toàn; bỏ segment thiếu hoặc URL không hợp lệ; test model.
- [x] Thêm `getMatchReplay(matchId)` vào repository domain/API và provider DI; test endpoint/envelope.
- [x] Thêm hàm thuần ánh xạ thời gian timeline chung sang segment/offset và media time có `clipStartSec`, gồm biên/cuối clip; unit test.
- [x] Thêm player replay responsive: seek timeline theo `[clipStartSec, clipStartSec + durationSec)`, prebuffer controller kế tiếp ở ngưỡng 10 giây, chuyển/skip lỗi và dispose đúng vòng đời; i18n vi/en.
- [x] Tích hợp replay vào `LiveVideoBox` khi không live; widget test fake repository cho available và `NOT_FINISHED`.
- [x] Chạy ba lệnh `flutter test --no-pub` cho test mới, `dart analyze` cho file Dart đã sửa và `openspec validate match-replay-app --strict` — tất cả pass.