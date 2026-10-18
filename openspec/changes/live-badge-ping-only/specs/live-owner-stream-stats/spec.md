## MODIFIED Requirements

### Requirement: The tournament creator and admins see stream stats on the live video

`LiveVideoPlayer` SHALL show a stats badge only when the viewer is an admin or the creator of the match's tournament. The badge SHALL read `Ping <n> ms`, and a Ping value not measured yet SHALL read `—`. Ping is refreshed every 5 seconds.

#### Scenario: Tournament creator

- **WHEN** the signed-in user's id equals the tournament's creator id and the stream is playing
- **THEN** the live video shows a badge containing `Ping` with an `ms` value

#### Scenario: Referee or viewer

- **WHEN** the signed-in user is neither an admin nor the tournament creator
- **THEN** the live video shows no stats badge

#### Scenario: Nothing measured yet

- **WHEN** the badge is shown before any manifest probe exists
- **THEN** it reads `Ping —`

### Requirement: Ping is measured only on an HLS manifest

The App SHALL measure Ping only when the playback URL's path ends with `.m3u8` (query string ignored). For any other playback URL, such as HTTP-FLV, the App SHALL send no request to measure Ping and SHALL show `Ping —`, because such a stream never finishes loading and would hold the connection open.

#### Scenario: HTTP-FLV playback URL

- **WHEN** the playback URL is `https://media.example.test/live/match-1.flv?token=abc`
- **THEN** the App sends no request to measure Ping and the badge reads `Ping —`

#### Scenario: HLS manifest with a query string

- **WHEN** the playback URL is `https://media.example.test/live/match-1.m3u8?token=abc` and the manifest returns within 4 seconds
- **THEN** the badge reads `Ping <n> ms`, where `<n>` is the time to receive the full manifest

## REMOVED Requirements

### Requirement: Trễ is media buffered ahead of the playhead, not camera latency

**Reason**: Người dùng bỏ chỉ số Trễ khỏi huy hiệu (18/10); huy hiệu chỉ còn Ping. Trễ chỉ là đệm phía App, không phải độ trễ camera, nên không giữ lại.

**Migration**: Không có chỉ số thay thế trong App. Huy hiệu không còn timer 1 giây và không đọc `controller.value.buffered`. Người xem không bị ảnh hưởng vì huy hiệu chỉ dành cho chủ giải và admin.

### Requirement: FPS comes from the stream-info endpoint and is never estimated on the device

**Reason**: Người dùng bỏ FPS khỏi huy hiệu (18/10). FPS chỉ cần phát đúng theo link HLS, không cần hiển thị; không có chỗ nào khoá FPS trong App hay Backend.

**Migration**: App không còn gọi `GET /livestream/matches/{matchId}/stream-info` và xoá model `MatchStreamInfoModel`. Backend gỡ endpoint này ở change riêng. Nếu sau này cần FPS, phải có requirement mới.
