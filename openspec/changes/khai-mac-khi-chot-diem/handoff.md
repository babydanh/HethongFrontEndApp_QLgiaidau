## Handoff

- Source of truth: Backend API error code `TOURNAMENT_NOT_STARTED` in the score-update response.
- Scope: Flutter App only; preserve error code through domain repository boundary and render localized Vietnamese/English notifier feedback. No tournament-launch action.
- Contract impact: No API contract change; client-side typed error mapping only.
- Evidence: `flutter gen-l10n` exited 0; `openspec validate khai-mac-khi-chot-diem --strict` exited 0.
- Test: `flutter test --no-pub test/match/score_panel_tournament_not_started_test.dart` could not execute because Flutter asset bundling requires the absent `.env` (`No file or variants found for asset: .env.`). Do not create/copy `.env`.
- Risk/status: The regression test is present but unverified due to the repository's secret-file asset requirement. Do not claim the App change is fully verified until the targeted test is rerun in an environment with the required local `.env`.
- Next action: Run the targeted Flutter test in an authorized configured environment, then complete review and push only branch `g1-khai-mac`.