import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_scoreboard_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(alignment: Alignment.bottomLeft, child: child),
  ),
);

void main() {
  testWidgets('TC-LIVEVIEW-11 shows both sides and their scores stacked', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const LiveScoreboardOverlay(
          team1: Text('Alpha'),
          team2: Text('Beta'),
          score1: 7,
          score2: 11,
        ),
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    // Two rows stacked: the second side sits below the first.
    expect(
      tester.getTopLeft(find.text('Beta')).dy,
      greaterThan(tester.getTopLeft(find.text('Alpha')).dy),
    );
  });

  testWidgets('TC-LIVEVIEW-12 a long side name is cut, not overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 360,
          // Loose constraints, like a Positioned parent gives the overlay.
          child: Align(
            alignment: Alignment.centerLeft,
            child: LiveScoreboardOverlay(
              team1: Text(
                'N' * 200,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              team2: const Text('Beta'),
              score1: 0,
              score2: 0,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(LiveScoreboardOverlay)).width,
      lessThanOrEqualTo(220),
    );
  });

  testWidgets('TC-LIVEVIEW-13 finished match greys the score cells', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const LiveScoreboardOverlay(
          team1: Text('Alpha'),
          team2: Text('Beta'),
          score1: 11,
          score2: 9,
          finished: true,
        ),
      ),
    );

    final cells = tester.widgetList<DecoratedBox>(
      find.byKey(const ValueKey('live-scoreboard-score-bg')),
    );
    expect(cells, hasLength(2));
    for (final c in cells) {
      final gradient =
          (c.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient.colors.first, const Color(0xFF475569));
    }
  });

  testWidgets('TC-LIVEVIEW-17 a changed score pops in and the old one leaves', (
    tester,
  ) async {
    Widget host(int score1) => MaterialApp(
      home: Scaffold(
        body: LiveScoreboardOverlay(
          team1: Text('A'),
          team2: Text('B'),
          score1: score1,
          score2: 0,
        ),
      ),
    );

    await tester.pumpWidget(host(2));
    await tester.pumpWidget(host(3));
    await tester.pump(const Duration(milliseconds: 60));

    // Mid-transition both the old and the new value are on screen.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('TC-LIVEVIEW-18 reduced motion swaps the score at once', (
    tester,
  ) async {
    Widget host(int score1) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: LiveScoreboardOverlay(
            team1: Text('A'),
            team2: Text('B'),
            score1: score1,
            score2: 0,
          ),
        ),
      ),
    );

    await tester.pumpWidget(host(2));
    await tester.pumpWidget(host(3));
    await tester.pump();

    expect(find.text('2'), findsNothing);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('TC-LIVEVIEW-19 exposes one spoken summary when labelled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveScoreboardOverlay(
            team1: Text('ODI695'),
            team2: Text('SON BAO B'),
            score1: 3,
            score2: 2,
            semanticsLabel: 'odi695 3, son bao b 2',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('odi695 3, son bao b 2'), findsOneWidget);
    handle.dispose();
  });
}
