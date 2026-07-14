# Test Cases: Flutter Modules - Bracket, Match/Score, Ranking, Tournament Intro

---

## 1. BRACKET MODULE

---

### TC-FLUTTER-BRACKET-001: BracketViewScreen - Single Elimination Layout
- **Module**: bracket
- **Screen**: BracketViewScreen
- **Preconditions**: Tournament with single elimination bracket type; matches exist in DB; user is authenticated
- **Steps**:
  1. Navigate to BracketViewScreen with a single-elimination tournament ID
  2. Observe the screen layout
  3. Verify the app bar title displays the tournament name
  4. Verify the "So do nhanh dau Knockout" info card is shown
  5. Click "Xem so do" button
- **Expected**: App bar shows tournament name; info card is present; button navigates to BracketDiagramScreen; match list is rendered with rounds, round names, status indicators, set scores; orientation is allowed in both portrait and landscape
- **Edge cases**: Tournament name is empty string; tournament name is very long; tournament data is null

---

### TC-FLUTTER-BRACKET-002: BracketViewScreen - Double Elimination Layout
- **Module**: bracket
- **Screen**: BracketViewScreen
- **Preconditions**: Tournament with double elimination bracket type
- **Steps**:
  1. Navigate to BracketViewScreen
  2. Observe matches rendered with bracket tree (winners/losers separation)
- **Expected**: Matches are grouped into winners bracket and losers bracket; round names display "Nhanh Thang" / "Nhanh Thua" prefix; Grand Final and Bracket Reset matches are shown separately; SeparatedBuchheimWalkerAlgorithm shifts losers bracket nodes vertically
- **Edge cases**: No loser bracket matches exist yet; grand final reset match has status `pending_if_necessary`

---

### TC-FLUTTER-BRACKET-003: BracketViewScreen - Round Robin Layout
- **Module**: bracket
- **Screen**: BracketViewScreen
- **Preconditions**: Tournament with round robin bracket type; 3 tabs (Lich thi dau, Bang xep hang, Bang cheo) appear
- **Steps**:
  1. Navigate to BracketViewScreen
  2. Observe TabBar with 3 tabs
  3. Tap each tab
- **Expected**: Tab "Lich thi dau" renders horizontal rounds layout via `_buildHorizontalRounds`; Tab "Bang xep hang" renders standings DataTable via `standingsProvider`; Tab "Bang cheo" renders CrossTableView widget
- **Edge cases**: No matches exist (empty state shown); only 1 team in tournament; matches have no scores yet

---

### TC-FLUTTER-BRACKET-004: BracketViewScreen - Match Filtering (All / Live / Scheduled / Completed)
- **Module**: bracket
- **Screen**: BracketViewScreen
- **Preconditions**: Multiple matches with various statuses exist
- **Steps**:
  1. Observe filter chips: "Tat ca", "Dang Live", "Sap dien ra", "Da ket thuc"
  2. Tap each chip
- **Expected**: `_matchFilter` state updates; match list filters accordingly; chip count badges update dynamically (e.g., "Dang Live (2)"); empty state text "Khong co tran dau nao" shown when no matches match filter
- **Edge cases**: All matches are the same status; filter changes to status with zero matches; rapidly switching between filters

---

### TC-FLUTTER-BRACKET-005: BracketViewScreen - Match Table Row Rendering
- **Module**: bracket
- **Screen**: BracketViewScreen (match table row)
- **Preconditions**: Match with data including sets, scores, scheduledTime, court exists
- **Steps**:
  1. Scroll to a match row in the list
  2. Observe round name, status indicator, team names, set scores, total score, time/location
- **Expected**: Round name is computed correctly (Vong 1 / Chung ket); status labels (Dang thi dau / Da ket thuc / Chua thi dau) with appropriate colors; team row shows overlapping avatars; set columns show hyphen for unplayed sets; total score box highlights winner green; winner gets bold name weight; footer shows calendar + location icons; scheduledTime formatted as HH:mm - dd/MM/yyyy
- **Edge cases**: `team1Name` contains hyphen or newline for double-partner names; `scheduledTime` is null (shows "Chua xep lich"); `court` is empty; match is live (red border glow)

---

### TC-FLUTTER-BRACKET-006: BracketViewScreen - Match Row Referee Indicator
- **Module**: bracket
- **Screen**: BracketViewScreen
- **Preconditions**: `isReferee` is true; match is live or scheduled
- **Steps**:
  1. Observe match row footer
- **Expected**: "Tinh diem" label with arrow icon appears at the right of the row; color is red for live, primary for scheduled
- **Edge cases**: `isReferee` is false (no indicator); match is completed (indicator hidden)

---

### TC-FLUTTER-BRACKET-007: BracketViewScreen - Standings DataTable
- **Module**: bracket
- **Screen**: BracketViewScreen (standings tab)
- **Preconditions**: Standings data is available via `standingsProvider`
- **Steps**:
  1. View Round Robin -> "Bang xep hang" tab
  2. Observe the DataTable
  3. Tap info icon
- **Expected**: DataTable columns: Hang, Doi, Tran, T, H, B, BT, BB, HS, Diem; each row shows rank number, team name, stats; info icon opens AlertDialog explaining the coefficient abbreviations (T=Thang, H=Hoa, B=Bai, BT=Ban Thang, BB=Ban Bai, HS=Hieu so)
- **Edge cases**: Standings list is empty (shows "Chua co du lieu bang xep hang"); some teams have zero matches played

---

### TC-FLUTTER-BRACKET-008: BracketViewScreen - Empty State
- **Module**: bracket
- **Screen**: BracketViewScreen
- **Preconditions**: No matches exist for the tournament
- **Steps**:
  1. Navigate to BracketViewScreen with a tournament that has no matches
- **Expected**: AccountTree icon displayed; text "Chua co tran dau nao" and "Hay boc tham de tao so do thi dau" shown
- **Edge cases**: Tournament exists but matches data is empty list; network error during fetch (shows error state)

---

### TC-FLUTTER-BRACKET-009: BracketViewScreen - Landscape Orientation Lock
- **Module**: bracket
- **Screen**: BracketViewScreen
- **Preconditions**: Screen is opened
- **Steps**:
  1. InitState: SystemChrome.setPreferredOrientations enables portrait + landscape
  2. Rotate device to landscape
  3. Dispose screen
- **Expected**: Bracket screen allows landscape; on dispose, orientation locks back to portrait only
- **Edge cases**: Rapidly opening/closing the screen; multiple bracket screens in navigation stack

---

### TC-FLUTTER-BRACKET-010: BracketViewScreen - InteractiveViewer Navigation
- **Module**: bracket
- **Screen**: BracketViewScreen
- **Preconditions**: Matches exist; knockout bracket layout rendered
- **Steps**:
  1. Pan the bracket tree with touch/drag
  2. Pinch to zoom
  3. Use keyboard arrow keys
- **Expected**: InteractiveViewer allows panning with `_transformationController`; keyboard arrows (up/down/left/right) translate the view by 100px per press; minScale=0.1, maxScale=2.0; boundary margin of 500px
- **Edge cases**: Keyboard shortcuts work when FocusableActionDetector is focused; matches list is empty

---

### TC-FLUTTER-BRACKET-011: BracketViewScreen - AppBar Back Navigation
- **Module**: bracket
- **Screen**: BracketViewScreen
- **Preconditions**: User is admin OR regular user
- **Steps**:
  1. Tap back arrow
- **Expected**: If `isEmbedded` is true, back arrow is hidden (SizedBox.shrink); if admin role, navigates to `/admin/tournament/{id}`; if regular user, navigates to `/home`; logout button shown only for non-admin non-embedded users
- **Edge cases**: `isEmbedded` true and user tries to navigate via system back; role is viewer

---

### TC-FLUTTER-BRACKET-012: AutoDrawScreen - Auto Draw Generation
- **Module**: bracket
- **Screen**: AutoDrawScreen
- **Preconditions**: Tournament exists; teams are registered; no matches saved yet
- **Steps**:
  1. Navigate to AutoDrawScreen
  2. Tap "Boc tham tu dong" button
  3. Wait for loading indicator
- **Expected**: Loading spinner shown; after 600ms delay, preview matches appear in ListView; `_isManualDrawMode` is false; all teams revealed; "Luu & Bat dau giai" button enabled; round 1 matches displayed with team names; BYE matches shown with "DAC CACH VAO VONG TRONG" badge
- **Edge cases**: Number of teams is not a power of 2 (BYE slots generated); all teams generate BYE; `_generatePreview` throws exception (snackbar error shown)

---

### TC-FLUTTER-BRACKET-013: AutoDrawScreen - Manual Draw Mode
- **Module**: bracket
- **Screen**: AutoDrawScreen
- **Preconditions**: Tournament exists; teams registered
- **Steps**:
  1. Navigate to AutoDrawScreen
  2. Tap "Boc tham tung doi" button
  3. Tap "Boc 1 doi" multiple times
  4. Tap "Hien tat ca"
- **Expected**: Preview matches shown with "???" for unrevealed teams; team count shown "Con N doi chua boc"; each tap reveals one team (removes last from shuffled list); "Hien tat ca" reveals all remaining teams; "Luu" button disabled while `_unrevealedTeamIds` is not empty; once all teams revealed, save button activates
- **Edge cases**: Only 1 team left unrevealed; manual draw with BYE teams; switching between auto and manual mid-flow; user navigates away mid-draw

---

### TC-FLUTTER-BRACKET-014: AutoDrawScreen - Save Draw
- **Module**: bracket
- **Screen**: AutoDrawScreen
- **Preconditions**: Preview matches generated; all teams revealed (manual) or auto mode
- **Steps**:
  1. Tap "Luu & Bat dau giai" button
  2. Wait for API response
- **Expected**: `publishTournamentDrawUseCase` called; `_hasSaved` becomes true; snackbar "Boc tham va luu thanh cong!" shown; screen pops; if API fails, snackbar error shown; save button disabled while `_isDrawing` or `_hasSaved` is true
- **Edge cases**: API returns error; user double-taps save; network disconnect during save

---

### TC-FLUTTER-BRACKET-015: AutoDrawScreen - Clear Draw (Lam lai so do)
- **Module**: bracket
- **Screen**: AutoDrawScreen
- **Preconditions**: Matches have been saved previously
- **Steps**:
  1. Navigate to AutoDrawScreen
  2. Observe "Lam lai so do" button (red, with delete icon)
  3. Tap the button
- **Expected**: `resetTournamentDrawUseCase` called; preview cleared; state reset; snackbar "Lam lai so do thanh cong!" shown; if tournament has started matches (`hasStartedMatches`), show warning and disable the clear button
- **Edge cases**: Tournament already in progress (matches with scores >0) show locked warning text; API error during reset

---

### TC-FLUTTER-BRACKET-016: BracketGraphService - Single Elimination Graph Building
- **Module**: bracket
- **Screen**: BracketGraphService
- **Preconditions**: List of MatchModel objects with `nextMatchId` links
- **Steps**:
  1. Call `BracketGraphService.buildSingleEliminationGraph(matches)`
- **Expected**: Graph nodes created for valid matches (not BYE-vs-BYE, not cancelled); edges connect parent->child (nextMatch -> current); if multiple roots exist (single elimination poorly formed), a dummy root node (id: DUMMY_ROOT) is added to prevent BuchheimWalker crash
- **Edge cases**: Matches list is empty (empty graph); all matches are BYE-vs-BYE; matches have circular nextMatchId references; no nextMatchId exists (single root)

---

### TC-FLUTTER-BRACKET-017: BracketGraphService - Double Elimination Graph Building
- **Module**: bracket
- **Screen**: BracketGraphService
- **Preconditions**: List of MatchModel objects with `bracketPosition.bracket` values
- **Steps**:
  1. Call `BracketGraphService.buildDoubleEliminationGraph(matches, bracketType: 'winners')`
- **Expected**: Only matches with matching bracketType and not cancelled are included; BYE-vs-BYE matches filtered out; edges created via nextMatchId; `_ensureSingleRoot` called for multiple roots
- **Edge cases**: `bracketType: 'losers'` — only losers bracket matches; mixed brackets in same list; no valid matches after filtering

---

### TC-FLUTTER-BRACKET-018: SingleEliminationGenerator - Brackets with Power-of-2 Teams
- **Module**: bracket
- **Screen**: BracketGenerator (SingleEliminationGenerator)
- **Preconditions**: List of 8 teams; tournamentId provided
- **Steps**:
  1. Instantiate SingleEliminationGenerator
  2. Call `generate(tournamentId, teams)`
- **Expected**: Generates 7 matches (3 rounds); round 1 has 4 matches with real teams; subsequent rounds have TBD teams; `nextMatchId` links properly; positions follow `matchNumber` increment; winnerId empty for non-walkover; BYE handling if team count < next power of 2
- **Edge cases**: Team count is already power of 2 (no BYE); 1 team only (returns empty list); team list has BYE team already; duplicate team names

---

### TC-FLUTTER-BRACKET-019: SingleEliminationGenerator - BYE Walkover Propagation
- **Module**: bracket
- **Screen**: BracketGenerator (SingleEliminationGenerator)
- **Preconditions**: 5 teams (needs 8 slots, so 3 BYEs)
- **Steps**:
  1. Generate with 5 teams
  2. Check walkover propagation
- **Expected**: Slots distributed team1 first then team2; walkover matches get status 'walkover' and winnerId set; walkover winners are propagated to next match's team slot via `copyWith`; next match team1Name/team1Id updated from walkover winner
- **Edge cases**: Multiple consecutive BYEs for one bracket position; all BYE matches in round 1

---

### TC-FLUTTER-BRACKET-020: DoubleEliminationGenerator - Full Bracket Generation
- **Module**: bracket
- **Screen**: BracketGenerator (DoubleEliminationGenerator)
- **Preconditions**: 8 teams; single-round count
- **Steps**:
  1. Instantiate DoubleEliminationGenerator
  2. Call `generate(tournamentId, teams)`
- **Expected**: Winners bracket (WB) rounds: `totalWBRounds = log2(8) = 3` rounds; Losers bracket (LB): `2 * (3-1) = 4` rounds; Grand Final match + Grand Final Reset match generated; matches have `loserNextMatchId` set; WB round 1 losers -> LB round 1; match IDs follow pattern W_r_p, L_j_p, GF_0, GF_1
- **Edge cases**: 2 teams (simplest double elim: 1 WB round, 0 LB rounds); odd number of teams (extends to power of 2); very large team count (32+)

---

### TC-FLUTTER-BRACKET-021: DoubleEliminationGenerator - Walkover Propagation (Both Brackets)
- **Module**: bracket
- **Screen**: BracketGenerator (DoubleEliminationGenerator)
- **Preconditions**: Teams include BYEs
- **Steps**:
  1. Generate double elimination bracket with 6 teams (4 real + 2 BYE)
  2. Observe the while-loop walkover propagation
- **Expected**: Matches with BYE get status 'walkover'; winners propagated forward via `nextMatchId`; losers propagated via `loserNextMatchId`; `loserNextMatchId` propagation handles team1/team2 assignment based on round/position; `changed` flag drives loop until stable
- **Edge cases**: Walkover in WB round 1 propagates loser BYE into LB; LB match receives BYE loser; grand final gets walkover input; `loserNextMatchId` from WB round > 1

---

### TC-FLUTTER-BRACKET-022: RoundRobinGenerator - Round Robin Generation
- **Module**: bracket
- **Screen**: BracketGenerator (RoundRobinGenerator)
- **Preconditions**: 6 teams; `roundCount` specified
- **Steps**:
  1. Instantiate RoundRobinGenerator
  2. Call `generate(tournamentId, teams, roundCount: 2)`
- **Expected**: If odd teams, a BYE team is added (`teamCount % 2 != 0`); each round uses circular rotation (`teams.insert(1, teams.removeLast())`); matchesPerRound = numTeams / 2; BYE-vs-BYE matches not generated; matchCounter increments globally across rounds
- **Edge cases**: 1 team (returns empty list); 2 teams (1 match per round); very high roundCount; roundCount=0

---

### TC-FLUTTER-BRACKET-023: BracketFactory - Generator Selection
- **Module**: bracket
- **Screen**: BracketFactory
- **Preconditions**: Various bracket type strings
- **Steps**:
  1. Call `BracketFactory.getGenerator('single_elimination')` -> SingleEliminationGenerator
  2. Call `BracketFactory.getGenerator('double_elimination')` -> DoubleEliminationGenerator
  3. Call `BracketFactory.getGenerator('round_robin')` -> RoundRobinGenerator
  4. Call `BracketFactory.getGenerator('unknown_type')`
- **Expected**: Correct generator type returned for each known type; unknown type defaults to SingleEliminationGenerator
- **Edge cases**: Null/empty bracketType string

---

### TC-FLUTTER-BRACKET-024: SeparatedBuchheimWalkerAlgorithm - Node Positioning
- **Module**: bracket
- **Screen**: SeparatedBuchheimWalkerAlgorithm
- **Preconditions**: Graph with winners, losers, final, grand_final nodes
- **Steps**:
  1. Instantiate SeparatedBuchheimWalkerAlgorithm with configuration
  2. Call `run(graph, shiftX, shiftY)`
- **Expected**: Losers bracket nodes shifted by `separation` (2200) in Y; Final/GrandFinal nodes shifted by `separation/2`; all nodes normalized so min X/Y becomes 0; size computed from max extents
- **Edge cases**: Empty graph; no matches with bracket labels; all same bracket type; graph has no nodes

---

## 2. MATCH / SCORE MODULE

---

### TC-FLUTTER-MATCH-001: LiveScoreScreen - Setup State (Scheduled Match)
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Match has `status = 'scheduled'`; user is admin or referee
- **Steps**:
  1. Navigate to LiveScoreScreen with scheduled match
  2. Observe setup state UI
- **Expected**: Configuration form displayed: max score text field, time limit text field, referee name text field, win-by-two switch; sport config chips shown (mon, format BO?, thang ? set, moc set, luat, tiebreak); default values seeded from sport rules or match settings; "BAT DAU VA MO BAN CHAM DIEM" button visible
- **Edge cases**: `sportRules` is null (uses match defaults); match has no `maxScore` set (uses config.pointsPerSet); sport is tennis (score label shows "Số game..."); scoring model is pickleball side-out

---

### TC-FLUTTER-MATCH-002: LiveScoreScreen - Start Match
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Setup form filled; user is admin/referee
- **Steps**:
  1. Fill in max score (e.g., 21), time limit (15), referee name ("Trong tai A")
  2. Toggle win-by-two if needed
  3. Tap "BAT DAU VA MO BAN CHAM DIEM"
- **Expected**: `updateConfig` called with values; `startMatch` called; official score modal opens automatically; match status transitions to 'live'; if not mounted after await, returns early
- **Edge cases**: Empty referee name (uses match.refereeName); empty time limit (null, no limit); maxScore is invalid (uses fallback: match.maxScore -> config.pointsPerSet)

---

### TC-FLUTTER-MATCH-003: LiveScoreScreen - Live State: Referee Score Controls
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Match is live; user is admin/referee
- **Steps**:
  1. Observe live state layout
  2. Tap team1 area (increment score by 1)
  3. Tap team1 decrement button (`remove_circle_outline`)
- **Expected**: Two team score panels side by side with gradient background; center VS label + LIVE badge; tapping team area calls `controller.addScore(isTeam1, 1)`; decrement button calls `addScore(isTeam1, -1)`; score animated with AnimatedSwitcher (ScaleTransition); score change triggers `_trackScoreChanges` and temporary animation flag
- **Edge cases**: Score goes below 0 (should prevent in notifier); rapid tapping causes double increment; very large scores

---

### TC-FLUTTER-MATCH-004: LiveScoreScreen - Win Condition Check
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Match is live; maxScore set to 21; winByTwo is true
- **Steps**:
  1. Increment score until team1 reaches 21 (or maxScore threshold)
  2. Observe win dialog
- **Expected**: `_checkWinner` called via `addPostFrameCallback`; if score1 >= maxScore, if `winByTwo` and abs(score1-score2) < 2, return (no dialog); else show winner dialog: "Doi X da gianh chien thang!" with score; two buttons: "Tiep tuc danh (Huy)" and "Xac nhan Ket thuc"; confirmation calls `endMatch(winnerId, loserId)` and pops screen
- **Edge cases**: Both scores exceed maxScore simultaneously; winByTwo is false (check passes at >= maxScore regardless of gap); score reaches threshold during decrement

---

### TC-FLUTTER-MATCH-005: LiveScoreScreen - Foul Sheet / Penalty
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Match is live; user is referee/admin
- **Steps**:
  1. Tap "THOI COI" button
  2. Select a team (team1 or team2)
  3. In PenaltyInputDialog, choose penalty option and reason
  4. Submit
- **Expected**: Foul selection dialog shows "Doi nao bi phat?" with both teams; selecting a team opens PenaltyInputDialog (with sport-specific options); onSubmit calls `addPenalty(isTeam1, sport, optionId, optionName, reason)`; snackbar "Da ghi nhan [option]" shown
- **Edge cases**: sport is null (falls back to tournament sport or 'other'); option list is empty; penalty service throws exception

---

### TC-FLUTTER-MATCH-006: LiveScoreScreen - Force Win (Xu thang)
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Match is live; user is referee/admin
- **Steps**:
  1. Tap "XU THANG" button
  2. In dialog, tap team1 or team2 as winner
- **Expected**: Force win dialog shows "Xac nhan xu thang cho mot doi (doi thu bo cuoc hoac pham quy)?"; tapping a team calls `_forceWinMatch(winnerId, loserId)`; if match exists from provider, calculates newScore: uses maxScore if set, else opponentScore+1; calls `updateMatchResultByAdmin`; if match null, calls `endMatch`; screen pops
- **Edge cases**: match is null from provider (falls to else); both scores high and no maxScore set

---

### TC-FLUTTER-MATCH-007: LiveScoreScreen - Viewer State (Match Live)
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: `isViewer` is true; match is live
- **Steps**:
  1. Open viewer mode for a live match
  2. Observe video player mockup
  3. Observe scoreboard overlay
  4. Switch between "Ti so & Dien bien" and "Phong thao luan" tabs
- **Expected**: Video player mockup with 16:9 aspect ratio, gradient background, play button, "CAM 1" label; TV-style scoreboard overlay top-left with team names, scores, LIVE indicator; bottom video controls bar; heart button (tapping it spawns heart animation); premium viewer scoreboard with team avatars, ELO display, set wins, set history boxes; info expansion tile; chat tab for comments
- **Edge cases**: match is completed in viewer mode (shows "KET THUC"); match is scheduled (shows "SAP DAU"); team name is very long (compacted with substring)

---

### TC-FLUTTER-MATCH-008: LiveScoreScreen - Comments (Chat)
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: `isViewer` is true
- **Steps**:
  1. Switch to "Phong thao luan" tab
  2. View comments loaded from API
  3. Post a new comment
  4. Observe match events mixed in feed
- **Expected**: Comments fetched from `/matches/{id}/comments` on init; socket subscription (`socket.onCommentNew`) adds real-time comments; comments merged with match events sorted by createdAt descending; text field with auth guard (only authenticated users can type); send button or submit via keyboard; "Dang nhap de binh luan" hint for unauthenticated; empty state "Chua co thao luan"; system events (score, foul, yellow/red card) show with icons and colors
- **Edge cases**: API fetch fails silently; comment submission fails (shows snackbar); event type is unknown (defaults to notifications icon)

---

### TC-FLUTTER-MATCH-009: LiveScoreScreen - Completed State
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Match status is 'completed'
- **Steps**:
  1. Navigate to completed match
  2. Observe the completed state layout
- **Expected**: Trophy icon with shimmer/scale animation; "TRAN DAU DA KET THUC" header; score display with winner highlighted in green; winner badge "Thang: [TeamName]"; for admin role: "SUA KET QUA (ADMIN)" button; "Quay lai" and "Ve trang chu" buttons
- **Edge cases**: match has no winnerId (draw); admin edits score (opens inline admin dialog); role is not admin (edit button hidden)

---

### TC-FLUTTER-MATCH-010: LiveScoreScreen - Admin Edit Inline Dialog
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Match is completed; role is admin
- **Steps**:
  1. Tap "SUA KET QUA (ADMIN)"
  2. Change score1 and score2 values
  3. Select winner from dropdown
  4. Tap "Luu Thay Doi"
- **Expected**: AlertDialog with warning "Thay doi ket qua se ghi de du lieu va tu dong cap nhat nhanh dau tiep theo"; two text fields for scores; dropdown for winner; saving calls `updateMatchResultByAdmin(score1, score2, winnerId, loserId)`; snackbar "Da cap nhat ket qua tran dau!"
- **Edge cases**: Empty/invalid score input (defaults to 0); winner not changed; admin edits completed match multiple times

---

### TC-FLUTTER-MATCH-011: LiveScoreScreen - Error / Null Match States
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Match ID is invalid or null data from provider
- **Steps**:
  1. Navigate with invalid match ID
- **Expected**: "Khong tim thay tran dau" state with search_off icon and text; or error state with error message, retry button, and back button
- **Edge cases**: Provider loading state shows CircularProgressIndicator; error with long message string

---

### TC-FLUTTER-MATCH-012: LiveScoreScreen - Official Score Modal Button
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Match is live; user is admin/referee
- **Steps**:
  1. Look for "Tinh diem" button in app bar actions
- **Expected**: FilledButton.tonalIcon with scoreboard icon appears only when match is live (not completed/scheduled); on press opens `showOfficialScoreModal`; when match data is null/loading/error, button hidden (SizedBox.shrink)
- **Edge cases**: canOpenScoring is false (viewer role); match status changes while modal is open

---

### TC-FLUTTER-MATCH-013: TennisScorePanel - Normal Point Progression
- **Module**: match
- **Screen**: TennisScorePanel
- **Preconditions**: Tennis match is live; not tiebreak; not deuce
- **Steps**:
  1. Observe TennisScorePanel in the score modal
  2. Award point to team1 via add button
- **Expected**: Points display shows tennis format (0, 15, 30, 40); info pills show "Diem game: 15 . 30 . 40"; adding points progresses through sequence; center state label shows "GAME"
- **Edge cases**: Score goes from 0 -> 15 -> 30 -> 40 -> win game; team1 and team2 both at 40 (enters Deuce)

---

### TC-FLUTTER-MATCH-014: TennisScorePanel - Deuce State
- **Module**: match
- **Screen**: TennisScorePanel
- **Preconditions**: Both teams at game points >= 3 and equal
- **Steps**:
  1. Award points until both reach 40 (3-3)
- **Expected**: Center state shows "DEUCE" label with amber styling; info pill adds "Trang thai: Deuce"; removing a point from one side exits deuce if scores diverge; points display still shows "40"
- **Edge cases**: Both teams at 40-40, then one gets advantage; advantage lost back to deuce

---

### TC-FLUTTER-MATCH-015: TennisScorePanel - Tiebreak State
- **Module**: match
- **Screen**: TennisScorePanel
- **Preconditions**: Game points reach tiebreak threshold (e.g., 6-6 in games)
- **Steps**:
  1. Observe tiebreak mode
- **Expected**: Orange banner at top: "TIEBREAK . Moi pha bong duoc 1 diem, cham ? va cach 2 de thang set"; points display shows real integer numbers (not 15-30-40); center state shows "TIEBREAK" label; info pill shows "Diem game: Tiebreak"
- **Edge cases**: Tiebreak finishes (one side reaches 7+ and leads by 2); tiebreak display switch back to normal after set win

---

### TC-FLUTTER-MATCH-016: TennisScorePanel - Responsive Layout
- **Module**: match
- **Screen**: TennisScorePanel
- **Preconditions**: Width < 620 (compact mode)
- **Steps**:
  1. Resize panel to narrow width
- **Expected**: Team controls stack vertically (Column) instead of horizontal (Row); VS label between them; text sizes adapt (compact: 54px, normal: 62px)
- **Edge cases**: Width exactly 620; extremely narrow (< 300px); rotation during scoring

---

### TC-FLUTTER-MATCH-017: TennisScorePanel - Read-Only Mode
- **Module**: match
- **Screen**: TennisScorePanel
- **Preconditions**: `isReadOnly` is true (e.g., match completed)
- **Steps**:
  1. Observe panel in read-only mode
- **Expected**: Add/Remove point buttons hidden; all other UI (points, info pills, set history) remains visible
- **Edge cases**: `isReadOnly` changing dynamically; read-only during live match for viewers

---

### TC-FLUTTER-MATCH-018: TeamScoreCard - Score Display
- **Module**: match
- **Screen**: TeamScoreCard
- **Preconditions**: Match data available; match is live or completed
- **Steps**:
  1. Render TeamScoreCard for team1
- **Expected**: Team name displayed; score shown in a large 100x100 container; if winner (completed), green border and accent color; if live, ScoreStepper shown with increment/decrement
- **Edge cases**: Team name very long (ellipsized); match is null (SizedBox.shrink); score is 0; match is completed and team is loser (no winner styling)

---

### TC-FLUTTER-MATCH-019: TeamScoreCard - Score Controls (Live)
- **Module**: match
- **Screen**: TeamScoreCard
- **Preconditions**: `isLive` is true
- **Steps**:
  1. Tap increment (+) button
  2. Tap decrement (-) button
- **Expected**: `controller.addScore(isTeam1, 1)` called on increment; `addScore(isTeam1, -1)` called on decrement; on error, snackbar "Loi: Ban khong co quyen sua diem." shown
- **Edge cases**: User lacks permission (notifier throws); rapid button presses

---

### TC-FLUTTER-MATCH-020: Official Score Modal - Display & Structure
- **Module**: match
- **Screen**: OfficialScoreModal
- **Preconditions**: Match data provided; context available
- **Steps**:
  1. Call `showOfficialScoreModal(context, tournamentId, matchId, match)`
- **Expected**: DraggableScrollableSheet with initial 0.88 height; handle bar at top; header with shield icon, "BANG TRONG TAI" label, match teams, sport badge (LIVE/CHO); sport label bar (tennis/pickleball/bong ban/cau long); match ops summary (_MatchOpsSummary); score panel (TennisScorePanel or PickleballPanel or RallyScorePanel); SetHistoryBar; MatchBottomBar
- **Edge cases**: match is null; kind is unknown (falls to rally); scoring model is pickleball side-out

---

### TC-FLUTTER-MATCH-021: Official Score Modal - _MatchOpsSummary
- **Module**: match
- **Screen**: OfficialScoreModal _(MatchOpsSummary)
- **Preconditions**: Match with various metadata
- **Steps**:
  1. Observe _MatchOpsSummary widget
- **Expected**: Meta pills for sport, status, court, time; "Luat ap dung" section with config chips (BO, thang set, diem/set, cach 2, scoring model, tiebreak, tran diem, gioi han); "Dieu chinh o cap tran" if match.maxScore != null or !winByTwo; "Hinh phat theo mon" section with penalty options (up to 4); "Ghi phat" and "Xu thang" buttons if callbacks provided
- **Edge cases**: match.scheduledTime is null (shows "Chua xep gio"); court is empty; no penalty options; both onRecordPenalty and onForceWin are null (buttons hidden)

---

### TC-FLUTTER-MATCH-022: LiveMatchScreen - Match Sections
- **Module**: match
- **Screen**: LiveMatchScreen
- **Preconditions**: Tournaments with all match statuses
- **Steps**:
  1. Navigate to LiveMatchScreen
  2. Observe sections
- **Expected**: Header banner with tournament name, total match count, live badge (if any); "Dang thi dau" section (live matches); "Sap dien ra" section (scheduled); "Da ket thuc" section (completed); animations on cards (slideX for live, fadeIn for others); pull-to-refresh reloads data
- **Edge cases**: No live matches (hide section); no matches at all (empty state); very large number of matches

---

### TC-FLUTTER-MATCH-023: LiveMatchScreen - Match Filtering
- **Module**: match
- **Screen**: LiveMatchScreen
- **Preconditions**: Matches have various statuses
- **Steps**:
  1. Observe `validMatches` logic
- **Expected**: Matches with status 'live' or 'completed' always shown; otherwise both team names must not be 'TBD'; matches categorized into live, completed, upcoming based on status; stats row shows counts
- **Edge cases**: Matches with TBD but are live (still shown); matches with empty team names; `AppConstants.matchLive` vs `match.isLive`

---

### TC-FLUTTER-MATCH-024: LiveMatchScreen - Empty State
- **Module**: match
- **Screen**: LiveMatchScreen
- **Preconditions**: No valid matches exist
- **Steps**:
  1. Navigate to LiveMatchScreen with no matches
- **Expected**: Header banner (without live badge); centered empty state: sports_score icon + "Chua co tran dau" + description + "Tai lai" button; pull-to-refresh available
- **Edge cases**: Tournament loading fails (error state with cloud_off icon + retry); shimmer loading during data fetch

---

### TC-FLUTTER-MATCH-025: AdminEditScoreDialog - Edit Score Form
- **Module**: match
- **Screen**: AdminEditScoreDialog
- **Preconditions**: Match exists; admin user
- **Steps**:
  1. Open AdminEditScoreDialog for a match
  2. Modify score1 and score2 text fields
  3. Select winner via radio buttons
  4. Tap "Luu ket qua"
- **Expected**: Dialog title "Admin: Sua ket qua"; two text fields prefilled with current scores; radio group for winner selection; save button disabled if no winner selected; on save, returns map {score1, score2, winnerId, loserId} via Navigator.pop
- **Edge cases**: No winner initially selected (match.winnerId is empty); score fields empty (defaults to match scores); loserId computed as the other team

---

### TC-FLUTTER-MATCH-026: LiveScoreScreen - Heart Animation
- **Module**: match
- **Screen**: LiveScoreScreen
- **Preconditions**: Match is live; viewer mode
- **Steps**:
  1. Tap the floating heart button (or heart icon in chat)
- **Expected**: 3 HeartModel instances created with random color, scale, position; hearts animate upward using Timer.periodic(30ms); hearts removed when yProgress >= 1.0; timer auto-cancels when no hearts remain
- **Edge cases**: Rapid heart spawns (multiple overlapping timers); 500+ hearts accumulated; dispose clears timer

---

## 3. RANKING MODULE

---

### TC-FLUTTER-RANKING-001: LeaderboardScreen - Category Selection
- **Module**: ranking
- **Screen**: LeaderboardScreen
- **Preconditions**: Multiple sport categories available from API
- **Steps**:
  1. Navigate to LeaderboardScreen
  2. Observe sport chips scrolling horizontally
  3. Tap a different sport chip
- **Expected**: Sport chips loaded from `categoriesProvider`; first category auto-selected as default if `_selectedCategory` is 'all' or invalid; tapping a chip updates `_selectedCategory`; rankings reload for that category; chips display sport icon + name; selected chip uses primary color, unselected uses bgCard
- **Edge cases**: Categories list is empty (empty state shown); single category; category list returns error; rapid switching between categories

---

### TC-FLUTTER-RANKING-002: LeaderboardScreen - Rankings List with Podium
- **Module**: ranking
- **Screen**: LeaderboardScreen
- **Preconditions**: Rankings have >= 3 players
- **Steps**:
  1. Select a sport category with rankings
  2. Observe the list
- **Expected**: PodiumView shown at top (top 3 players with special styling); positions 4+ listed as RankingRow items; each row shows rank, user avatar, name, ELO points, tier badge; "Ban" sticky card at bottom for current authenticated user; scroll-to-rank feature via `_scrollToRank` buttons (if any)
- **Edge cases**: Rankings have < 3 players (no podium, list only); rankings have exactly 3 players; 100+ players (scroll performance)

---

### TC-FLUTTER-RANKING-003: LeaderboardScreen - Search Functionality
- **Module**: ranking
- **Screen**: LeaderboardScreen
- **Preconditions**: Rankings data loaded
- **Steps**:
  1. Type a player name in search bar
  2. Observe filtered results
  3. Tap the X button in search bar
- **Expected**: As user types, `_query` updates, rankings filtered by `fullName.toLowerCase().contains(query)`; search results show filtered list with `highlight: true`; clear button appears; tapping X clears search and restores full podium+list view; "Khong tim thay" empty state text shown for no matches
- **Edge cases**: Search term matches partial names; diacritics/accents in names; searching while category changes; very long search term

---

### TC-FLUTTER-RANKING-004: LeaderboardScreen - User Stats Card (Sticky Me)
- **Module**: ranking
- **Screen**: LeaderboardScreen
- **Preconditions**: User is authenticated; user has a ranking or not
- **Steps**:
  1. Observe bottom of rankings list
- **Expected**: If user has a ranking in top 100, UserStatsCard shown as sticky bottom card; if user has no ranking, a card with message "Ban chua co hang trong Top 100. Tham gia giai dau de duoc xep hang!" is shown
- **Edge cases**: User is not authenticated (no card); user's rank changes while viewing; user scrolls past bottom

---

### TC-FLUTTER-RANKING-005: LeaderboardScreen - Tier Legend
- **Module**: ranking
- **Screen**: LeaderboardScreen
- **Preconditions**: ELO tiers loaded for selected category
- **Steps**:
  1. Observe TierLegendView widget
- **Expected**: Tier legend renders tiers from `eloTiersProvider`; highlightElo param highlights current user's tier; loading/error states handle height (52px placeholder)
- **Edge cases**: No tiers defined for category; tiers data error; user ELO is null

---

### TC-FLUTTER-RANKING-006: LeaderboardScreen - Empty / Error States
- **Module**: ranking
- **Screen**: LeaderboardScreen
- **Preconditions**: Categories or rankings fail to load
- **Steps**:
  1. Trigger categories error
  2. Trigger rankings error
- **Expected**: Categories error: empty state with "Loi tai danh sach mon the thao" + retry button; Rankings error: empty state with "Khong the tai bang xep hang" + retry button; Loading states: CircularProgressIndicator
- **Edge cases**: Partial error (categories loaded, rankings failed); retry triggers re-fetch

---

### TC-FLUTTER-RANKING-007: UserRankingDetailScreen - User Stats Display
- **Module**: ranking
- **Screen**: UserRankingDetailScreen
- **Preconditions**: User is authenticated; ranking data available
- **Steps**:
  1. Navigate to UserRankingDetailScreen
- **Expected**: Back button + title "Thong tin xep hang"; gradient card with avatar (initials), name, tier badge (with fire emoji), ELO rating (large text, 52px), "Tuan nay +34" badge; stats row: Tran, Thang, Thua, Win rate (with percentage); "Tran dau gan day" section with 3 mock matches (win/loss with scores)
- **Edge cases**: User has no ranking data (defaults to 0 ELO, rank 0); fullName is empty (shows "??"); winRate calculation edge cases (0 matches played); `matchesLost` is negative (hypothetical)

---

### TC-FLUTTER-RANKING-008: UserRankingDetailScreen - Error State
- **Module**: ranking
- **Screen**: UserRankingDetailScreen
- **Preconditions**: API fails to load ranking
- **Steps**:
  1. Observe error state
- **Expected**: cloud_off icon, "Khong the tai thong tin" text, error message displayed; loading state shows CircularProgressIndicator
- **Edge cases**: Network error vs application error; empty data from server

---

### TC-FLUTTER-RANKING-009: StandingsProvider - Basic Calculation
- **Module**: ranking
- **Screen**: StandingsProvider
- **Preconditions**: Teams and completed matches exist
- **Steps**:
  1. Watch `standingsProvider(tournamentId)`
- **Expected**: Provider computes standings from teams + completed matches; each team initialized with 0 stats; completed matches (via StatusHelper.isCompleted) update: played +1, won/lost/drawn based on winnerId, pointsFor/pointsAgainst based on score1/score2; draws identified by `score1 == score2 && winnerId.isEmpty`; totalPoints: win=3, draw=1, loss=0; sorted by totalPoints desc -> pointDifference desc -> pointsFor desc
- **Edge cases**: No teams (empty standings); no completed matches (all zeros); match with walkover status (counts as win for winner, loss for loser, no draw possible); BYE team excluded from standings; team appears as team1 and team2 in different matches

---

### TC-FLUTTER-RANKING-010: StandingsProvider - Walkover Handling
- **Module**: ranking
- **Screen**: StandingsProvider
- **Preconditions**: Match with status 'walkover'
- **Steps**:
  1. Provide walkover match data
  2. Observe standings output
- **Expected**: Winner gets played+1, won+1, totalPoints+3; loser (if not BYE) gets played+1, lost+1; if loser is BYE, excluded (BYE not in standingsMap)
- **Edge cases**: walkover with empty winnerId (no stat updates); walkover with empty loserId; walkover where loser is a real team

---

### TC-FLUTTER-RANKING-011: StandingsProvider - Loading / Error States
- **Module**: ranking
- **Screen**: StandingsProvider
- **Preconditions**: teamsProvider or matchesProvider in loading/error state
- **Steps**:
  1. Observe provider state when dependencies are loading
- **Expected**: If teamsAsync or matchesAsync is loading, provider returns AsyncValue.loading; if either has error, provider returns AsyncValue.error with the error/stacktrace; combined states handled correctly
- **Edge cases**: teamsAsync loading but matchesAsync has data (still loading); teamsAsync error but matchesAsync success (returns error)

---

### TC-FLUTTER-RANKING-012: LeaderboardView - Table Rendering
- **Module**: ranking
- **Screen**: LeaderboardView
- **Preconditions**: Standings list with multiple entries
- **Steps**:
  1. Render LeaderboardView with standings data
- **Expected**: Header row with columns: #, DOI, P, W, D, L, GD, PTS; data rows with rank number, team name, stats; top 3 have gold/silver/bronze colors with trophy icons; PTS column highlighted in blue; GD shows positive/negative sign
- **Edge cases**: Standings list is empty (empty state with emoji_events icon + "Chua co du lieu thi dau"); very long team name (ellipsized); all stats are zero; negative point difference

---

## 4. TOURNAMENT INTRO MODULE

---

### TC-FLUTTER-INTRO-001: TournamentIntroScreen - Tab Navigation
- **Module**: intro
- **Screen**: TournamentIntroScreen
- **Preconditions**: Tournament exists; user has role (or not)
- **Steps**:
  1. Navigate to TournamentIntroScreen
  2. Observe 4 tabs
  3. Tap each tab
- **Expected**: Tabs: "Gioi thieu", "Danh sach doi", "Bang thi dau", "Bang xep hang"; SliverAppBar with tournament name, back button, viewer count badge; NestedScrollView with sliver header + body; tab bar persists on scroll (SliverPersistentHeader)
- **Edge cases**: Tournament status is null; user role is null; tournament data is null (NotFoundView shown)

---

### TC-FLUTTER-INTRO-002: TournamentIntroScreen - About Tab
- **Module**: intro
- **Screen**: TournamentIntroScreen (About Tab)
- **Preconditions**: Tournament has description, prize info, contact info
- **Steps**:
  1. Go to "Gioi thieu" tab
  2. Scroll through content
- **Expected**: "BAN TO CHUC" section with creator avatar + name + status badge; "GIOI THIEU GIAI DAU" section with description (scrollable, maxHeight 200); "CO CAU GIAI THUONG" section with prize description (or "Dang cap nhat"); "THONG TIN LIEN HE" section with phone/email if available (or "Chua cap nhat"); CountdownTimer shown if tournament is upcoming and registrationStartDate exists
- **Edge cases**: description is empty (hidden); prizeDescription is null; contactInfo is null; creatorAvatarUrl is relative path (prepends base URL)

---

### TC-FLUTTER-INTRO-003: TournamentIntroScreen - Teams Tab with Divisions
- **Module**: intro
- **Screen**: TournamentIntroScreen (Teams Tab)
- **Preconditions**: Teams with various divisions/groups exist
- **Steps**:
  1. Go to "Danh sach doi" tab
  2. Use DivisionFilterSegment to filter
  3. Expand team cards
- **Expected**: DivisionFilterSegment shows "Tat ca" + unique divisions; teams grouped by division with colored headers (blue for Nam, pink for Nu); each team card shows name, division label, member count, approval status, seed (if >0); expansion tile reveals member list with captain badge; empty state "Khong co doi nao" when filtered to empty
- **Edge cases**: Team has no group (falls to "Khac"); team has empty members list; division contains both "Nam" and "Nu" keywords; team seed is 0 (hidden)

---

### TC-FLUTTER-INTRO-004: TournamentIntroScreen - Bottom Action Bar
- **Module**: intro
- **Screen**: TournamentIntroScreen (Bottom Bar)
- **Preconditions**: Various tournament statuses and user roles
- **Steps**:
  1. Observe floating bottom bar
- **Expected**: Follow/Unfollow button with bookmark icon; conditional buttons based on status+role: "Vao bang quan tri" (admin), "Xem so do thi dau" (regular user), "Xem truc tiep" (live matches), "Dang ky tham gia" (registration open), "Xem ket qua"/"Xem lich thi dau" (completed/other); buttons positioned at bottom-right with shadow
- **Edge cases**: Tournament is draft/upcoming/in_progress/completed; role is viewer/admin/null; follow API error (silent)

---

### TC-FLUTTER-INTRO-005: TournamentIntroScreen - Follow/Unfollow Tournament
- **Module**: intro
- **Screen**: TournamentIntroScreen
- **Preconditions**: User is authenticated
- **Steps**:
  1. Tap "Theo doi" button
  2. Tap "Dang theo doi" button
- **Expected**: Follow API called with `followTournament(id)`; button toggles to "Dang theo doi" (outlined style); unfollow calls `unfollowTournament(id)`; button toggles back; loading state shows CircularProgressIndicator; snackbar confirms action
- **Edge cases**: `_isFollowing` from API fails (silent catch); double-tap (loading guard); user not authenticated

---

### TC-FLUTTER-INTRO-006: TournamentIntroScreen - Registration Sheet
- **Module**: intro
- **Screen**: TournamentIntroScreen (Registration)
- **Preconditions**: Tournament status allows registration; user not hasRole
- **Steps**:
  1. Tap "Dang ky tham gia" button
- **Expected**: `showModalBottomSheet` opens TournamentRegistrationSheet (isScrollControlled); sheet allows filling registration form
- **Edge cases**: Registration API error; user already registered; tournament capacity full

---

### TC-FLUTTER-INTRO-007: TournamentIntroScreen - Viewer Count Badge
- **Module**: intro
- **Screen**: TournamentIntroScreen
- **Preconditions**: `presenceCountProvider` has data > 0
- **Steps**:
  1. Observe app bar actions
- **Expected**: Red badge with count number + red dot shown; if count is 0 or null, badge hidden
- **Edge cases**: Presence count changes in real-time; very high viewer count

---

### TC-FLUTTER-INTRO-008: TournamentIntroScreen - Loading/Error/Null States
- **Module**: intro
- **Screen**: TournamentIntroScreen
- **Preconditions**: Tournament provider varies
- **Steps**:
  1. Observe on null tournament
  2. Observe on loading
  3. Observe on error
- **Expected**: Null tournament: NotFoundView with "Ve trang chu" button; Loading: CircularProgressIndicator; Error: error message + "Thu lai" button (invalidates provider); teams data error still shows tab content with empty team list
- **Edge cases**: Back navigation when context.canPop() is false (goes to /home); auth token is SESSION (no signOut on back)

---

### TC-FLUTTER-DETAIL-001: TournamentDetailScreen - Tournament Info Card
- **Module**: intro
- **Screen**: TournamentDetailScreen
- **Preconditions**: Tournament exists; admin role
- **Steps**:
  1. Navigate to TournamentDetailScreen
- **Expected**: Info card with sport icon, tournament name, chips (sport name, format, category, bracket type, status, max teams, players/team); status and metadata from AppConstants mappings
- **Edge cases**: Tournament name is empty (shows "(Chua co ten)"); sport is unknown (falls to trophy emoji); format/category mappings missing (empty string)

---

### TC-FLUTTER-DETAIL-002: TournamentDetailScreen - Quick Actions
- **Module**: intro
- **Screen**: TournamentDetailScreen
- **Preconditions**: Admin role; tournament status "in_progress"
- **Steps**:
  1. Observe action buttons
- **Expected**: "QUAN LY" section with buttons: Quan ly Ma truy cap (Token), Quan ly doi/VDV, Boc tham & Phan bang, Xem Bracket; additional "Ket thuc giai dau" (only if status in_progress) with confirm dialog; "Xuat du lieu giai dau" (Excel export)
- **Edge cases**: Tournament is completed (no "Ket thuc" button); tablet vs mobile (embedded views vs navigation); action fails (snackbar error)

---

### TC-FLUTTER-DETAIL-003: TournamentDetailScreen - Finalize Tournament
- **Module**: intro
- **Screen**: TournamentDetailScreen
- **Preconditions**: Tournament status = 'in_progress'
- **Steps**:
  1. Tap "Ket thuc giai dau"
  2. Confirm in dialog
- **Expected**: showConfirmDialog with warning; on confirm, `finalizeTournament(id)` called; success snackbar "Giai dau da ket thuc thanh cong!"; error snackbar otherwise
- **Edge cases**: User cancels dialog; API fails; matches still in progress

---

### TC-FLUTTER-DETAIL-004: TournamentDetailScreen - Delete Tournament
- **Module**: intro
- **Screen**: TournamentDetailScreen
- **Preconditions**: Admin role
- **Steps**:
  1. Tap more_vert menu in app bar
  2. Select "Xoa giai dau"
  3. Confirm deletion
- **Expected**: PopupMenuButton with delete option; confirm dialog "Thao tac nay khong the hoan tac."; on confirm, `deleteTournament(id)` called; success navigates to /admin; error snackbar "Loi khi xoa: $error"
- **Edge cases**: User cancels deletion; tournament has matches and teams (cascade delete); network error during deletion

---

### TC-FLUTTER-DETAIL-005: TournamentDetailScreen - Excel Export
- **Module**: intro
- **Screen**: TournamentDetailScreen
- **Preconditions**: Tournament has matches
- **Steps**:
  1. Tap "Xuat du lieu giai dau"
- **Expected**: Snackbar "Dang tao file Excel..."; `matchesProvider` fetched; `ExcelExportService.exportTournamentData` called; success snackbar "Xuat du lieu thanh cong!"; error snackbar with error message
- **Edge cases**: No matches yet (empty export); file creation permission denied; very large dataset

---

### TC-FLUTTER-DETAIL-006: TournamentDetailScreen - Responsive Layout (Tablet)
- **Module**: intro
- **Screen**: TournamentDetailScreen
- **Preconditions**: Tablet form factor
- **Steps**:
  1. Open TournamentDetailScreen on tablet
- **Expected**: Master-detail layout: left panel (320px) with management buttons, right panel with embedded screen; selecting an action updates the detail view inline via `_selectedFeature` state; "Chon mot chuc nang ben trai" placeholder initially
- **Edge cases**: Switching between features rapidly; feature state persists when rotating

---

### TC-FLUTTER-DETAIL-007: TournamentDetailScreen - Embedded Screens
- **Module**: intro
- **Screen**: TournamentDetailScreen (features)
- **Preconditions**: Admin role
- **Steps**:
  1. Select each feature via buttons
- **Expected**: TokenManagementScreen embedded (isEmbedded: true); TeamListScreen embedded; AutoDrawScreen embedded; BracketViewScreen embedded; each embedded screen hides its own back button
- **Edge cases**: Embedded screen's internal navigation (should not break); token management screen loaded with valid tournament ID

---

## 5. CROSS-MODULE / INTEGRATION

---

### TC-FLUTTER-CROSS-001: Bracket -> Match Flow (Tap Match -> LiveScore)
- **Module**: cross
- **Screen**: BracketViewScreen -> LiveScoreScreen
- **Preconditions**: Match exists in bracket list; user has any role
- **Steps**:
  1. Tap any match row in BracketViewScreen
- **Expected**: Navigation to `/live/{match.id}` via GoRouter push; LiveScoreScreen opens with tournamentId and matchId; correct view mode based on auth role (referee/admin controls, viewer limits)
- **Edge cases**: Match ID is invalid; user navigates back from LiveScreen to Bracket

---

### TC-FLUTTER-CROSS-002: Draw -> Bracket Preview Flow
- **Module**: cross
- **Screen**: AutoDrawScreen -> BracketViewScreen
- **Preconditions**: Draw saved successfully
- **Steps**:
  1. Complete auto draw on AutoDrawScreen
  2. Navigate to BracketViewScreen for same tournament
- **Expected**: Previously empty bracket now shows generated matches with round structure; round names are properly labeled; bracket tree renders correctly; standings data shows teams with 0 matches played (before any matches are played)
- **Edge cases**: Draw is not yet published (empty bracket still); draw uses manual mode vs auto mode

---

### TC-FLUTTER-CROSS-003: Score Update -> Standings Recalculation
- **Module**: cross
- **Screen**: LiveScoreScreen -> StandingsProvider
- **Preconditions**: Match completed; standings provider watching same tournament
- **Steps**:
  1. Complete a match via LiveScoreScreen (endMatch)
  2. Return to bracket view -> standings tab
  3. Refresh
- **Expected**: Standings provider recalculates with completed match; winning team gets +3 points, +1 played, +1 won; losing team gets +0 points, +1 played, +1 lost; sort order updated
- **Edge cases**: Match is draw (score1 == score2, no winnerId); match is walkover; bracket type is round robin vs knockout (standings visible in both)

---

### TC-FLUTTER-CROSS-004: Tournament Intro -> Bracket/Live/Registration Navigation
- **Module**: cross
- **Screen**: TournamentIntroScreen -> Bracket/Live/Registration
- **Preconditions**: Various tournament statuses
- **Steps**:
  1. Tap bottom bar action based on tournament state
- **Expected**: If tournament is live: navigates to `/live-matches/{tournamentId}`; if admin: navigates to `/admin/tournament/{id}`; if registration open: opens TournamentRegistrationSheet; if completed: switches to bracket tab; navigation works correctly context.go and context.push
- **Edge cases**: Nested navigation with embedded screens; user role changes during session; tournament status changes between viewings

---

### TC-FLUTTER-CROSS-005: Admin Edit Score -> Bracket Advancement
- **Module**: cross
- **Screen**: LiveScoreScreen (Admin Edit) -> BracketGraphService
- **Preconditions**: Admin edits a match result in a bracket
- **Steps**:
  1. Edit completed match score via admin edit dialog
  2. Navigate to bracket view
- **Expected**: `updateMatchResultByAdmin` triggers bracket advancement updates; next round matches reflect updated winner; Standings recalculated with new scores
- **Edge cases**: Editing a match that already advanced a winner to next round; editing a match in double elimination (affects both winners and losers brackets)
