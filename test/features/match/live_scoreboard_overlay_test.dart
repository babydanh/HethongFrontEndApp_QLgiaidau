import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_scoreboard_overlay.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/scoreboard_set_columns.dart';
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

  testWidgets('TC-LIVEVIEW-21 broadcast-size board: two slim rows', (
    tester,
  ) async {
    // A portrait-sized picture (the scale follows the width it is given).
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 411,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: LiveScoreboardOverlay(
              team1: Text('Alpha'),
              team2: Text('Beta'),
              score1: 3,
              score2: 1,
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(LiveScoreboardOverlay));
    // Two 20dp rows plus the 2dp gap, and no wider than a TV score bug.
    expect(size.height, lessThanOrEqualTo(44));
    expect(size.width, lessThanOrEqualTo(170));
  });

  testWidgets('TC-LIVEVIEW-22 the board is translucent so the picture shows', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const LiveScoreboardOverlay(
          team1: Text('Alpha'),
          team2: Text('Beta'),
          score1: 3,
          score2: 1,
        ),
      ),
    );

    final panel = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('live-scoreboard-panel')),
    );
    expect(((panel.decoration as BoxDecoration).color)!.a, lessThan(0.8));
    final cell = tester.widgetList<DecoratedBox>(
      find.byKey(const ValueKey('live-scoreboard-score-bg')),
    );
    for (final c in cell) {
      final gradient =
          (c.decoration as BoxDecoration).gradient as LinearGradient;
      expect(gradient.colors.first.a, lessThan(1));
    }
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
      // Grey hue kept; only the alpha is lowered so the picture shows through.
      expect(
        gradient.colors.first.withValues(alpha: 1),
        const Color(0xFF475569),
      );
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

  testWidgets('TC-SETCOL-07 finished sets show their scores next to the current one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const LiveScoreboardOverlay(
          team1: Text('Alpha'),
          team2: Text('Beta'),
          score1: 4,
          score2: 3,
          setColumns: [
            SetColumn(
              setNumber: 1,
              team1: 11,
              team2: 5,
              state: SetColumnState.finished,
              winner: 1,
            ),
            SetColumn(
              setNumber: 2,
              team1: 8,
              team2: 11,
              state: SetColumnState.finished,
              winner: 2,
            ),
            SetColumn(
              setNumber: 3,
              team1: 4,
              team2: 3,
              state: SetColumnState.current,
              winner: null,
            ),
          ],
        ),
      ),
    );

    for (final text in ['S1', 'S2', 'S3', '11', '5', '8', '4', '3']) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.text('11'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    // Still one blue score cell per row for the current set.
    expect(
      find.byKey(const ValueKey('live-scoreboard-score-bg')),
      findsNWidgets(2),
    );
  });

  testWidgets('TC-SETCOL-08 no columns keeps the single-set board without a header', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const LiveScoreboardOverlay(
          team1: Text('Alpha'),
          team2: Text('Beta'),
          score1: 4,
          score2: 3,
        ),
      ),
    );

    expect(find.text('S1'), findsNothing);
  });

  testWidgets('TC-LIVEOVL-10 board shrinks with a 400dp video and is glass', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 400,
          child: Align(
            alignment: Alignment.topLeft,
            child: LiveScoreboardOverlay(
              team1: Text('Alpha'),
              team2: Text('Beta'),
              score1: 3,
              score2: 1,
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(LiveScoreboardOverlay));
    // Old board: 42dp tall, up to 170dp wide; now 70% of that.
    expect(size.height, lessThanOrEqualTo(42 * 0.7 + 1));
    expect(size.width, lessThanOrEqualTo(170 * 0.7 + 1));
    expect(
      find.descendant(
        of: find.byType(LiveScoreboardOverlay),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
  });
}
