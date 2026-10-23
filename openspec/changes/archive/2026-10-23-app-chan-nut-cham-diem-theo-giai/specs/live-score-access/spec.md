## ADDED Requirements

### Requirement: Nút chấm điểm theo quyền trên giải và trận

The match detail screen SHALL show the scoring button (start match or open scoreboard) for a tournament match only when the user is the tournament creator, the match's assigned referee, or a non-ADMIN user the backend `GET /matches/:id/score-access` allows. The Super Lite behaviour and the completed-match rule SHALL stay unchanged.

#### Scenario: ADMIN xem giải của người khác
- **WHEN** a signed-in ADMIN opens a match of a tournament they did not create and are not the assigned referee of
- **THEN** the scoring button is not shown, even if `score-access` returns `canScore: true`, because the backend grants admins `canScore` on every tournament

#### Scenario: Chủ giải hoặc trọng tài gán đúng trận
- **WHEN** the signed-in user id equals the tournament creator id or the match referee id
- **THEN** the scoring button is shown without waiting for `score-access`

#### Scenario: Người dùng khác có quyền theo backend
- **WHEN** a signed-in non-ADMIN user is neither creator nor assigned referee and `score-access` returns `canScore: true`
- **THEN** the scoring button is shown; when it returns false, errors, or is still loading, it is hidden

#### Scenario: Chưa đăng nhập
- **WHEN** no user is signed in
- **THEN** the scoring button is not shown
