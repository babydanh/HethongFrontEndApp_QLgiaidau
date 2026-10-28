## ADDED Requirements

### Requirement: Xác nhận kết quả giải có điều kiện và hộp xác nhận
The end-of-tournament sheet SHALL show the podium of ranks 1 to 3, the prize description and the conditions, SHALL disable the confirm button with a red reason while a match is live, and SHALL ask a confirmation dialog that states the consequence before calling `complete`.

#### Scenario: Còn trận đang diễn ra
- **WHEN** a match is live
- **THEN** the confirm button is disabled and a red line states the number of live matches

#### Scenario: Huỷ hộp xác nhận
- **WHEN** the organizer taps confirm and cancels the dialog
- **THEN** `complete` is not called

### Requirement: Chốt lại kết quả khi Backend yêu cầu
When the tournament is completed and the results snapshot has `needsReconfirm` true, the app MUST offer an action that calls `POST /tournaments/:id/results/confirm` and MUST NOT offer it otherwise.

#### Scenario: Chốt lại thành công
- **WHEN** the organizer taps the reconfirm action and confirms
- **THEN** the app posts to `/tournaments/:id/results/confirm` once
