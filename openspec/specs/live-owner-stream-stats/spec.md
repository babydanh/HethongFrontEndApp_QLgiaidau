# live-owner-stream-stats Specification

## Purpose
Huy hiệu thông số luồng (Ping, Trễ, FPS) trên video live của App, chỉ cho chủ giải và admin.

## Requirements

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

### Requirement: Ping probes are bounded in time and size

Ping SHALL be the time from sending the manifest GET until its complete body is received, in whole milliseconds. The probe SHALL use `ResponseType.plain` and a total timeout of 4 seconds. A body larger than 64 KB SHALL be cancelled with a `CancelToken`. A failed, timed-out or cancelled probe SHALL show `Ping —`.

#### Scenario: Manifest larger than 64 KB

- **WHEN** the manifest body exceeds 64 KB before it completes
- **THEN** the probe cancels the request and the badge reads `Ping —`

#### Scenario: Manifest not complete within 4 seconds

- **WHEN** the manifest does not finish loading within 4 seconds
- **THEN** the probe is cancelled and the badge reads `Ping —`
