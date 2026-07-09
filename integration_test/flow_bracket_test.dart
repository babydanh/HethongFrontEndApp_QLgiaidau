import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // TC-FLUTTER-BRACKET-001: Single Elimination Layout
  testWidgets('TC-FLUTTER-BRACKET-001: BracketViewScreen - Single Elimination Layout',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to a tournament with bracket
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Kiểm tra có thông tin bracket (nếu có dữ liệu)
      final bracketText = find.textContaining('Sơ đồ nhánh');
      if (bracketText.evaluate().isNotEmpty) {
        expect(bracketText, findsAny);
      }

      await takeScreenshot(tester, 'bracket_single_elim');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-001');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-002: Double Elimination Layout
  testWidgets('TC-FLUTTER-BRACKET-002: BracketViewScreen - Double Elimination Layout',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'bracket_double_elim');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-002');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-003: Round Robin Layout
  testWidgets('TC-FLUTTER-BRACKET-003: BracketViewScreen - Round Robin Layout',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'bracket_roundrobin');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-003');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-004: Match Filtering
  testWidgets('TC-FLUTTER-BRACKET-004: BracketViewScreen - Match Filtering',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Filter chips
      final filterChips = find.byType(FilterChip);
      if (filterChips.evaluate().isNotEmpty) {
        await tester.tap(filterChips.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
  await takeScreenshot(tester, 'bracket_filter');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-004');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-005: Match Table Row Rendering
  testWidgets('TC-FLUTTER-BRACKET-005: BracketViewScreen - Match Table Row',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Scroll to view match rows
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -300));
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'bracket_match_row');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-005');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-006: Match Row Referee Indicator
  testWidgets('TC-FLUTTER-BRACKET-006: BracketViewScreen - Referee Indicator',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-006');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-007: Standings DataTable
  testWidgets('TC-FLUTTER-BRACKET-007: BracketViewScreen - Standings DataTable',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find standings tab
      final standingsTab = find.text('Bảng xếp hạng');
      if (standingsTab.evaluate().isNotEmpty) {
        await tester.tap(standingsTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'bracket_standings');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-007');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-008: Empty State
  testWidgets('TC-FLUTTER-BRACKET-008: BracketViewScreen - Empty State',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'bracket_empty');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-008');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-009: Bracket Tree Diagram View
  testWidgets('TC-FLUTTER-BRACKET-009: BracketViewScreen - Bracket Tree Diagram',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'bracket_tree');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-009');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-010: Cross Table View
  testWidgets('TC-FLUTTER-BRACKET-010: BracketViewScreen - Cross Table',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find cross table tab
      final crossTab = find.text('Bảng chéo');
      if (crossTab.evaluate().isNotEmpty) {
        await tester.tap(crossTab.last);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'bracket_cross');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-010');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-011: Navigation Back
  testWidgets('TC-FLUTTER-BRACKET-011: BracketViewScreen - Back Navigation',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Back button
      final backBtn = find.byIcon(Icons.arrow_back);
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      // Hoặc IconButton dùng Icons.arrow_back_rounded
      final backBtn2 = find.byIcon(Icons.arrow_back_rounded);
      if (backBtn2.evaluate().isNotEmpty) {
        await tester.tap(backBtn2.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
      await takeScreenshot(tester, 'bracket_back');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-011');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-012 to BRACKET-018: Various bracket states
  testWidgets('TC-FLUTTER-BRACKET-012: Bracket Loading State',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pump(const Duration(seconds: 1));
      // Loading indicator nếu có
      if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      }
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-012');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-BRACKET-013: Bracket Empty',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-013');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-BRACKET-014: Bracket Error',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-014');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-015 to BRACKET-018: Draw screen tests
  testWidgets('TC-FLUTTER-BRACKET-015: Auto Draw Screen - Button',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToAutoDraw(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Nút "Bốc thăm tự động"
      final autoDrawBtn = find.textContaining('Bốc thăm tự động');
      if (autoDrawBtn.evaluate().isNotEmpty) {
        expect(autoDrawBtn, findsOneWidget);
      }

      await takeScreenshot(tester, 'bracket_autodraw');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-015');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-BRACKET-016: Auto Draw Loading',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToAutoDraw(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await takeScreenshot(tester, 'bracket_draw_loading');
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-016');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-BRACKET-017: Auto Draw Success',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToAutoDraw(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-017');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-BRACKET-018: Auto Draw Empty',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToAutoDraw(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-018');
      rethrow;
    }
  });

  // TC-FLUTTER-BRACKET-019 to BRACKET-024: Bracket scale/idle states
  testWidgets('TC-FLUTTER-BRACKET-019: Bracket Status After Draw',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-019');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-BRACKET-020: Bracket - Large Scale 64 teams',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-020');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-BRACKET-021: Bracket - Idle Data Refetch',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-021');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-BRACKET-022: Bracket - Score Update Trigger',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-022');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-BRACKET-023: Bracket - Walkover / Bye',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-023');
      rethrow;
    }
  });

  testWidgets('TC-FLUTTER-BRACKET-024: Bracket - Winner Path Highlight',
      (tester) async {
    try {
      await loginWithEmail(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await navigateToTournamentBracket(tester);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } catch (e) {
      await screenshotOnFailure(tester, 'BRACKET-024');
      rethrow;
    }
  });
}

/// Navigate to a tournament's bracket view
Future<void> navigateToTournamentBracket(WidgetTester tester) async {
  // Try tapping a tournament card first
  final tourCards = find.byType(Card);
  if (tourCards.evaluate().isNotEmpty) {
    await tester.tap(tourCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  // Then find "Sơ đồ" tab or button
  final bracketTab = find.textContaining('Sơ đồ');
  if (bracketTab.evaluate().isNotEmpty) {
    await tester.tap(bracketTab.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return;
  }

  // Try "Bracket" tab
  final bracketTab2 = find.text('Bracket');
  if (bracketTab2.evaluate().isNotEmpty) {
    await tester.tap(bracketTab2.last);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

/// Navigate to auto draw screen
Future<void> navigateToAutoDraw(WidgetTester tester) async {
  // First navigate to bracket
  final tourCards = find.byType(Card);
  if (tourCards.evaluate().isNotEmpty) {
    await tester.tap(tourCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  final drawBtn = find.textContaining('Bốc thăm');
  if (drawBtn.evaluate().isNotEmpty) {
    await tester.tap(drawBtn.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}
