import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_board_palette.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_row.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/results_rounds.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match(
  String id, {
  String status = 'SCHEDULED',
  String team2Id = 'b',
  String? refereeName,
  String? courtName,
  DateTime? scheduledTime,
}) {
  return MatchModel(
    id: id,
    round: 1,
    matchNumber: 1,
    bracketPosition: const BracketPosition(round: 1, position: 1),
    team1Id: 'a',
    team2Id: team2Id,
    status: status,
    refereeName: refereeName,
    courtName: courtName,
    scheduledTime: scheduledTime,
    team1Players: [ParticipantPlayer(slot: 1, fullName: 'Nguyen Van A')],
    team2Players: [ParticipantPlayer(slot: 1, fullName: 'Tran Thi B')],
    updatedAt: DateTime(2026, 1, 1),
  );
}

Future<void> _pump(
  WidgetTester tester,
  MatchModel match, {
  VoidCallback? onScore,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: ResultsMatchRow(match: match, label: '#V1', onScore: onScore),
        ),
      ),
    ),
  );
}

Color _borderOf(WidgetTester tester, String id) {
  final box = tester.widget<Container>(
    find.byKey(ValueKey('results-tone-$id')),
  );
  return ((box.decoration! as BoxDecoration).border! as Border).left.color;
}

void main() {
  group('left status border (TC-RBR-30)', () {
    for (final (status, team2Id, tone) in [
      ('SCHEDULED', 'b', MatchTone.ready),
      ('SCHEDULED', '', MatchTone.wait),
      ('ONGOING', 'b', MatchTone.live),
      ('COMPLETED', 'b', MatchTone.done),
      ('DISPUTED', 'b', MatchTone.done),
      ('CANCELLED', 'b', MatchTone.cancel),
    ]) {
      testWidgets('$status / "$team2Id" uses the $tone colour', (tester) async {
        await _pump(tester, _match('m', status: status, team2Id: team2Id));
        expect(_borderOf(tester, 'm'), ResultsBoardPalette.toneBorder(tone));
      });
    }
  });

  group('score button (TC-RBR-31)', () {
    testWidgets('is a 44 dp target centred between the two sides', (
      tester,
    ) async {
      await _pump(tester, _match('m'), onScore: () {});
      final button = find.byKey(const ValueKey('results-add-score-m'));
      expect(button, findsOneWidget);
      expect(tester.getSize(button).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(44));

      final side1 = tester.getCenter(
        find.byKey(const ValueKey('side-lines-player-0')).first,
      );
      final side2 = tester.getCenter(
        find.byKey(const ValueKey('side-lines-player-0')).last,
      );
      final centre = tester.getCenter(button).dy;
      expect(centre, greaterThan(side1.dy));
      expect(centre, lessThan(side2.dy));
      expect(centre, closeTo((side1.dy + side2.dy) / 2, 3));
    });

    testWidgets('tapping it asks for the score', (tester) async {
      var taps = 0;
      await _pump(tester, _match('m'), onScore: () => taps++);
      await tester.tap(find.byKey(const ValueKey('results-add-score-m')));
      expect(taps, 1);
    });

    testWidgets('is absent for a viewer', (tester) async {
      await _pump(tester, _match('m'));
      expect(find.byKey(const ValueKey('results-add-score-m')), findsNothing);
    });
  });

  group('meta line (TC-RBR-32)', () {
    testWidgets('shows time, court and referee when they exist', (
      tester,
    ) async {
      await _pump(
        tester,
        _match(
          'm',
          courtName: 'Sân 2',
          refereeName: 'Hoang Nam',
          scheduledTime: DateTime.utc(2026, 11, 3, 7, 0),
        ),
      );
      expect(find.byKey(const ValueKey('results-meta-time-m')), findsOneWidget);
      expect(find.text('TT: Hoang Nam'), findsOneWidget);
    });

    testWidgets('has no referee text without a referee', (tester) async {
      await _pump(tester, _match('m', courtName: 'Sân 2'));
      expect(
        find.byKey(const ValueKey('results-meta-referee-m')),
        findsNothing,
      );
    });
  });

  group('sides (TC-RBR-33)', () {
    testWidgets('doubles stack both players, a team shows its logo', (
      tester,
    ) async {
      final doubles = _match('m').copyWith(
        team1Players: [
          ParticipantPlayer(slot: 1, fullName: 'Nguyen Van A'),
          ParticipantPlayer(slot: 2, fullName: 'Le Van C'),
        ],
      );
      await _pump(tester, doubles);
      expect(find.byKey(const ValueKey('side-lines-player-1')), findsOneWidget);

      final team = _match('t').copyWith(team1Name: 'Sam Set');
      await _pump(tester, team);
      expect(find.text('Sam Set'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('side-lines-team-logo')),
        findsOneWidget,
      );
    });
  });
}
