import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_compact.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The match card typography was enlarged to match the reference product, so
/// every label it prints has to keep shrinking inside its row instead of
/// overflowing the phone width, and the trailing court label has to stay
/// pinned to the right edge of the bar.
///
/// These are the exact inputs that broke it: a long round name (which the bar
/// renders verbatim) and a two-digit round badge. The court label is passed
/// pre-shortened because `TournamentLocationFormatter.matchShortCourt` is what
/// the card actually renders, and the finder has to see that exact string.
const longRound = 'GIẢI PICKLEBALL TẬP CHỊ TRÊM VIỆT NAM LẦN 1 - 2026';
const courtLabel = 'Sân TDTT Q1';

Widget _harness(Widget child) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(width: 320, child: Center(child: child)),
    ),
  );
}

MatchModel _match({
  required String status,
  String round = '16',
  String team1 = 'Nguyễn Minh Danh',
  String team2 = 'Trần Quốc Bảo Khánh',
}) {
  return MatchModel(
    id: 'match-1',
    round: int.parse(round),
    matchNumber: 1,
    bracketPosition: const BracketPosition(round: 1, position: 1),
    team1Id: 'team-1',
    team2Id: 'team-2',
    team1Name: team1,
    team2Name: team2,
    courtName: courtLabel,
    court: courtLabel,
    status: status,
    // `formatRound` returns a group name verbatim, which is how the bar ends
    // up holding a name long enough to overflow.
    stageName: 'GROUP_STAGE',
    groupName: longRound,
    updatedAt: DateTime(2026, 1, 1),
  );
}

/// The court label is the trailing element of every bar: it has to stay pinned
/// to the right edge. Giving both the round name and the court name a Flex and
/// leaving a Spacer between them still fits the row, but leaves the court
/// label floating mid-bar — a defect no overflow assertion can see.
void _expectCourtPinnedRight(WidgetTester tester, {double tolerance = 24}) {
  final court = tester.getRect(find.text(courtLabel).last);
  final card = tester.getRect(find.byType(LiveMatchCardV2));
  expect(card.right - court.right, lessThan(tolerance));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compact card fits a two-digit round and long team names', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        MatchCardCompact(
          match: _match(
            status: 'COMPLETED',
            team1: 'Nguyễn Minh Danh và đồng đội rất dài',
          ),
          isCompleted: true,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('16'), findsWidgets);
  });

  testWidgets('completed bar fits a long round name and pins court right', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        LiveMatchCardV2(match: _match(status: 'COMPLETED'), isCompleted: true),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    _expectCourtPinnedRight(tester);
  });

  testWidgets('scheduled bar fits a long round name and pins court right', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(LiveMatchCardV2(match: _match(status: 'scheduled'))),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    _expectCourtPinnedRight(tester);
  });

  testWidgets('live bar fits a long round name and pins court right', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(LiveMatchCardV2(match: _match(status: 'IN_PROGRESS'), isLive: true)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    // The live bar wraps the court label in a bordered chip, so allow for that
    // chip's own padding on top of the card padding.
    _expectCourtPinnedRight(tester, tolerance: 32);

    // The live badge pulses forever; tear the card down so the test does not
    // end with a pending animation timer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}