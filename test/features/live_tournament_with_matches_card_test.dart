import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/explore/widgets/live_tournament_with_matches_card.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Page = ({List<MatchModel> matches, String? nextCursor});

void main() {
  testWidgets('card shows a match from a later page when page one has none', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _PagedMatchRepository({
      null: (matches: [_placeholderMatch], nextCursor: 'page-2'),
      'page-2': (matches: [_visibleMatch], nextCursor: null),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.pumpAndSettle();

    expect(repository.requests, [null, 'page-2']);
    expect(find.text('Team Alpha'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card hides when no page has a renderable match', (tester) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _PagedMatchRepository({
      null: (matches: [_placeholderMatch], nextCursor: 'page-2'),
      'page-2': (matches: [_placeholderMatch], nextCursor: null),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.pumpAndSettle();

    expect(repository.requests, [null, 'page-2']);
    expect(find.text(_tournament.name.toUpperCase()), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card hides after cursor pages with no renderable match', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _PagedMatchRepository({
      null: (matches: [_placeholderMatch], nextCursor: 'p1'),
      'p1': (matches: [_placeholderMatch], nextCursor: 'p2'),
      'p2': (matches: [_placeholderMatch], nextCursor: 'p3'),
      'p3': (matches: [_placeholderMatch], nextCursor: 'p4'),
      'p4': (matches: [_placeholderMatch], nextCursor: 'p5'),
      'p5': (matches: [_placeholderMatch], nextCursor: 'p6'),
      'p6': (matches: [_visibleMatch], nextCursor: null),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.pumpAndSettle();

    expect(repository.requests, [null, 'p1', 'p2', 'p3', 'p4', 'p5']);
    expect(find.text(_tournament.name.toUpperCase()), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card hides when manual paging lands on an empty page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _PagedMatchRepository({
      null: (matches: [_visibleMatch], nextCursor: 'a'),
      'a': (matches: [_placeholderMatch], nextCursor: 'a'),
    });

    await tester.pumpWidget(_cardApp(repository));
    await tester.pumpAndSettle();

    expect(repository.requests, [null]);
    expect(find.text(_tournament.name.toUpperCase()), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();

    expect(repository.requests, [null, 'a']);
    expect(find.text(_tournament.name.toUpperCase()), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _cardApp(IMatchRepository repository) {
  return ProviderScope(
    overrides: [matchRepositoryProvider.overrideWith((ref) => repository)],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: LiveTournamentWithMatchesCard(tournament: _tournament),
        ),
      ),
    ),
  );
}

final _tournament = Tournament(
  id: 'synthetic-tournament',
  name: 'Synthetic tournament',
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

final _placeholderMatch = _match(
  id: 'placeholder-match',
  team2Id: 'team-tbd-id',
  team2Name: 'TBD',
);

final _visibleMatch = _match(
  id: 'visible-match',
  team2Id: 'team-beta-id',
  team2Name: 'Team Beta',
);

MatchModel _match({
  required String id,
  required String team2Id,
  required String team2Name,
}) {
  return MatchModel(
    id: id,
    tournamentId: _tournament.id,
    round: 1,
    matchNumber: 1,
    team1Id: 'team-alpha-id',
    team2Id: team2Id,
    team1Name: 'Team Alpha',
    team2Name: team2Name,
    status: 'scheduled',
    bracketPosition: const BracketPosition(round: 1, position: 1),
    updatedAt: DateTime.utc(2026, 9, 27),
  );
}

class _PagedMatchRepository extends Fake implements IMatchRepository {
  _PagedMatchRepository(this.pages);

  final Map<String?, _Page> pages;
  final List<String?> requests = [];

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
    requests.add(cursor);
    final page = pages[cursor]!;
    return (
      matches: page.matches,
      nextCursor: page.nextCursor,
      hasMore: page.nextCursor != null,
      total: page.matches.length,
    );
  }
}
