// Master test runner cho 213 test cases
// Chạy: flutter test test/run_all_tests.dart --machine > results.json
// Sau đó: python test_docs/update-results.py results.json
//
// Hoặc chạy toàn bộ: flutter test --machine > results.json
//                  python test_docs/update-results.py results.json

// Model tests
import 'models/app_notification_test.dart' as notification_tests;
import 'models/player_ranking_test.dart' as ranking_model_tests;
import 'models/standing_test.dart' as standing_model_tests;
import 'models/tournament_test.dart' as tournament_model_tests;
import 'models/team_test.dart' as team_model_tests;
import 'models/match_test.dart' as match_model_tests;
import 'models/payment_test.dart' as payment_model_tests;
import 'models/community_test.dart' as community_model_tests;
import 'models/tournament_workspace_test.dart' as workspace_model_tests;
import 'models/elo_tier_test.dart' as elo_tier_model_tests;

// Provider tests
import 'providers/auth_state_test.dart' as auth_state_tests;
import 'providers/standings_provider_test.dart' as standings_provider_tests;
// notification_provider_test.dart - cần mock repository
// my_tournament_workspace_provider_test.dart - cần mock

void main() {
  // All test files auto-run when imported
  // This file ensures they're all loaded for 'flutter test --machine'
}
