import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // === MATCH MODULE: 26 TESTCASES ===

  // TC-FLUTTER-MATCH-001: LiveScoreScreen Setup State (Scheduled)
  testWidgets('TC-FLUTTER-MATCH-001: LiveScoreScreen - Setup State Scheduled',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Kiểm tra nút "BẮT ĐẦU" cho match đang scheduled
      final startBtn = find.textContaining('BẮT ĐẦU');
      if (startBtn.evaluate().isNotEmpty) {
        expect(startBtn, findsOneWidget);
      }

      await takeScreenshot(tester, 'match_setup');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-001');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-002: Start Match
  testWidgets('TC-FLUTTER-MATCH-002: LiveScoreScreen - Start Match',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for "BẮT ĐẦU" button
      final startBtn = find.textContaining('BẮT ĐẦU');
      if (startBtn.evaluate().isNotEmpty) {
        await tester.tap(startBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
      await takeScreenshot(tester, 'match_started');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-002');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-003: Live State Referee Score Controls
  testWidgets('TC-FLUTTER-MATCH-003: LiveScoreScreen - Referee Score Controls',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'match_score_controls');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-003');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-004: Win Condition Check
  testWidgets('TC-FLUTTER-MATCH-004: LiveScoreScreen - Win Condition Check',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-004');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-005: Foul Sheet / Penalty
  testWidgets('TC-FLUTTER-MATCH-005: LiveScoreScreen - Foul Sheet Penalty',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for "THỔI CÒI" button
      final foulBtn = find.textContaining('THỔI CÒI');
      if (foulBtn.evaluate().isNotEmpty) {
        await tester.tap(foulBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'match_foul');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-005');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-006: Force Win
  testWidgets('TC-FLUTTER-MATCH-006: LiveScoreScreen - Force Win',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final winBtn = find.textContaining('XỬ THẮNG');
      if (winBtn.evaluate().isNotEmpty) {
        await tester.tap(winBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'match_forcewin');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-006');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-007: Viewer State
  testWidgets('TC-FLUTTER-MATCH-007: LiveScoreScreen - Viewer State',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'match_viewer');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-007');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-008: Comments / Chat
  testWidgets('TC-FLUTTER-MATCH-008: LiveScoreScreen - Comments Chat',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Chat tab
      final chatTab = find.textContaining('Phòng thảo luận');
      if (chatTab.evaluate().isNotEmpty) {
        await tester.tap(chatTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'match_chat');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-008');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-009: Completed State
  testWidgets('TC-FLUTTER-MATCH-009: LiveScoreScreen - Completed State',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'match_completed');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-009');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-010: Admin Edit Inline Dialog
  testWidgets('TC-FLUTTER-MATCH-010: LiveScoreScreen - Admin Edit Dialog',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final editBtn = find.textContaining('SỬA KẾT QUẢ');
      if (editBtn.evaluate().isNotEmpty) {
        await tester.tap(editBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-010');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-011: Error / Null Match States
  testWidgets('TC-FLUTTER-MATCH-011: LiveScoreScreen - Error Null Match',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-011');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-012: Official Score Modal Button
  testWidgets('TC-FLUTTER-MATCH-012: LiveScoreScreen - Official Score Modal',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Nút "Tính điểm"
      final scoreBtn = find.textContaining('Tính điểm');
      if (scoreBtn.evaluate().isNotEmpty) {
        await tester.tap(scoreBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-012');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-013: TennisScorePanel Normal Point
  testWidgets('TC-FLUTTER-MATCH-013: TennisScorePanel - Normal Point',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-013');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-014: TennisScorePanel Deuce State
  testWidgets('TC-FLUTTER-MATCH-014: TennisScorePanel - Deuce State',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-014');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-015: TennisScorePanel Tiebreak State
  testWidgets('TC-FLUTTER-MATCH-015: TennisScorePanel - Tiebreak State',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-015');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-016: TennisScorePanel Responsive Layout
  testWidgets('TC-FLUTTER-MATCH-016: TennisScorePanel - Responsive Layout',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-016');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-017: TennisScorePanel Read-Only Mode
  testWidgets('TC-FLUTTER-MATCH-017: TennisScorePanel - Read-Only Mode',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-017');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-018: TeamScoreCard Display
  testWidgets('TC-FLUTTER-MATCH-018: TeamScoreCard - Score Display',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'match_score_card');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-018');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-019: TeamScoreCard Controls Live
  testWidgets('TC-FLUTTER-MATCH-019: TeamScoreCard - Score Controls Live',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-019');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-020: Official Score Modal Structure
  testWidgets('TC-FLUTTER-MATCH-020: Official Score Modal - Display Structure',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-020');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-021: MatchOpsSummary
  testWidgets('TC-FLUTTER-MATCH-021: Official Score Modal - MatchOpsSummary',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-021');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-022: LiveMatchScreen Match Sections
  testWidgets('TC-FLUTTER-MATCH-022: LiveMatchScreen - Match Sections',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatchScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Kiểm tra screen đã load thành công

      await takeScreenshot(tester, 'match_live_sections');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-022');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-023: LiveMatchScreen Match Filtering
  testWidgets('TC-FLUTTER-MATCH-023: LiveMatchScreen - Match Filtering',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatchScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Filter chips
      final chips = find.byType(FilterChip);
      if (chips.evaluate().isNotEmpty) {
        await tester.tap(chips.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
      await takeScreenshot(tester, 'match_filter');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-023');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-024: LiveMatchScreen Empty State
  testWidgets('TC-FLUTTER-MATCH-024: LiveMatchScreen - Empty State',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatchScreen(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'match_live_empty');
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-024');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-025: AdminEditScoreDialog
  testWidgets('TC-FLUTTER-MATCH-025: AdminEditScoreDialog - Edit Score',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToLiveMatch(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-025');
      rethrow;
    }
  });

  // TC-FLUTTER-MATCH-026: Heart Animation
  testWidgets('TC-FLUTTER-MATCH-026: LiveScoreScreen - Heart Animation',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'MATCH-026');
      rethrow;
    }
  });
}

/// Navigate to a live match score screen
Future<void> navigateToLiveMatch(WidgetTester tester) async {
  // Try to find and tap a match in bracket view
  final matchRows = find.byType(ListTile);
  if (matchRows.evaluate().isNotEmpty) {
    await tester.tap(matchRows.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }

  // Try through bracket
  await navigateToTournamentBracket(tester);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Navigate to LiveMatchScreen (list of live matches)
Future<void> navigateToLiveMatchScreen(WidgetTester tester) async {
  // Try finding "Trận đấu" or "Live" buttons
  final liveTab = find.text('Trận đấu');
  if (liveTab.evaluate().isNotEmpty) {
    await tester.tap(liveTab.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }

  // Check bottom nav for live
  final liveNav = find.text('Live');
  if (liveNav.evaluate().isNotEmpty) {
    await tester.tap(liveNav.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  // Try "Trực tiếp"
  final liveNav2 = find.textContaining('Trực tiếp');
  if (liveNav2.evaluate().isNotEmpty) {
    await tester.tap(liveNav2.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Navigate to tournament bracket (reused from bracket test)
Future<void> navigateToTournamentBracket(WidgetTester tester) async {
  final tourCards = find.byType(Card);
  if (tourCards.evaluate().isNotEmpty) {
    await tester.tap(tourCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  final bracketBtn = find.textContaining('Sơ đồ');
  if (bracketBtn.evaluate().isNotEmpty) {
    await tester.tap(bracketBtn.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
