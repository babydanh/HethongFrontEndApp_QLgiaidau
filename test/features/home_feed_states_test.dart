import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/domain/entities/region.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/region_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/home/screens/home_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home match section keeps loading state visible', (tester) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    final matches = StreamController<List<MatchModel>>();
    addTearDown(matches.close);

    await tester.pumpWidget(_homeApp((ref, tournamentId) => matches.stream));
    await tester.pump();

    expect(find.text('Live Matches'), findsOneWidget);
    expect(find.text('Loading match data...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('home match error stays visible and retry refetches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    var requests = 0;

    await tester.pumpWidget(
      _homeApp((ref, tournamentId) {
        requests++;
        return Stream<List<MatchModel>>.error(StateError('synthetic failure'));
      }),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming Matches'), findsOneWidget);
    expect(
      find.text('Unable to load match data. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(requests, greaterThan(1));
    expect(
      find.text('Unable to load match data. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('home match section explains a successful empty result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      _homeApp((ref, tournamentId) => Stream.value(const <MatchModel>[])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming Matches'), findsOneWidget);
    expect(find.text('No upcoming matches'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets('home keeps a successful scheduled match visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    final match = MatchModel(
      id: 'synthetic-match',
      tournamentId: _tournament.id,
      round: 1,
      matchNumber: 1,
      team1Name: 'Team Alpha',
      team2Name: 'Team Beta',
      status: 'scheduled',
      bracketPosition: const BracketPosition(round: 1, position: 1),
      updatedAt: DateTime.utc(2026, 9, 27),
    );

    await tester.pumpWidget(
      _homeApp(
        (ref, tournamentId) => Stream.value([match]),
        cardMatches: [match],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Team Alpha'), findsOneWidget);
    expect(find.text('Team Beta'), findsOneWidget);
    expect(find.text('Upcoming Matches'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _homeApp(
  Stream<List<MatchModel>> Function(Ref ref, String tournamentId) matches, {
  List<MatchModel> cardMatches = const [],
}) {
  return ProviderScope(
    overrides: [
      matchRepositoryProvider.overrideWith(
        (ref) => _FakeMatchRepository(cardMatches),
      ),
      authProvider.overrideWith(_PreviewAuthNotifier.new),
      tournamentsProvider.overrideWith((ref) => Stream.value([_tournament])),
      matchesProvider.overrideWith(matches),
      categoriesProvider.overrideWith(
        (ref) => Future.value([
          CategoryModel(
            id: 'sport-1',
            name: 'Pickleball',
            slug: 'pickleball',
            description: '',
            isActive: true,
          ),
        ]),
      ),
      communityDetailProvider.overrideWith((ref, id) async => _community),
      liveMatchesProvider.overrideWith(
        (ref) => Future.value(const <MatchModel>[]),
      ),
      unreadCountProvider.overrideWith((ref) => Future.value(0)),
      regionRepositoryProvider.overrideWith((ref) => _FakeRegionRepository()),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(initialTab: 0),
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

final _community = Community(id: 'synthetic-club', name: 'Synthetic club');

class _FakeMatchRepository extends Fake implements IMatchRepository {
  _FakeMatchRepository(this.matches);

  final List<MatchModel> matches;

  @override
  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getTournamentMatchesPaged({
    required String tournamentId,
    String? status,
    String? cursor,
    int limit = 4,
  }) async => (
    matches: matches,
    nextCursor: null,
    hasMore: false,
    total: matches.length,
  );
}

class _FakeRegionRepository implements IRegionRepository {
  @override
  Future<List<Region>> getProvinces() async => const [];

  @override
  Future<List<Region>> getWardsByProvince(String provinceCode) async =>
      const [];
}

class _PreviewAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    status: AuthStatus.authenticated,
    role: UserRole.viewer,
    tokenCode: 'synthetic-token',
  );

  @override
  Future<void> init() async {}
}
