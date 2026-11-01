import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/widgets/skeleton/list_skeletons.dart';
import 'package:app_quanly_giaidau/domain/entities/match.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/match/screens/matches_list_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Page = ({List<MatchModel> matches, String? nextCursor});

void main() {
  testWidgets('opening asks for one first page and shows row skeletons first', (
    tester,
  ) async {
    _phone(tester);
    final gate = Completer<void>();
    final repo = _Repository({
      null: (matches: [_match('m1')], nextCursor: null),
    })..gate = gate;

    await tester.pumpWidget(_app(repo));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(MatchRowSkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Search and filters stay real while the list loads.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Ongoing'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();

    expect(repo.calls.length, 1);
    expect(repo.calls.single.cursor, isNull);
    expect(repo.calls.single.limit, 20);
    expect(find.byType(MatchRowSkeleton), findsNothing);
    expect(find.text('Team A m1'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('scrolling near the end requests the next page by cursor once', (
    tester,
  ) async {
    _phone(tester);
    final repo = _Repository({
      null: (
        matches: [for (var i = 0; i < 12; i++) _match('a$i', tournament: 'T$i')],
        nextCursor: 'c2',
      ),
      'c2': (matches: [_match('b0', tournament: 'Tz')], nextCursor: null),
    });

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    expect(repo.calls.map((c) => c.cursor), [null]);

    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -2500));
      await tester.pumpAndSettle();
    }

    expect(repo.calls.map((c) => c.cursor), [null, 'c2']);
    await _dispose(tester);
  });

  testWidgets('"Ended" filters on the server as COMPLETED and returns results', (
    tester,
  ) async {
    _phone(tester);
    final repo = _Repository({
      null: (matches: [_match('open')], nextCursor: null),
    })..byStatus['COMPLETED'] = [_match('done', status: 'completed')];

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ended'));
    await tester.pumpAndSettle();

    expect(repo.calls.last.status, 'COMPLETED');
    expect(find.text('Team A done'), findsOneWidget);
    expect(find.text('Team A open'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('there is no dead "Open registration" pill', (tester) async {
    _phone(tester);
    final repo = _Repository({null: (matches: [_match('m1')], nextCursor: null)});

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Open registration'), findsNothing);
    expect(find.text('Just ended'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('a first-load failure offers retry, and retry loads the list', (
    tester,
  ) async {
    _phone(tester);
    final repo = _Repository({null: (matches: [_match('m1')], nextCursor: null)})
      ..failing = true;

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(MatchRowSkeleton), findsNothing);

    repo.failing = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Team A m1'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('a failed refresh keeps the list that is already shown', (
    tester,
  ) async {
    _phone(tester);
    final repo = _Repository({null: (matches: [_match('m1')], nextCursor: null)});

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Team A m1'), findsOneWidget);

    repo.failing = true;
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Team A m1'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('no matches after loading shows the empty message', (tester) async {
    _phone(tester);
    final repo = _Repository({null: (matches: <MatchModel>[], nextCursor: null)});

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('Try changing the filter or search terms'), findsOneWidget);
    expect(find.byType(MatchRowSkeleton), findsNothing);
    await _dispose(tester);
  });
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Unmounting disposes the ProviderScope and the screen's timer.
Future<void> _dispose(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

Widget _app(_Repository repo) => ProviderScope(
  overrides: [
    matchRepositoryProvider.overrideWithValue(repo),
    categoriesProvider.overrideWith((ref) => Future.value(const [])),
  ],
  child: MaterialApp(
    theme: AppTheme.darkTheme,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const MatchesListScreen(),
  ),
);

MatchModel _match(
  String id, {
  String status = 'scheduled',
  String tournament = 'Cup',
}) => MatchModel(
  id: id,
  tournamentId: 't-$tournament',
  tournamentName: tournament,
  round: 1,
  matchNumber: 1,
  team1Id: 'a-$id',
  team2Id: 'b-$id',
  team1Name: 'Team A $id',
  team2Name: 'Team B $id',
  status: status,
  bracketPosition: const BracketPosition(round: 1, position: 1),
  updatedAt: DateTime.utc(2026, 11, 1),
);

class _Call {
  final String? cursor;
  final String? status;
  final int limit;

  _Call(this.cursor, this.status, this.limit);
}

/// Only `getPublicMatchesPaged` exists: the old full `getMatches` read throws.
class _Repository extends Fake implements IMatchRepository {
  _Repository(this.pages);

  final Map<String?, _Page> pages;
  final byStatus = <String, List<MatchModel>>{};
  final calls = <_Call>[];
  Completer<void>? gate;
  var failing = false;

  @override
  Future<
    ({List<MatchModel> matches, String? nextCursor, bool hasMore, int total})
  >
  getPublicMatchesPaged({
    String? cursor,
    int limit = 10,
    String? search,
    String? categoryId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? trigger,
  }) async {
    calls.add(_Call(cursor, status, limit));
    await gate?.future;
    if (failing) throw StateError('boom');
    final filtered = status == null ? null : byStatus[status];
    final page = filtered != null
        ? (matches: filtered, nextCursor: null)
        : pages[cursor]!;
    return (
      matches: page.matches,
      nextCursor: page.nextCursor,
      hasMore: page.nextCursor != null,
      total: page.matches.length,
    );
  }
}
