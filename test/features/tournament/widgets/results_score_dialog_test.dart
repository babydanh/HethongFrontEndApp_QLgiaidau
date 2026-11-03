import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/domain/services/sport_rule_service.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_score_dialog.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _Call {
  _Call(this.matchId, this.p1, this.p2, this.sets, this.winnerId);
  final String matchId;
  final int p1;
  final int p2;
  final List<SetScoreData> sets;
  final String? winnerId;
}

class _FakeMatches extends Fake implements IMatchRepository {
  final calls = <_Call>[];
  Completer<void>? gate;
  Object? failWith;

  @override
  Future<void> updateScoreDetails(
    String tournamentId,
    String matchId, {
    required int p1SetsWon,
    required int p2SetsWon,
    required List<SetScoreData> scoreDetails,
    Map<String, dynamic>? scoreDetailsExtras,
    String? winnerId,
    String? overrideReason,
    int? expectedRevision,
    bool useLiteParticipantAccess = false,
  }) async {
    calls.add(_Call(matchId, p1SetsWon, p2SetsWon, scoreDetails, winnerId));
    await gate?.future;
    if (failWith != null) throw failWith!;
  }
}

MatchModel _match() => MatchModel(
  id: 'm1',
  round: 1,
  matchNumber: 1,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  team1Id: 'a',
  team2Id: 'b',
  status: 'SCHEDULED',
  courtName: 'Sân 2',
  refereeName: 'Hoang Nam',
  scheduledTime: DateTime(2026, 11, 3, 14, 0),
  team1Players: [
    ParticipantPlayer(slot: 1, fullName: 'Nguyen Van A'),
    ParticipantPlayer(slot: 2, fullName: 'Le Van C'),
  ],
  team2Players: [ParticipantPlayer(slot: 1, fullName: 'Tran Thi B')],
  updatedAt: DateTime(2026, 1, 1),
);

Future<_FakeMatches> _pump(WidgetTester tester) async {
  final repo = _FakeMatches();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [matchRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showResultsScoreDialog(
                      context,
                      match: _match(),
                      tournamentId: 't1',
                      label: '#V1',
                      liveRoute: '/live/m1',
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/live/:id',
              builder: (_, _) => const Scaffold(body: Text('live-room')),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

Finder _input(int side, int set) =>
    find.byKey(ValueKey('results-score-input-$side-$set'));

Future<void> _type(WidgetTester tester, List<(int, int)> sets) async {
  for (final (i, (a, b)) in sets.indexed) {
    await tester.enterText(_input(1, i), '$a');
    await tester.enterText(_input(2, i), '$b');
  }
  await tester.pump();
}

Finder get _save => find.byKey(const ValueKey('results-score-save'));

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_save).onPressed != null;

void main() {
  testWidgets('TC-RBR-40 shows both sides, time, court, referee, 3 sets', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Nhập điểm #V1'), findsOneWidget);
    expect(find.byKey(const ValueKey('side-lines-player-1')), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
    expect(find.text('Sân 2'), findsOneWidget);
    expect(find.text('TT: Hoang Nam'), findsOneWidget);
    expect(find.text('Set 3'), findsOneWidget);
    expect(find.text('Set 4'), findsNothing);
    expect(_saveEnabled(tester), isFalse);
  });

  testWidgets('TC-RBR-41 saves the sets and the winner, then closes', (
    tester,
  ) async {
    final repo = await _pump(tester);
    await _type(tester, [(21, 18), (21, 15)]);
    expect(_saveEnabled(tester), isTrue);

    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(repo.calls, hasLength(1));
    final call = repo.calls.single;
    expect((call.matchId, call.p1, call.p2), ('m1', 2, 0));
    expect(call.winnerId, 'a');
    expect(call.sets.map((s) => (s.score1, s.score2)), [(21, 18), (21, 15)]);
    expect(find.byKey(const ValueKey('results-score-save')), findsNothing);
  });

  testWidgets('TC-RBR-42 equal sets won keep Save disabled and say why', (
    tester,
  ) async {
    await _pump(tester);
    await _type(tester, [(21, 18), (18, 21)]);
    expect(_saveEnabled(tester), isFalse);
    expect(find.byKey(const ValueKey('results-score-tied')), findsOneWidget);
  });

  testWidgets('TC-RBR-43 a failed save keeps the popup, shows the error', (
    tester,
  ) async {
    final repo = await _pump(tester);
    repo.failWith = Exception('Mất kết nối');
    await _type(tester, [(21, 18)]);
    await tester.tap(_save);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('results-score-error')), findsOneWidget);
    expect(find.text('Mất kết nối'), findsOneWidget);
    expect(_saveEnabled(tester), isTrue);
  });

  testWidgets('TC-RBR-44 a double tap sends one request', (tester) async {
    final repo = await _pump(tester);
    repo.gate = Completer<void>();
    await _type(tester, [(21, 18)]);
    await tester.tap(_save);
    await tester.pump();
    expect(_saveEnabled(tester), isFalse);
    await tester.tap(_save, warnIfMissed: false);
    await tester.pump();
    expect(repo.calls, hasLength(1));

    repo.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('TC-RBR-45 "Thêm set" adds a column', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('results-score-add-set')));
    await tester.pumpAndSettle();
    expect(find.text('Set 4'), findsOneWidget);
    expect(_input(1, 3), findsOneWidget);
  });

  testWidgets('TC-RBR-46 "Vào trang Live" closes the popup and opens live', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('results-score-live')));
    await tester.pumpAndSettle();
    expect(find.text('live-room'), findsOneWidget);
  });
}
