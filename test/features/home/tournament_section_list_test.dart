import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/home/widgets/tournament_section_list.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _tournamentCount = 14;
const _firstPage = 6;

void main() {
  testWidgets(
    'TC-HOMEFEED-03 first frame scans only the first page of tournaments',
    (tester) async {
      final requested = <String>[];

      await tester.pumpWidget(_app(requested, withMatches: false));

      // Watching every tournament at once is what made the tab fire a request
      // storm the moment it opened.
      expect(requested.toSet(), {for (var i = 0; i < _firstPage; i++) 't$i'});
    },
  );

  testWidgets('TC-HOMEFEED-04 keeps scanning while no tournament has a match', (
    tester,
  ) async {
    final requested = <String>[];

    await tester.pumpWidget(_app(requested, withMatches: false));
    await tester.pumpAndSettle();

    // An empty tab must not stall at page one: nothing is on screen to scroll.
    expect(requested.toSet().length, _tournamentCount);
  });

  testWidgets(
    'TC-HOMEFEED-05 loads the next page only when scrolled near the end',
    (tester) async {
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final requested = <String>[];

      await tester.pumpWidget(_app(requested, withMatches: true));
      await tester.pumpAndSettle();

      expect(
        requested.toSet().length,
        lessThan(_tournamentCount),
        reason: 'a full screen of cards must not pull every tournament',
      );

      for (var i = 0; i < 12; i++) {
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
      }

      expect(requested.toSet().length, _tournamentCount);
    },
  );
}

Widget _app(List<String> requested, {required bool withMatches}) {
  return ProviderScope(
    overrides: [
      matchRepositoryProvider.overrideWith((ref) => _PagedRepository()),
      matchesProvider.overrideWith((ref, tournamentId) {
        requested.add(tournamentId);
        return Stream.value(withMatches ? [_match(tournamentId)] : const []);
      }),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            TournamentSectionList(
              tournaments: [
                for (var i = 0; i < _tournamentCount; i++) _tournament('t$i'),
              ],
              filterStatus: 'scheduled',
              emptyMessage: 'empty',
            ),
          ],
        ),
      ),
    ),
  );
}

Tournament _tournament(String id) => Tournament(
  id: id,
  name: 'Tournament $id',
  sport: 'pickleball',
  format: 'single_elimination',
  bracketType: 'SINGLE_ELIMINATION',
  status: 'registration',
  adminToken: '',
  refereeToken: '',
  viewerToken: '',
  creatorId: 'synthetic-user',
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
  startDate: DateTime.utc(2026, 10, 1),
);

MatchModel _match(String tournamentId) => MatchModel(
  id: 'match-$tournamentId',
  tournamentId: tournamentId,
  round: 1,
  matchNumber: 1,
  team1Id: 'team-alpha-id',
  team2Id: 'team-beta-id',
  team1Name: 'Team Alpha',
  team2Name: 'Team Beta',
  status: 'scheduled',
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 9, 27),
);

/// Each card pages its own matches through the repository; one empty page is
/// enough because the section list only needs the card to mount.
class _PagedRepository extends Fake implements IMatchRepository {
  @override
  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getTournamentMatchesPaged({
    required String tournamentId,
    String? status,
    String? cursor,
    int limit = 4,
    String? trigger,
  }) async {
    return (
      matches: [_match(tournamentId)],
      nextCursor: null,
      hasMore: false,
      total: 1,
    );
  }
}
