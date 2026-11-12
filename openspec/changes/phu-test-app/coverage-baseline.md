# Độ phủ nền (trước khi thêm test)

Lệnh: `flock /tmp/qlgd-heavy.lock cloud-flutter test --no-pub --coverage -j 2` (3653 test xanh).
Phạm vi tính: `lib/**` có trong lcov, loại file sinh (`*.g.dart`, `*.freezed.dart`, `app_localizations*`).

| Chỉ số | Giá trị |
|---|---|
| File trong lcov | 634 |
| Dòng khả thi | 98206 |
| Dòng đã phủ | 54076 |
| **Độ phủ dòng** | **55,06%** |

## 30 file nhiều dòng chưa phủ nhất (chưa phủ / tổng / %)

| File | Chưa phủ | Tổng | % |
|---|---|---|---|
| features/lite/screens/lite_management_screen.dart | 1453 | 2137 | 32,0 |
| features/tournament/screens/create_public_quick_tournament_screen.dart | 1266 | 1268 | 0,2 |
| features/chat/screens/chat_detail_screen.dart | 1123 | 1239 | 9,4 |
| features/community/screens/club_match_sessions_screen.dart | 1105 | 1105 | 0,0 |
| features/community/screens/club_management_screen.dart | 1101 | 1101 | 0,0 |
| features/community/widgets/club_activity_tab.dart | 1032 | 1032 | 0,0 |
| features/match/screens/live_score_screen.dart | 885 | 1614 | 45,2 |
| features/register/screens/tournament_register_screen.dart | 739 | 1423 | 48,1 |
| features/organizer_ops/screens/organizer_ops_screen.dart | 699 | 1930 | 63,8 |
| features/chat/widgets/chat_room_settings_sheet.dart | 636 | 636 | 0,0 |
| features/profile/screens/user_profile_screen.dart | 619 | 620 | 0,2 |
| features/community/screens/create_club_screen.dart | 569 | 570 | 0,2 |
| features/register/screens/doubles_registration_screen.dart | 514 | 1012 | 49,2 |
| data/repositories/api/api_community_repository.dart | 472 | 472 | 0,0 |
| features/social/screens/social_detail_screen.dart | 440 | 467 | 5,8 |
| features/live/screens/live_match_screen.dart | 430 | 430 | 0,0 |
| features/community/screens/edit_club_screen.dart | 417 | 450 | 7,3 |
| features/payment/screens/payments_screen.dart | 410 | 434 | 5,5 |
| core/router/app_router.dart | 406 | 591 | 31,3 |
| data/repositories/api/api_tournament_repository.dart | 398 | 739 | 46,1 |
| features/chat/screens/chat_screen.dart | 387 | 388 | 0,3 |
| features/match/notifiers/score_panel_notifier.dart | 386 | 887 | 56,5 |
| data/repositories/api/api_match_repository.dart | 336 | 821 | 59,1 |
| data/repositories/api/api_community_social_repository.dart | 178 | 178 | 0,0 |
| data/repositories/api/api_social_session_repository.dart | 225 | 329 | 31,6 |
| data/repositories/api/api_team_repository.dart | 203 | 271 | 25,1 |
| providers/lite_management_notifier.dart | 267 | 609 | 56,2 |
| providers/social_provider.dart | 258 | 344 | 25,0 |
| data/models/social_session_model.dart | 279 | 512 | 45,5 |
| core/services/match_socket_service.dart | 165 | 181 | 8,8 |
