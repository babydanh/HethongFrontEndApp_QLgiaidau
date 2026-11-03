## ADDED Requirements

### Requirement: Rounds are grouped by bracket branch
The results board SHALL assign each round to a branch (main, winners, losers, grand final), order rounds by branch then round number, and give each losers-bracket round its own box even when two rounds share a label.

#### Scenario: Double elimination order
- **WHEN** a double-elimination division has winners round 1, losers round 1 and the grand final
- **THEN** the boxes appear as winners, losers, grand final
- **AND** each box head shows the colour and icon of its branch

#### Scenario: Single elimination
- **WHEN** the division is single elimination
- **THEN** every round uses the main (neutral) tone and shows no winners or losers icon

### Requirement: Round boxes collapse and expand
Each round box SHALL toggle open or folded when its head is tapped, and the head SHALL expose its expanded state to accessibility.

#### Scenario: Default state
- **WHEN** the board first shows rounds and no search text is typed
- **THEN** only the first round that still waits for a score is open, or the last round when none waits

#### Scenario: Search opens matching boxes
- **WHEN** the viewer types a player name that matches matches in several rounds
- **THEN** every box with a match is open, except a box the viewer folded by hand

### Requirement: "Tới vòng" opens only the chosen round
The round picker SHALL open the chosen round, fold every other round, and scroll the chosen box into view.

#### Scenario: Pick a losers round
- **WHEN** the viewer picks "Nhánh thua • Tứ kết" from the picker
- **THEN** that box is open and all other boxes are folded
- **AND** the board scrolls so the box head is visible

### Requirement: Match rows show status, columns and schedule
Each match row SHALL show a left border coloured by its status, SHALL sit under a column header `# · Cặp đấu · Kết quả`, and SHALL show time, court and referee when they exist.

#### Scenario: Doubles match
- **WHEN** a doubles match has two players per side
- **THEN** each side shows both players, one line each, with their avatars

#### Scenario: Singles and club teams
- **WHEN** a side is a single player or a named team with a logo
- **THEN** a single player shows one name, and a team shows its name with its logo

### Requirement: Filter bar has no late or disputed chip
The board filter bar SHALL NOT offer "Trễ giờ" or "Tranh chấp" chips. A filter of that kind that arrives from the progress popup SHALL still apply and its chip SHALL appear selected.

#### Scenario: Normal open
- **WHEN** an organiser opens the board without a preset filter
- **THEN** the chips are Tất cả, Đang đấu, Sắp tới, Đã xong, Chưa xong

#### Scenario: Deep link from the progress popup
- **WHEN** the board opens with the disputed filter preset
- **THEN** only disputed matches show and a selected "Tranh chấp" chip is visible so the filter can be changed

### Requirement: Clear score button between the two sides
A match that takes a score and has none yet SHALL show a large round "+" button in the Kết quả column, vertically centred between the two sides, with a touch target of at least 44 dp.

#### Scenario: Tap the plus
- **WHEN** an organiser taps the "+" of a ready match
- **THEN** the score popup opens

### Requirement: Score entry popup
Tapping a match that accepts a score SHALL, for organisers and referees, open a popup with both sides, the match time and court, one score input per set, a Save button and a "Vào trang Live" button.

#### Scenario: Save a finished match
- **WHEN** an organiser enters set scores that give one side more sets and taps Save
- **THEN** the popup sends the sets and the winner through the existing score API and closes
- **AND** the board refreshes the match

#### Scenario: Tied sets
- **WHEN** both sides have the same number of sets won
- **THEN** the Save button stays disabled

#### Scenario: Network failure
- **WHEN** the save request fails
- **THEN** the popup stays open, shows the error, and the Save button works again

### Requirement: Match date and time in the score popup
The score popup SHALL show a "Ngày giờ thi đấu" field in the form dd/mm/yyyy HH:mm with a calendar button, and SHALL send the typed date and time with the score. The time part is optional. The time the organiser saved SHALL replace the schedule time on the match row and in the popup header.

#### Scenario: Seed
- **WHEN** the popup opens for a match that stores a played date and time
- **THEN** the field shows them
- **AND** a match without a stored date starts at today with no time

#### Scenario: Save with date and time
- **WHEN** an organiser types 04/11/2026 09:15 and saves a finished match
- **THEN** the request carries playedDate 2026-11-04 and playedTime 09:15

#### Scenario: Date without time
- **WHEN** the organiser types only a date
- **THEN** the request carries that date and a null time

#### Scenario: Unreadable value
- **WHEN** the field holds text that is not a real date and time
- **THEN** the popup says so and the Save button stays disabled
