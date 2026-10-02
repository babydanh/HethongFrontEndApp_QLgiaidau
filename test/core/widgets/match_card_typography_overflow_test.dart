import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/match_card_compact.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The match card typography was enlarged to match the reference product, so
/// the labels it prints (round name, court, team names) have to keep shrinking
/// inside the row instead of overflowing the phone width. A two-digit round and
/// a long round/court name are the exact inputs that broke it.
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
  required String round,
  required String courtName,
  String status = 'COMPLETED',
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
    status: status,
    stageName: 'GROUP_STAGE',
    groupName: longLabel,
    courtName: courtName,
    court: courtName,
    updatedAt: DateTime(2026, 1, 1),
  );
}

const longLabel = 'GIẢI PICKLEBALL TẬP CHỊ TRÊM VIỆT NAM LẦN 1 - 2026';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compact card fits a two-digit round and long team names', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        MatchCardCompact(
          match: _match(
            round: '16',
            courtName: '',
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

  testWidgets('completed bar ellipsizes a long round and court name', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        LiveMatchCardV2(
          match: _match(
            round: '16',
            courtName: 'Sân trung tâm TDTT Quận 1',
            team1: longLabel,
            team2: longLabel,
          ),
          isCompleted: true,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .any((text) => text.overflow == TextOverflow.ellipsis),
      isTrue,
    );
  });

  testWidgets('scheduled bar ellipsizes a long round and court name', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        LiveMatchCardV2(
          match: _match(
            round: '16',
            courtName: 'Sân trung tâm TDTT Quận 1',
            team1: longLabel,
            team2: longLabel,
            status: 'scheduled',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .any((text) => text.overflow == TextOverflow.ellipsis),
      isTrue,
    );
  });

  testWidgets('live bar ellipsizes a long round name', (tester) async {
    await tester.pumpWidget(
      _harness(
        LiveMatchCardV2(
          match: _match(
            round: '16',
            courtName: 'Sân trung tâm TDTT Quận 1',
            team1: longLabel,
            team2: longLabel,
            status: 'IN_PROGRESS',
          ),
          isLive: true,
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);

    // The live badge pulses forever; tear the card down so the test does not
    // end with a pending animation timer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}