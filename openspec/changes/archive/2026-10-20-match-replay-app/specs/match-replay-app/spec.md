# match-replay-app Specification

## Purpose
Cho phép người xem xem lại trận đã đấu trên App qua các đoạn MP4 như một bản phát liên tục.

## ADDED Requirements

### Requirement: Completed match replay is available when recordings exist
Khi trận không có nguồn phát trực tiếp, App SHALL tải `GET /api/v1/livestream/matches/:matchId/replay`. App SHALL hiển thị player phát lại khi `available` là `true` và có segment hợp lệ. Segment không có URL HTTPS hợp lệ SHALL bị loại khi parse.

#### Scenario: Completed match has a replay
- **WHEN** trận không live và replay trả `available: true` với segment URL HTTPS hợp lệ
- **THEN** App hiển thị player replay thay cho khung không có tín hiệu

#### Scenario: Replay is unavailable or match is unfinished
- **WHEN** replay trả `available: false`, `NOT_FINISHED`, hoặc không còn segment hợp lệ
- **THEN** App giữ nguyên khung không có tín hiệu hiện tại và không hiển thị player replay

### Requirement: Replay uses one global timeline
Player SHALL provide a seekable timeline from `0` to `durationSec` and map each global position to a segment and elapsed offset.

#### Scenario: Seeking across a segment boundary
- **WHEN** người xem tua đến vị trí thuộc segment tiếp theo
- **THEN** player chuyển segment, seek theo offset cục bộ và tiếp tục hiển thị thời gian toàn cục

#### Scenario: Timeline position maps to an estimated gap
- **WHEN** thời gian tua nằm trong khoảng trống giữa hai segment ước tính
- **THEN** player chuyển đến đầu segment kế tiếp

### Requirement: Clip playback respects the match window
Each segment SHALL play only `[clipStartSec, clipStartSec + durationSec)`. Starting a segment SHALL seek to `clipStartSec`; seeking SHALL add the elapsed offset to that value.

#### Scenario: First segment includes footage before the match
- **WHEN** segment đầu có `clipStartSec` lớn hơn 0
- **THEN** player seek `clipStartSec` trước khi phát và timeline bắt đầu ở 0

#### Scenario: Final recording file extends past its estimated window
- **WHEN** segment cuối đạt `clipStartSec + durationSec` trước khi hết tệp
- **THEN** player dừng ở biên `durationSec` và không phát phần tệp còn lại

### Requirement: Segment transitions are buffered and dispose resources
Player SHALL prepare the next controller when khoảng 10 giây còn lại, chuyển khi segment kết thúc, bỏ qua segment lỗi với thông báo nhỏ, và dispose controller cũ.

#### Scenario: Segment ends or fails
- **WHEN** một segment kết thúc hoặc không tải/phát được
- **THEN** player phát segment hợp lệ kế tiếp, giải phóng controller cũ và báo nhỏ nếu bỏ qua lỗi

#### Scenario: Final segment completes
- **WHEN** segment cuối kết thúc hoặc đạt giới hạn thời lượng
- **THEN** player dừng ở cuối timeline và giải phóng controller phát
