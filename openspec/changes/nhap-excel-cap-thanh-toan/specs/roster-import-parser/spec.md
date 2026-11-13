# roster-import-parser Specification

## Purpose
Parser Excel của App ghép cặp, đọc thanh toán và hỏi AI layout như Web.

## ADDED Requirements

### Requirement: App pairs rows by merged or repeated STT

The app parser SHALL read vertical merged regions from the workbook and fill them down, SHALL pair two consecutive named rows with the same STT (merged, written twice, or upper row only) when at least 80% of the named rows are in such groups, SHALL read a pair-code column with an empty code inheriting the code above, and SHALL treat a section title row such as `DANH SÁCH VĐV CHƯA CÓ CẶP` as the start of single athletes that are never paired by STT or position.

#### Scenario: Sample file

- **WHEN** the sample workbook (11 pairs, a section title, 7 singles, 44 STT-only rows) is parsed for a doubles division
- **THEN** the result has 11 pairs and 7 single athletes and no row for the section title or the STT-only rows

#### Scenario: Numbered list

- **WHEN** the STT column reads `1, 2, 3, 4` with one name per row
- **THEN** no rows are paired

#### Scenario: Pair-code column with an empty code

- **WHEN** the pair-code column reads `1`, empty, `Cặp 2`, empty
- **THEN** rows 1 and 2 form one pair and rows 3 and 4 form another

### Requirement: Partner column is only a hint

A partner column (`VĐV đăng ký đứng chung`, `đứng chung`, `đồng đội`, `partner`) SHALL NOT become a player. A hint SHALL pair two rows only when it fuzzy-matches exactly one other row that has no pair from STT or code and is not in a singles section; it SHALL NOT override those pairs, and `chưa`, `chưa có`, `2 người` or empty SHALL be no hint.

#### Scenario: Nickname hint

- **WHEN** two rows have no STT pair and the hint of one holds a nickname containing the given name of the other
- **THEN** the two rows form one pair

#### Scenario: Hint names nobody

- **WHEN** the hint is `Chưa có`
- **THEN** the row stays single and no athlete is created from the cell

### Requirement: App imports unpaid by default

The app parser SHALL set `isPaid` true only for a paid value in a payment column (`x`, `✓`, `đã ck`, a money amount above zero, ...) and SHALL send `isPaid` to the import API; a file without payment data SHALL import unpaid, and a payment cell merged over a pair SHALL apply to both athletes.

#### Scenario: No payment column

- **WHEN** the file has no payment column
- **THEN** every parsed row has `isPaid = false`

#### Scenario: Merged payment cell

- **WHEN** the payment cell is merged over two rows and reads `x`
- **THEN** both athletes are paid

### Requirement: App asks the AI layout only when the rules are not confident

The import sheet SHALL ask `POST /ai/tournaments/:id/roster-layout` with a masked digest when the rule-based reading is not confident: a table read by no block, an e-mail outside the mapped columns, too many nameless rows, or a doubles division with pair signs but no pair found. A confident reading SHALL NOT call the AI.

#### Scenario: Confident rules

- **WHEN** the sample file is read
- **THEN** the AI is not called

#### Scenario: Pair signs but no pair found

- **WHEN** a doubles division has merged STT regions but too few pair rows for the rules
- **THEN** the AI is asked once and the digest carries the merged regions as addresses only

### Requirement: App keeps the rule-based rows when the AI cannot answer

When the answer is `aiAvailable: false`, the call fails with 429 or 503, or the answer holds no block, the sheet SHALL keep the rule-based rows, run the preview check on them and show the status.

#### Scenario: AI unavailable

- **WHEN** the answer is `aiAvailable: false`
- **THEN** the rule-based rows stay, the preview check runs on them and the sheet shows that the AI is not available

#### Scenario: AI rate limit

- **WHEN** the call fails with HTTP 429
- **THEN** the rule-based rows stay and the sheet shows the error status

#### Scenario: AI layout with singles

- **WHEN** the AI answers `CONSECUTIVE_ROWS` with `singlesFromRow`, and the file has a merged STT region
- **THEN** the rows before `singlesFromRow` pair by position and the rows from it stay single
