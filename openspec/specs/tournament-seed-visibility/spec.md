# tournament-seed-visibility Specification

## Purpose
App chỉ hiện và cho quản lý hạt giống ở nội dung vòng bảng + loại trực tiếp; các thể thức khác không hiện số hạt giống, không có nút xếp hạt giống và lời mô tả không hứa xếp hạt giống.

## Requirements

### Requirement: Seed chỉ hiện ở vòng bảng + loại trực tiếp

The App MUST show a team's seed only when its division bracketType is `group_stage_knockout`. The comparison MUST ignore letter case and surrounding spaces.

#### Scenario: Vòng bảng + loại trực tiếp hiện seed

- **WHEN** a team belongs to a division with bracketType `GROUP_STAGE_KNOCKOUT`
- **THEN** the team card MUST show the label "Hạt giống #N"

#### Scenario: Thể thức khác ẩn seed

- **WHEN** a team belongs to a `SINGLE_ELIMINATION` division, or its divisionId is missing from the loaded divisions
- **THEN** the team card MUST NOT show any seed label

### Requirement: Quản lý seed chỉ liệt kê vòng bảng + loại trực tiếp

The division management section MUST list only divisions whose bracketType is `group_stage_knockout` in the seed editor. The auto-seed action, seed inputs and save action MUST NOT appear for other formats.

#### Scenario: Có nội dung vòng bảng

- **WHEN** the tournament has a `GROUP_STAGE_KNOCKOUT` division and a `SINGLE_ELIMINATION` division
- **THEN** the seed editor MUST list only the `GROUP_STAGE_KNOCKOUT` division

#### Scenario: Không có nội dung vòng bảng

- **WHEN** the tournament has no `GROUP_STAGE_KNOCKOUT` division
- **THEN** the seed section MUST be hidden entirely

### Requirement: Chip seed Ops chỉ cho vòng bảng + loại trực tiếp

The organizer ops roster MUST show a participant's seed chip only when the selected division bracketType is `group_stage_knockout`.

#### Scenario: Nội dung vòng bảng hiện chip

- **WHEN** the selected division bracketType is `GROUP_STAGE_KNOCKOUT` and the participant has a seed
- **THEN** the participant card MUST show the seed chip

#### Scenario: Thiếu thể thức ẩn chip

- **WHEN** the division payload has no bracketType
- **THEN** the participant card MUST NOT show the seed chip

### Requirement: Copy không hứa xếp hạt giống cho mọi thể thức

The division description, the English draw title and the English recreate-bracket notice MUST NOT promise seeding. Each changed string MUST keep its key in both `app_vi.arb` and `app_en.arb`.

#### Scenario: Mô tả nội dung tiếng Việt

- **WHEN** the user opens the division management section in Vietnamese
- **THEN** the description MUST read "Tạo và cấu hình nội dung thi đấu."

#### Scenario: Thiếu key ở một file ARB

- **WHEN** a changed key is missing from either ARB file
- **THEN** `flutter gen-l10n` MUST fail and the change MUST NOT be archived
