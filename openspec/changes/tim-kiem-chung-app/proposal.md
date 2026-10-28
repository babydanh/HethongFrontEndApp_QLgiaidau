## Why

Organizer management tabs (Lịch, VĐV) have no unified search. The approved mock
(`~/.lavish/tim-kiem-chung.html`) adds one search icon in the toolbar that drops
down a search box with filters, shared by every list tab.

## What Changes

- New shared `SearchFilterBar` + `SearchFilterToggle` (`lib/shared/widgets/search_filter_bar.dart`) and a per-tab Riverpod state keyed by tab.
- Lịch grid toolbar: search icon first, print moved into a ⋯ menu; non-matching grid cards fade to opacity 0.22.
- VĐV tab: search icon row + filters Duyệt / Phí; people list honours the same state.
- Not wired (no screen in origin/main): Kết quả. Bảng đấu has no filterable list. "Có mặt" filter dropped (no check-in field in the model).

## Impact

- ARB keys added to `app_vi.arb` / `app_en.arb` (generated l10n regenerated).
- Touches `tournament_schedule_court_grid.dart`, `schedule_grid.dart`, `tournament_management_athletes_tab.dart`, `tournament_management_people_section.dart`.
