import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({String status = 'scheduled'}) => MatchModel(
  id: 'm1',
  round: 1,
  matchNumber: 1,
  team1Name: 'Đội A',
  team2Name: 'Đội B',
  divisionId: 'd1',
  status: status,
  bracketPosition: BracketPosition(round: 1, position: 1),
  court: 'Sân 1',
  courtId: 'san-1',
  courtName: 'Sân 1',
  scheduledTime: DateTime(2026, 10, 24, 8),
  durationMinutes: 60,
  updatedAt: DateTime.utc(2026, 1, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required MatchModel match,
  String? gender,
}) async {
  tester.view.physicalSize = const Size(600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScheduleGrid(
            courts: const ['Sân 1'],
            matches: [match],
            startHour: 7,
            endHour: 10,
            onTapMatch: (_) {},
            divisionNameById: const {'d1': 'Đôi nam'},
            divisionMetadataById: {
              'd1': TournamentDivision(
                id: 'd1',
                name: 'Đôi nam',
                matchType: 'DOUBLES',
                genderRestriction: gender,
              ),
            },
          ),
        ),
      ),
    ),
  );
  // A live card pulses forever, so settle with a bounded pump.
  await tester.pump(const Duration(milliseconds: 100));
}

Color _stripeColor(WidgetTester tester) {
  final box = tester.widget<ColoredBox>(
    find.byKey(const ValueKey('schedule-match-stripe-m1')),
  );
  return box.color;
}

void main() {
  testWidgets('MALE division card has a blue stripe', (tester) async {
    await _pump(tester, match: _match(), gender: 'MALE');
    expect(_stripeColor(tester), const Color(0xFF2563EB));
  });

  testWidgets('FEMALE division card has a pink stripe', (tester) async {
    await _pump(tester, match: _match(), gender: 'FEMALE');
    expect(_stripeColor(tester), const Color(0xFFEC4899));
  });

  testWidgets('division without gender restriction is orange', (tester) async {
    await _pump(tester, match: _match());
    expect(_stripeColor(tester), const Color(0xFFEA580C));
  });

  testWidgets('live match shows a blinking dot instead of LIVE text', (
    tester,
  ) async {
    await _pump(
      tester,
      match: _match(status: 'LIVE'),
      gender: 'MALE',
    );
    expect(find.byKey(const ValueKey('schedule-live-dot-m1')), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    // The stripe keeps its gender colour while live.
    expect(_stripeColor(tester), const Color(0xFF2563EB));
  });

  testWidgets('completed match says "Kết thúc" and has no live dot', (
    tester,
  ) async {
    await _pump(
      tester,
      match: _match(status: 'COMPLETED'),
      gender: 'MALE',
    );
    expect(find.text('Kết thúc'), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-live-dot-m1')), findsNothing);
  });
}
