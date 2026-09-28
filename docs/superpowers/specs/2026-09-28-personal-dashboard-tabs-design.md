# Personal Dashboard Tabs — Design Specification

**Status:** Three-tab design approved in chat; written specification review pending.  
**Date:** 2026-09-28  
**Platform:** Flutter app (Android/iOS; preserve existing responsive behavior).

## 1. Goal

Rename the account-menu entry `Dashboard` to `Của tôi` in Vietnamese and `My Dashboard` in English. Keep the existing `/dashboard` route and app-bar title. Reorganize the authenticated dashboard's long single-scroll content into three clearly labeled tabs without changing data, metric formulas, access rules, or action destinations.

## 2. Current state and source of truth

- The route remains `/dashboard`, handled by `DashboardScreen` in `lib/features/dashboard/screens/dashboard_screen.dart`.
- The app-bar title already resolves to `Của tôi` / `My Dashboard`. The remaining `Dashboard` menu label comes from `settingsDashboard` in `lib/features/profile/screens/profile_settings_screen.dart` and the English/Vietnamese ARB files.
- The authenticated view is one long scroll. Its existing sections are the profile/stat header, sport filter and ranking/ELO content, recent achievements, workspace counts/invitations/roles/assigned matches/tournaments, and quick actions.
- The screen has stateful sport selection, workspace loading/error/empty states, and pull-to-refresh behavior. Keep these contracts intact.
- The existing change record `changes/sports-profile-dashboard-redesign-20260927/04-screen-spec.md` states that no control/state behavior is added. Tabs intentionally supersede that constraint for this request. Preserve the old change record; implement and validate this request in a separate change workspace.

## 3. Approved information architecture

Use text-labeled Flutter tabs. The selected tab on initial entry is **Tổng quan**.

### Tổng quan

- Keep the existing profile summary and four summary metrics.
- Keep the existing quick-action panel in this tab and preserve all current destinations and authorization behavior.
- Do not add, remove, or recalculate actions or metrics.

### Thành tích

- Move the existing sport filter, ranking/ELO section, and recent-achievement section here.
- Preserve the current sport-filter values, ordering, data source, empty/loading/error behavior, and selected sport while switching tabs.

### Giải đấu

- Move the existing workspace content here: workspace summary, pending invitations, role information, assigned matches, and the existing tournament list.
- Preserve existing visibility/access checks and all current tournament/invitation/match actions.
- Preserve tournament search, expansion, and scroll state when switching tabs for the lifetime of the dashboard screen.

The tabs change organization only. No backend request, provider contract, ranking result, tournament rule, access policy, or route changes are part of this design.

## 4. Interaction and accessibility

- Use visible localized tab labels and native Flutter tab semantics; do not use icon-only tabs.
- Keep the existing app-bar title, back behavior, responsive max-width layout, theme tokens, safe-area handling, and pull-to-refresh semantics.
- Use a scrollable tab bar where needed for narrow layouts and large text. Selected state must be perceivable without color alone; retain a clear focus/pressed state and at least 48 dp interactive targets.
- Tab switches must not re-fetch the same workspace or ranking data solely because the user changed tabs. Preserve the current provider lifecycle.
- Do not add decorative motion. Existing content animations must not replay on each tab switch.
- Leave the unauthenticated/guest branch unchanged.

## 5. Localization

- Change the existing `settingsDashboard` values to `Của tôi` (Vietnamese) and `My Dashboard` (English).
- Add localized labels for the three tabs in `lib/l10n/app_vi.arb` and `lib/l10n/app_en.arb`; use the existing localization naming convention and generated localization code. Do not hand-edit generated files.
- Do not change the existing `dashboard_title` values, which already provide the page title.

## 6. Domain profiles and risk

- **Dashboard profile:** required because this surface presents user performance metrics. Create the per-change `dashboard-analytics-spec.md`; document the existing metric source, grain, formula, timezone/null semantics, access scope, and query behavior. This UI change does not redefine those metrics.
- **Recommendation profile:** required because an existing ranking/ELO presentation is moved. Create `recommendation-feature-spec.md` and record that events, candidates, ranking objective/order, score calculation, user controls, and outputs remain unchanged. No recommendation or ranking algorithm work is included.
- **I18N/L10N profile:** required for the Vietnamese and English menu/tab labels and locale validation.
- **Apple iOS profile:** required because the Flutter app has an iOS target. Create `apple-ios-release-review.md`; this change adds no purchase, permission, authentication, account-deletion, or privacy-data behavior. Release review remains a human gate; do not claim App Store approval.
- **Risk:** Normal, presentation-only; no change to existing data classification, access, metric, eligibility, or ranking behavior. Record the product-owner approval in the per-change record.
- Commerce, Transaction, Vietnam compliance, and Theme profiles are not activated; no payment/state mutation, legal-scope change, or new design-token system is introduced.

## 7. Compatibility and preservation

- Keep the route, page class, provider keys, API contracts, metric calculations, and all existing action routes unchanged.
- The current `dashboard_screen.dart`, settings screen, locale sources, and dashboard tests have pre-existing work. Inspect and preserve those diffs; do not replace whole files or modify the separate in-flight change records.
- Keep the current workspace fetch and permissions. Moving content into tabs must not broaden row visibility or alter the guest path.

## 8. Acceptance criteria

1. The profile menu displays `Của tôi` in Vietnamese and `My Dashboard` in English; `/dashboard` and its existing page title still work.
2. Three tabs appear in this order: `Tổng quan`, `Thành tích`, `Giải đấu`, with the approved sections in each tab.
3. Selecting a tab shows its content without duplicating or dropping existing actions and data.
4. Sport selection, tournament search/expansion, provider loading/error/empty states, and refresh behavior are preserved across tab switches.
5. No new API requests, metric computations, ranking decisions, access changes, or route changes are introduced by switching tabs.
6. The layout has no overflow at narrow mobile widths or enlarged text, and tab names/selected state are accessible in both supported locales and themes.
7. Existing dashboard widget coverage is updated to navigate to the tab containing each asserted section; add a behavioral test for tab selection/state preservation only where existing coverage does not prove it.

## 9. Verification evidence expected

- Focused Flutter widget tests for the three tab states, localized labels, and preserved filter/workspace state.
- `flutter gen-l10n` and the focused dashboard test target.
- Visual smoke on an Android emulator at a narrow phone width, including tab switching, scroll, and refresh; review dark theme and enlarged text.
- `workflow/harness/validate-workflow.ps1 -ProjectRoot . -ChangeId <change-id> -Strict` after the per-change artifacts are complete.
- Record any remaining Apple release-review decision as `NEEDS_HUMAN_REVIEW`; do not represent it as approval.
