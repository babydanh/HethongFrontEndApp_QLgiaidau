## 1. Error mapping and notifier

- [x] 1.1 Add typed domain error for tournament score writes; repository throws it only for tournament matches when the API code is `TOURNAMENT_NOT_STARTED`, preserving other failures and club/social matches.
- [x] 1.2 Handle this error before generic HTTP 409 revision conflict in score notifier and show localized message; no tournament-launch action in App.
- [x] 1.3 Add notifier regression test for dedicated VI/EN feedback and non-mapping of other 409 errors.
- [x] 1.4 Add matching Vietnamese/English ARB keys and regenerate localization output.
- [x] 1.5 Run related Flutter test and strict OpenSpec validation; record evidence in handoff. `openspec validate khai-mac-khi-chot-diem --strict` PASS; test `test/match/score_panel_tournament_not_started_test.dart` chạy xanh trên nhánh gộp gop-con-lai-20261024 (bộ 8 file vùng gộp: 43/43 PASS).