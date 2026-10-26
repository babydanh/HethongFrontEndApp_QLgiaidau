import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/utils/match_round_label.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/match_table_row.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({
  String? matchCode,
  int round = 1,
  String status = 'completed',
  String court = 'Sân 1',
}) => MatchModel(
  id: 'm1',
  round: round,
  matchNumber: 3,
  matchCode: matchCode,
  team1Name: 'Nguyễn Văn An',
  team2Name: 'Trần Thị Bình',
  status: status,
  court: court,
  bracketPosition: BracketPosition(round: round, position: 3),
  updatedAt: DateTime.utc(2026, 1, 1),
);

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  theme: AppTheme.lightTheme,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

// Wide view on purpose: the test font (Ahem) is far wider than the real one,
// so a phone-width pump overflows even without a match code.
Future<void> _pumpRow(WidgetTester tester, MatchModel match) async {
  tester.view.physicalSize = const Size(1200, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    _host(
      MatchTableRow(
        match: match,
        isReadOnly: true,
        totalRounds: 4,
        tournamentId: 't-1',
      ),
    ),
  );
}

void main() {
  group('MatchTableRow footer label', () {
    testWidgets('shows round and match code, no overflow', (
      tester,
    ) async {
      await _pumpRow(tester, _match(matchCode: 'DN12W10T12'));

      expect(find.text('Vòng 1/8 - DN12W10T12VATB'), findsOneWidget);
      expect(find.textContaining('Trận 3'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps "Trận N" when matchCode is missing', (tester) async {
      await _pumpRow(tester, _match());

      expect(find.text('Vòng 1/8 - Trận 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ScheduleGrid footer without a round-label callback', () {
    Future<void> pumpGrid(WidgetTester tester, MatchModel match) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _host(
          ScheduleGrid(
            courts: const ['Sân 1'],
            matches: [match],
            startHour: 7,
            endHour: 12,
            day: DateTime(2026, 3, 1),
            onTapMatch: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    MatchModel scheduled({String? matchCode}) =>
        _match(matchCode: matchCode, status: 'scheduled').copyWith(
          scheduledTime: DateTime(2026, 3, 1, 8),
        );

    testWidgets('shows the match code', (tester) async {
      await pumpGrid(tester, scheduled(matchCode: 'DN1W2T3'));

      expect(find.text('DN1W2T3VATB'), findsOneWidget);
    });

    testWidgets('keeps "Vòng • Trận N" without a code', (tester) async {
      await pumpGrid(tester, scheduled());

      expect(find.text('Vòng 1 • Trận 3'), findsOneWidget);
    });
  });

  group('MatchRoundLabel generic fallback', () {
    final vi = lookupAppLocalizations(const Locale('vi'));
    final noRound = _match(round: 0, matchCode: 'DN1W2T3');

    test('uses the match code when there is one', () {
      expect(MatchRoundLabel.formatRound(match: noRound, l10n: vi), 'DN1W2T3VATB');
    });

    test('keeps "Trận N" without a code', () {
      expect(
        MatchRoundLabel.formatRound(match: noRound.copyWith(matchCode: ''), l10n: vi),
        'Trận 3',
      );
    });
  });
}
