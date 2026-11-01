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
  String bracket = 'winners',
  String? stageType,
  String? groupName,
  int? leg,
}) => MatchModel(
  id: 'm1',
  round: round,
  matchNumber: 3,
  matchCode: matchCode,
  team1Name: 'Nguyễn Văn An',
  team2Name: 'Trần Thị Bình',
  status: status,
  court: court,
  stageType: stageType,
  groupName: groupName,
  leg: leg,
  bracketPosition: BracketPosition(bracket: bracket, round: round, position: 3),
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
Future<void> _pumpRow(
  WidgetTester tester,
  MatchModel match, {
  bool showMatchCode = true,
}) async {
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
        showMatchCode: showMatchCode,
      ),
    ),
  );
}

void main() {
  group('MatchTableRow footer label', () {
    testWidgets('shows round and match code, no overflow', (tester) async {
      await _pumpRow(tester, _match(matchCode: 'DNTB-K1-T3'));

      expect(find.text('Vòng 1/8 - #DNTB-K1-T3'), findsOneWidget);
      expect(find.textContaining('Trận 3'), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets('TC-FEAT-03: shows code on a grand-final row', (tester) async {
      await _pumpRow(
        tester,
        _match(matchCode: 'DNTB-K1-T3', bracket: 'grand_final'),
      );

      expect(find.textContaining('#DNTB-K1-T3'), findsOneWidget);
    });

    testWidgets('TC-FEAT-04: shows code on a group-stage row', (tester) async {
      await _pumpRow(
        tester,
        _match(
          matchCode: 'DNTB-K1-T3',
          stageType: 'ROUND_ROBIN',
          groupName: 'Bảng A',
        ),
      );

      expect(find.text('Bảng A - Lượt 1 - #DNTB-K1-T3'), findsOneWidget);
    });

    testWidgets('keeps "Trận N" when matchCode is missing', (tester) async {
      await _pumpRow(tester, _match());

      expect(find.text('Vòng 1/8 - Trận 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('public surface (showMatchCode off) never shows the code', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        _match(matchCode: 'TK01'),
        showMatchCode: false,
      );

      expect(find.textContaining('TK01'), findsNothing);
      expect(find.text('Vòng 1/8 - Trận 3'), findsOneWidget);
    });
  });

  group('ScheduleGrid footer without a round-label callback', () {
    Future<void> pumpGrid(
      WidgetTester tester,
      MatchModel match, {
      String Function(MatchModel)? roundLabelOf,
    }) async {
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
            roundLabelOf: roundLabelOf,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    MatchModel scheduled({String? matchCode}) => _match(
      matchCode: matchCode,
      status: 'scheduled',
    ).copyWith(scheduledTime: DateTime(2026, 3, 1, 8));

    testWidgets('shows the match code', (tester) async {
      await pumpGrid(tester, scheduled(matchCode: 'DNTB-K1-T3'));

      expect(find.text('#DNTB-K1-T3'), findsOneWidget);
    });
    testWidgets('TC-FEAT-05: appends the code to the supplied round label', (
      tester,
    ) async {
      await pumpGrid(
        tester,
        scheduled(matchCode: 'DNTB-K1-T3'),
        roundLabelOf: (_) => 'Vòng 1/8',
      );

      expect(find.text('Vòng 1/8 - #DNTB-K1-T3'), findsOneWidget);
    });

    testWidgets('keeps "Vòng • Trận N" without a code', (tester) async {
      await pumpGrid(tester, scheduled());

      expect(find.text('Vòng 1 • Trận 3'), findsOneWidget);
    });
  });

  group('MatchRoundLabel', () {
    final vi = lookupAppLocalizations(const Locale('vi'));
    final noRound = _match(round: 0, matchCode: 'DNTB-K1-T3');

    test('uses the match code when there is one', () {
      expect(
        MatchRoundLabel.formatRound(match: noRound, l10n: vi),
        '#DNTB-K1-T3',
      );
    });

    test('keeps "Trận N" without a code', () {
      expect(
        MatchRoundLabel.formatRound(
          match: noRound.copyWith(matchCode: ''),
          l10n: vi,
        ),
        'Trận 3',
      );
    });

    test('TC-FEAT-11: does not duplicate code in short losers fallback', () {
      final label = MatchRoundLabel.formatRound(
        match: _match(
          round: 0,
          matchCode: 'DNTB-K1-T3',
          bracket: 'losers',
        ),
        short: true,
        l10n: vi,
      );

      expect(label, '#DNTB-K1-T3 (NT)');
    });

    test(
      'TC-FEAT-06: appends code to knockout, groups, Swiss, final and generic stage labels',
      () {
        final knockout = MatchRoundLabel.formatRound(
          match: _match(round: 1, matchCode: 'DNTB-K1-T3'),
          bracketSize: 16,
          l10n: vi,
        );
        final group = MatchRoundLabel.formatRound(
          match: _match(
            round: 1,
            matchCode: 'DNTB-K1-T3',
            stageType: 'ROUND_ROBIN',
            groupName: 'A',
          ),
          l10n: vi,
        );
        final swiss = MatchRoundLabel.formatRound(
          match: _match(round: 2, matchCode: 'DNTB-K1-T3', stageType: 'SWISS'),
          l10n: vi,
        );
        final finalLabel = MatchRoundLabel.formatRound(
          match: _match(
            round: 4,
            matchCode: 'DNTB-K1-T3',
            bracket: 'grand_final',
          ),
          l10n: vi,
        );
        final genericGroup = MatchRoundLabel.formatRound(
          match: _match(
            round: 1,
            leg: 2,
            matchCode: 'DNTB-K1-T3',
            stageType: 'ROUND_ROBIN',
          ),
          l10n: vi,
        );

        expect(knockout, '${vi.matchTableRoundOf(8, 16)} - #DNTB-K1-T3');
        expect(
          group,
          '${vi.matchRoundGroupLeg(vi.matchRoundGroupPrefix('A'), 1)} - #DNTB-K1-T3',
        );
        expect(swiss, '${vi.swissRoundLabel(2)} - #DNTB-K1-T3');
        expect(finalLabel, '${vi.matchRoundGrandFinal} - #DNTB-K1-T3');
        expect(
          genericGroup,
          '${vi.crossTableLegTitle(2, vi.bracketView_groupStage)} - #DNTB-K1-T3',
        );
      },
    );
  });
}
