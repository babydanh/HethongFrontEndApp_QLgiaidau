# Double Elimination Bracket Branch Bug Analysis

## Root Cause: Case Mismatch in `bracketType` Constants

### The Bug
`AppConstants.bracketDoubleElimination` is `'double_elimination'` (lowercase), but the API returns `'DOUBLE_ELIMINATION'` (uppercase). This means the Flutter app **never identifies** tournaments as double elimination, and therefore always renders the **Single Elimination diagram** instead of the Double Elimination diagram.

### Execution Trace

1. **`BracketViewScreen` (line 68, 150-152)** fetches the tournament and checks bracket type:
```dart
final bracketType = tournamentAsync.value?.bracketType ?? AppConstants.bracketSingleElimination;
// bracketType from API = 'DOUBLE_ELIMINATION' (uppercase)
// AppConstants.bracketSingleElimination = 'single_elimination' (lowercase)

final isDoubleElimination = bracketType == AppConstants.bracketDoubleElimination;
// => 'DOUBLE_ELIMINATION' == 'double_elimination'
// => false   <-- ALWAYS FALSE!
```

2. **`BracketDiagramScreen` (line 56)** also checks:
```dart
final isDouble = widget.bracketType == AppConstants.bracketDoubleElimination;
// => false   <-- ALWAYS FALSE!
```

3. Since `isDouble` is false, the code falls through to line 139:
```dart
return SingleElimDiagram(matches: widget.matches, ...);
```

This renders ALL matches (winners + losers + grand finals) in a single elimination layout. The matches appear jumbled together with no winners/losers separation.

### Where the Values Come From

**Backend** (`tournament-config.interface.ts`, line 15):
```typescript
bracketType: 'SINGLE_ELIMINATION' | 'DOUBLE_ELIMINATION' | 'ROUND_ROBIN' | 'GROUP_STAGE_THEN_KNOCKOUT';
```
All values are **UPPERCASE**.

**Backend** (`tournaments.service.ts`, line 747-749) — the bracket generator reads it and compares:
```typescript
const bracketType = config.bracketType as string || 'SINGLE_ELIMINATION';
if (bracketType === 'DOUBLE_ELIMINATION') {  // uppercase comparison
```

**Flutter** `Tournament.fromJson` (`tournament.dart`, line 120) reads the raw value:
```dart
String bracketTypeVal = config['bracketType']?.toString() ?? '';
// Gets 'DOUBLE_ELIMINATION' (uppercase) from API
```

**Flutter** `AppConstants` (`app_constants.dart`, lines 51-53):
```dart
static const String bracketDoubleElimination = 'double_elimination';  // LOWERCASE!
static const String bracketSingleElimination = 'single_elimination';   // LOWERCASE!
static const String bracketRoundRobin = 'round_robin';                 // LOWERCASE!
```

### Why Web Works
The web uses hardcoded uppercase strings for comparison:
```typescript
if (stageType === 'DOUBLE_ELIMINATION') { ... }
// Direct comparison with uppercase
```

### Proof
If you add a debug print in `BracketViewScreen`:
```dart
debugPrint('DEBUG: bracketType="$bracketType" isDouble=$isDoubleElimination');
```
You would see:
```
DEBUG: bracketType="DOUBLE_ELIMINATION" isDouble=false
```

---

## Fix

### Option 1 (Recommended): Fix AppConstants values

In `app_quanly_giaidau\lib\core\config\app_constants.dart`, lines 51-53:

```dart
// CHANGE FROM (lowercase):
static const String bracketSingleElimination = 'single_elimination';
static const String bracketDoubleElimination = 'double_elimination';
static const String bracketRoundRobin = 'round_robin';

// TO (uppercase, matching API):
static const String bracketSingleElimination = 'SINGLE_ELIMINATION';
static const String bracketDoubleElimination = 'DOUBLE_ELIMINATION';
static const String bracketRoundRobin = 'ROUND_ROBIN';
```

**Risk**: If any tournaments were created by the Flutter app with lowercase `bracketType` in the JSONB, those would stop matching. However, since the web is the primary admin interface, most tournaments are created with uppercase values.

### Option 2 (Safer): Normalize in Tournament.fromJson

In `tournament.dart`, line 120:
```dart
// CHANGE FROM:
String bracketTypeVal = config['bracketType']?.toString() ?? json['bracketType']?.toString() ?? '';
// TO (normalize to uppercase):
String bracketTypeVal = (config['bracketType']?.toString() ?? json['bracketType']?.toString() ?? '').toUpperCase();
```

This normalizes any value (upper or lower case) from the API to uppercase, making the comparison consistent regardless of how the tournament was created.

### Option 3 (Case-insensitive comparisons): Change all comparisons
Replace all `== AppConstants.bracketXxx` checks with `.toUpperCase() == 'DOUBLE_ELIMINATION'` style comparisons. More work, more fragile.

---

## Secondary Issue: Missing `loserNextMatchId` in Bracket Parser

### Location
`api_tournament_repository.dart`, `_parseBracketMatch()` method (lines 339-381).

### Bug
`loserNextMatchId` is not parsed from the API response. It defaults to `''` (empty string) for all matches.

### Impact
In `_DoubleElimPainter` (`double_elim_diagram.dart`, lines 631-637):
```dart
if (match.loserNextMatchId.isNotEmpty) {  // ALWAYS false
    // Loser connector lines from winners to losers are NEVER drawn
}
```
The loser connector lines (showing how losing players from Winners branch feed into the Losers branch) are never rendered.

### Fix
Add `loserNextMatchId` to all three parsing methods in `api_tournament_repository.dart` and `api_match_repository.dart`:

In `_parseBracketMatch` (`api_tournament_repository.dart`), add after `nextMatchId`:
```dart
loserNextMatchId: json['loserNextMatchId']?.toString() ?? '',
```

Similarly in all three inline parsers in `api_match_repository.dart`.

---

## Tertiary Issues

### 1. `_buildBands` uses `m.bracketPosition.bracket` correctly
The branching logic in `_buildBands()` (`double_elim_diagram.dart`, lines 60-70) is correct:
- `'winners'` → winners map (from `_mapBracketBranch('MAIN')`)
- `'losers'` → losers map (from `_mapBracketBranch('LOSERS')`)
- everything else → finals list (including `'grand_final'` from `_mapBracketBranch('GRAND_FINALS')`)

### 2. `_mapBracketBranch` mapping is correct
Both `api_tournament_repository.dart` and `api_match_repository.dart` have identical `_mapBracketBranch`:
```
'MAIN' → 'winners'
'LOSERS' → 'losers'
'GRAND_FINALS' → 'grand_final'
default → 'winners'
```

### 3. Losers bracket starts at X=0 in both web and Flutter
Both implementations start the losers bracket from column X=0. This is by design — the two bands are vertically separated (by `_kBandGap = 80px`), not horizontally.

---

## File Paths Referenced

| File | Path |
|------|------|
| AppConstants | `app_quanly_giaidau\lib\core\config\app_constants.dart` (lines 51-53) |
| Tournament entity | `app_quanly_giaidau\lib\domain\entities\tournament.dart` (line 120) |
| BracketViewScreen | `app_quanly_giaidau\lib\features\bracket\screens\bracket_view_screen.dart` (lines 147-152) |
| BracketDiagramScreen | `app_quanly_giaidau\lib\features\bracket\screens\bracket_diagram_screen.dart` (lines 56, 129-136) |
| DoubleElimDiagram | `app_quanly_giaidau\lib\features\bracket\widgets\double_elim_diagram.dart` |
| ApiTournamentRepository | `app_quanly_giaidau\lib\data\repositories\api\api_tournament_repository.dart` (lines 326-381) |
| ApiMatchRepository | `app_quanly_giaidau\lib\data\repositories\api\api_match_repository.dart` (lines 75-86) |
| Match entity (BracketPosition) | `app_quanly_giaidau\lib\domain\entities\match.dart` (lines 23-49) |
| Backend tournament-config interface | `backend-api_qlgiaidau\src\modules\tournaments\interfaces\tournament-config.interface.ts` (line 15) |
| Backend tournaments service | `backend-api_qlgiaidau\src\modules\tournaments\tournaments.service.ts` (line 747) |
| Web BracketTab | `frontend-web_qlgiaidau\src\app\(public)\tournaments\[id]\components\BracketTab.tsx` (line 78) |
| Web types | `frontend-web_qlgiaidau\src\app\(public)\tournaments\[id]\components\bracket\types.ts` (lines 24-25) |
| Backend matches schema | `backend-api_qlgiaidau\src\database\schema\matches.schema.ts` (line 64) |
| Backend matches repository | `backend-api_qlgiaidau\src\modules\matches\matches.repository.ts` (lines 203-226) |
