# Plan: Lite Management Screen (App Parity with Web)

## Goal
Build a full Lite Management Screen (`LiteManagementScreen`) with 4 tabs matching Web parity, replacing the current pairing-only screen as the management entry point.

## Files to Create
1. **`lib/providers/lite_management_notifier.dart`** — Riverpod `AsyncNotifier` for all management state
2. **`lib/features/lite/screens/lite_management_screen.dart`** — `ConsumerStatefulWidget` with 4 tabs

## Files to Modify
3. **`lib/core/router/app_router.dart`** — Add `/lite-manage/:id` route
4. Navigation entry points:
   - Club detail screen Lite list → tap → `/lite-manage/:id` (replace `/lite-pairing/:id`)
   - After create Lite → `/lite-manage/:id` (replace `/intro/:id`)

## Files NOT to touch
- `lib/features/lite/screens/lite_pairing_screen.dart` (keep as-is)

---

## Phase 1: Notifier (`lite_management_notifier.dart`)

### State model
Use a sealed/free `LiteManagementState` with:
- `tournament`: `Tournament?` — tournament detail
- `participants`: `List<_LiteParticipant>` — raw participants from API
- `selectedIds`: `Set<String>` — for manual pair selection
- `pairing`: `bool` — loading state for manual pair
- `generating`: `bool` — loading state for auto-generate
- `generatingStrategy`: `String?` — which strategy is running
- `creatingBracket`: `bool` — loading for bracket creation
- `error`: `String?` — error message
- `loading`: `bool` — initial load flag
- `matchType`: `String?` — SINGLES/DOUBLES
- `tournamentName`: `String?` — display name

### Methods
- `build(String tournamentId)` → fetches tournament + participants
- `refresh()` → re-fetch all data
- `toggleSelection(String id)` → select/deselect for pairing
- `manualPair()` → POST /tournaments/lite/:id/pairs
- `generatePairs(String strategy)` → POST /tournaments/lite/:id/pairs/generate
- `unpair(String participantId)` → POST /tournaments/lite/:id/pairs/:pid/unpair
- `createBracket()` → POST /tournaments/lite/:id/bracket

### Data models (reuse from pairing screen)
- `_LiteParticipant` — same structure as pairing screen
- `_LiteMember` — same structure as pairing screen

### API endpoints (from existing pairing screen pattern)
- `GET /tournaments/:id` → tournament detail
- `GET /tournaments/lite/:id/participants` → participants
- `POST /tournaments/lite/:id/pairs` → manual pair
- `POST /tournaments/lite/:id/pairs/generate` → auto generate
- `POST /tournaments/lite/:id/pairs/:pid/unpair` → unpair
- `POST /tournaments/lite/:id/bracket` → create bracket

---

## Phase 2: Screen (`lite_management_screen.dart`)

### Widget structure
```dart
class LiteManagementScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  // → ConsumerState with SingleTickerProviderStateMixin
  // → TabController with 4 tabs
  // → body: NestedScrollView with sliver app bar + tab bar + tab views
}
```

### AppBar / Header
- Back button, tournament name as title
- `TabBar` with 4 tabs:
  1. Tổng quan
  2. Người tham gia
  3. Bracket
  4. Trận đấu

### Tab 1: Tổng quan
- **Header card**: tournament name, status badge (color-coded via StatusHelper), sport, match type, max teams
- **Info grid** (2-column): môn thể thao, hình thức (đơn/đôi), thể thức bảng đấu, số đội tối đa, người tham gia, trận đấu
- **Invite code section**: copy button + invite code display
- **QR code**: QrImageView from qr_flutter (wrapped in white container)

### Tab 2: Người tham gia
- Pull-to-refresh via RefreshIndicator
- **Doubles mode** (matchType == DOUBLES):
  - Pending pool section: "Chờ ghép cặp (N)" with selectable cards
  - Manual pair button (visible when 2 selected)
  - Auto-generate section: "Ngẫu nhiên" + "Cân bằng ELO" buttons
  - Odd-number notice
  - Paired section: "Đã ghép cặp (N)" with "Hủy ghép" button
- **Singles mode**: flat list with "Đã tham gia" badge
- **Tạo bracket button** at bottom (when participants exist)

### Tab 3: Bracket
- If no bracket: placeholder with info icon + "Tạo bracket" button
- If bracket exists: placeholder showing bracket info + "Xem bracket" button

### Tab 4: Trận đấu
- Placeholder: "Danh sách trận đấu sẽ xuất hiện sau khi tạo bracket"

### Style rules
- Use `context.colors` everywhere (no hardcoded colors except for QrImageView white bg)
- Radius ≤ 12 (`AppTheme.radiusXL` = 12 is max)
- Vietnamese labels 100%
- Loading: `CircularProgressIndicator`
- Error: error icon + retry button
- Empty: empty state card

---

## Phase 3: Route Registration

### Add to `app_router.dart`
```dart
GoRoute(
  path: '/lite-manage/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return LiteManagementScreen(tournamentId: id);
  },
),
```

### Update navigation entry points
1. **Club detail screen** — In the Lite tournament list, change navigation from `/lite-pairing/:id` to `/lite-manage/:id`
2. **After create Lite** — Change navigation from `/intro/:id` to `/lite-manage/:id` in `create_club_tournament_screen.dart`

---

## Phase 4: Review Checklist

- [x] SKILLS.md: uses `AsyncNotifier` (not `StateNotifier`)
- [x] SKILLS.md: SRP separation (Notifier ≠ Screen)
- [x] Taste: radius ≤ 12 (`AppTheme.radiusXL` = 12 max)
- [x] Taste: no hardcoded colors (all via `context.colors` or `AppTheme`)
- [x] Vietnamese: all labels 100% Vietnamese
- [x] State handling: loading, error, empty states for all async operations
- [x] No regression: `LitePairingScreen` untouched
- [x] Follows existing patterns: Dio via `dioClientProvider`, `AppLogger`, `go_router`, `flutter_riverpod`
- [x] Clean Architecture: domain (models) → data (API via dio) → providers (Notifier) → features (Screen)
