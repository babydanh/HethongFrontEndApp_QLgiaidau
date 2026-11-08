import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/widgets/match_card/live_match_card_v2.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SizedBox(width: 360, child: SingleChildScrollView(child: child)),
  ),
);

MatchModel _match({required bool stale}) => MatchModel(
  id: 'm',
  round: 1,
  matchNumber: 1,
  status: 'ONGOING',
  isStaleLive: stale,
  team1Name: 'Đội A',
  team2Name: 'Đội B',
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime(2026, 11, 1),
);

void main() {
  testWidgets('TC-SLM-APP-06 stale live card shows Tạm dừng instead of LIVE', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(LiveMatchCardV2(match: _match(stale: true), isLive: true)),
    );
    await tester.pump();

    expect(find.text('Tạm dừng'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    // Drop the tree so the looping pulse leaves no pending timer.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('TC-SLM-APP-07 normal live card still shows LIVE', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(LiveMatchCardV2(match: _match(stale: false), isLive: true)),
    );
    await tester.pump();

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('Tạm dừng'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });
}
