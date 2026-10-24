# live-score-tournament-start Specification

## Purpose
Cho người xem và người ghi điểm biết vì sao không chốt được điểm khi giải chưa khai mạc: lỗi TOURNAMENT_NOT_STARTED từ API được ánh xạ thành thông báo riêng cho giải đấu (khác với xung đột bản ghi 409 thường) và hiển thị đúng hai ngôn ngữ VI/EN trên màn chấm điểm, không kèm hành động mở giải trong App.

## Requirements

### Requirement: Distinguish tournament-not-started score errors
The App MUST preserve the API error code `TOURNAMENT_NOT_STARTED` as a typed domain error for tournament match score updates. The score notifier MUST display a localized tournament-not-started message before generic HTTP 409 revision-conflict handling. The App MUST NOT provide a tournament-launch action.

#### Scenario: Tournament has not started
- **WHEN** a tournament match score update returns HTTP 409 with code `TOURNAMENT_NOT_STARTED`
- **THEN** the notifier displays the localized tournament-not-started message, not the revision-conflict message.

#### Scenario: Revision conflict
- **WHEN** a score update returns another HTTP 409 error
- **THEN** the notifier retains the existing revision-conflict behavior.
