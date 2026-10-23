import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/bracket_view_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ITournamentRepository {}

MatchModel _match(
  String id,
  int round, {
  String status = 'SCHEDULED',
  bool isBye = false,
}) => MatchModel(
  id: id,
  round: round,
  matchNumber: round,
  status: status,
  isBye: isBye,
  bracketPosition: BracketPosition(round: round, position: 0),
  updatedAt: DateTime.utc(2026, 10, 22),
);

late _MockRepo _repo;
(String, int, int)? _opened;

Widget _host(List<MatchModel> matches, {int totalRounds = 5}) => ProviderScope(
  overrides: [tournamentRepositoryProvider.overrideWithValue(_repo)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    // Plain theme + InkRipple: AppTheme needs google_fonts/shader assets.
    theme: ThemeData.light().copyWith(splashFactory: InkRipple.splashFactory),
    home: Scaffold(
      body: SwissRoundActions(
        tournamentId: 't1',
        divisionId: 'd1',
        stageId: 's1',
        matches: matches,
        totalRounds: totalRounds,
        onOpenPairing: (stage, round, total) => _opened = (stage, round, total),
      ),
    ),
  ),
);

void main() {
  setUp(() {
    _repo = _MockRepo();
    _opened = null;
  });

  testWidgets('round done and rounds left: "Ghép cặp vòng 3" opens pairing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host([
        _match('a', 1, status: 'COMPLETED'),
        _match('b', 2, status: 'COMPLETED'),
        _match('c', 2, status: 'COMPLETED'),
        _match('bye', 2, status: 'COMPLETED', isBye: true),
      ]),
    );

    expect(find.byKey(const Key('swiss-next-round')), findsOneWidget);
    expect(find.text('Ghép cặp vòng 3'), findsOneWidget);
    expect(find.byKey(const Key('swiss-undo-round')), findsNothing);

    await tester.tap(find.byKey(const Key('swiss-next-round')));
    expect(_opened, ('s1', 3, 5));
  });

  testWidgets('round still running: status line, no button', (tester) async {
    await tester.pumpWidget(
      _host([
        _match('a', 1, status: 'COMPLETED'),
        _match('b', 2, status: 'COMPLETED'),
        _match('c', 2, status: 'LIVE'),
      ]),
    );

    expect(find.text('Vòng 2 đang đấu'), findsOneWidget);
    expect(find.byKey(const Key('swiss-next-round')), findsNothing);
    expect(find.byKey(const Key('swiss-undo-round')), findsNothing);
  });

  testWidgets('all rounds played: "Đã đủ 5 vòng"', (tester) async {
    await tester.pumpWidget(
      _host([
        _match('a', 4, status: 'COMPLETED'),
        _match('b', 5, status: 'COMPLETED'),
      ]),
    );

    expect(find.text('Đã đủ 5 vòng'), findsOneWidget);
    expect(find.byKey(const Key('swiss-next-round')), findsNothing);
  });

  testWidgets('newest round untouched: undo button is offered', (tester) async {
    await tester.pumpWidget(
      _host([
        _match('a', 1, status: 'COMPLETED'),
        _match('b', 2, status: 'COMPLETED'),
        _match('c', 3),
        _match('d', 3),
        _match('bye', 3, status: 'COMPLETED', isBye: true),
      ]),
    );

    expect(find.byKey(const Key('swiss-undo-round')), findsOneWidget);
    expect(find.text('Hoàn tác vòng 3'), findsOneWidget);
    expect(find.text('Vòng 3 đang đấu'), findsOneWidget);
  });

  testWidgets('no undo for round 1', (tester) async {
    await tester.pumpWidget(_host([_match('a', 1), _match('b', 1)]));

    expect(find.byKey(const Key('swiss-undo-round')), findsNothing);
  });

  testWidgets('undo asks first, then calls the API and reports success', (
    tester,
  ) async {
    when(
      () => _repo.swissUndoRound(
        any(),
        any(),
        divisionId: any(named: 'divisionId'),
        stageId: any(named: 'stageId'),
      ),
    ).thenAnswer((_) async => 3);
    await tester.pumpWidget(
      _host([
        _match('a', 1, status: 'COMPLETED'),
        _match('b', 2, status: 'COMPLETED'),
        _match('c', 3),
      ]),
    );

    await tester.tap(find.byKey(const Key('swiss-undo-round')));
    await tester.pumpAndSettle();
    verifyNever(
      () => _repo.swissUndoRound(
        any(),
        any(),
        divisionId: any(named: 'divisionId'),
        stageId: any(named: 'stageId'),
      ),
    );

    await tester.tap(find.byKey(const Key('swiss-undo-round-confirm')));
    await tester.pumpAndSettle();

    verify(
      () => _repo.swissUndoRound('t1', 3, divisionId: 'd1', stageId: 's1'),
    ).called(1);
    expect(find.text('Đã hoàn tác vòng 3.'), findsOneWidget);
  });

  testWidgets('undo rejected by the server shows the coded error', (
    tester,
  ) async {
    when(
      () => _repo.swissUndoRound(
        any(),
        any(),
        divisionId: any(named: 'divisionId'),
        stageId: any(named: 'stageId'),
      ),
    ).thenThrow(
      const SwissApiException(status: 409, code: 'SWISS_ROUND_STARTED'),
    );
    await tester.pumpWidget(
      _host([_match('b', 2, status: 'COMPLETED'), _match('c', 3)]),
    );

    await tester.tap(find.byKey(const Key('swiss-undo-round')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swiss-undo-round-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.text('Không thể hoàn tác vì vòng này đã bắt đầu'),
      findsOneWidget,
    );
  });

  testWidgets('no matches yet: nothing is shown', (tester) async {
    await tester.pumpWidget(_host(const []));

    expect(find.byType(TextButton), findsNothing);
    expect(find.byKey(const Key('swiss-round-status')), findsNothing);
  });
}
