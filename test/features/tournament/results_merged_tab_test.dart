import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_merged_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/tournament_result_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _tid = 'tour-1';
const _did = 'div-1';

class _NoVenues extends Fake implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => const [];
}

MatchModel _match(String id, {required int round, String status = 'COMPLETED'}) {
  return MatchModel(
    id: id,
    tournamentId: _tid,
    round: round,
    matchNumber: 1,
    bracketPosition: BracketPosition(bracket: 'winners', round: round, position: 1),
    stageType: 'SINGLE_ELIMINATION',
    team1Id: 'a',
    team2Id: 'b',
    status: status,
    divisionId: _did,
    team1Name: 'Doi A',
    team2Name: 'Doi B',
    updatedAt: DateTime(2026, 1, 1),
  );
}

final _knockout = [
  _match('r1a', round: 1),
  _match('r1b', round: 1),
  _match('fin', round: 2),
];

const _withAward = {
  'awards': [
    {
      'rank': 1,
      'participant': {'teamName': 'CLB Sài Gòn'},
    },
  ],
};

Finder _row(String id) => find.byKey(ValueKey('results-row-$id'));

Future<void> _pump(
  WidgetTester tester, {
  required Map<String, dynamic> result,
  List<MatchModel>? matches,
  VoidCallback? onShare,
  bool inline = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentResultProvider((
          tournamentId: _tid,
          divisionId: _did,
        )).overrideWith((ref) => Stream.value(result)),
        matchesProvider(
          _tid,
        ).overrideWith((ref) => Stream.value(matches ?? _knockout)),
        tournamentManagementRepositoryProvider.overrideWithValue(_NoVenues()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) {
                final tab = ResultsMergedTab(
                  tournamentId: _tid,
                  isLite: false,
                  canManage: false,
                  divisionId: _did,
                  divisionName: 'Đôi Nam',
                  matchType: 'DOUBLES',
                  onShare: onShare,
                  inline: inline,
                );
                // Inline = placed in a page that already scrolls (accordion row).
                return Scaffold(
                  body: inline ? SingleChildScrollView(child: tab) : tab,
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-MERGED-04 inline: lays out inside a scrolling page', (
    tester,
  ) async {
    await _pump(tester, result: _withAward, inline: true);

    expect(tester.takeException(), isNull);
    expect(find.text('CLB Sài Gòn'), findsOneWidget);
    expect(_row('fin'), findsOneWidget);
  });

  group('TC-MERGED-01 podium above the board', () {
    testWidgets('finished knockout division: podium, then the final only', (
      tester,
    ) async {
      await _pump(tester, result: _withAward);

      expect(find.text('CLB Sài Gòn'), findsOneWidget);
      expect(_row('fin'), findsOneWidget);
      expect(_row('r1a'), findsNothing);
    });

    testWidgets('division not finished: no podium, no empty card, all rounds', (
      tester,
    ) async {
      // Round 1 still waits for a score, so its box starts open.
      await _pump(
        tester,
        result: {'awards': <dynamic>[]},
        matches: [
          _match('r1a', round: 1, status: 'SCHEDULED'),
          _match('fin', round: 2, status: 'SCHEDULED'),
        ],
      );

      expect(find.text('CLB Sài Gòn'), findsNothing);
      expect(find.text('Chưa có kết quả chính thức'), findsNothing);
      expect(find.byKey(const ValueKey('results-share')), findsNothing);
      expect(find.byKey(const ValueKey('results-podium-share')), findsNothing);
      // Without a podium the board keeps every round (round 1 starts open).
      expect(_row('r1a'), findsOneWidget);
    });

    testWidgets('tapping the podium opens the share sheet', (tester) async {
      var shared = 0;
      await _pump(tester, result: _withAward, onShare: () => shared++);

      await tester.tap(find.byKey(const ValueKey('results-podium-share')));

      expect(shared, 1);
    });
  });
}
