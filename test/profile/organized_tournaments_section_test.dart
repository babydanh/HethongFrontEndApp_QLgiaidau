// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_workspace.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/profile/widgets/organized_tournaments_section.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String id) => {
  'id': id,
  'name': 'Giai $id',
  'status': 'REGISTRATION_OPEN',
};

TournamentWorkspace _page(List<String> ids, {String? next}) =>
    TournamentWorkspace.fromJson({
      'organizedTournaments': [for (final id in ids) _json(id)],
      'meta': {'nextCursor': next, 'hasMore': next != null},
    });

/// Serves scripted pages and records every call so tests can assert the
/// cursor/limit/role the section sends.
class _FakeRepo implements ITournamentRepository {
  _FakeRepo(this.pages);

  final List<Future<TournamentWorkspace> Function()> pages;
  final calls = <Map<String, Object?>>[];

  @override
  Future<TournamentWorkspace> getMyWorkspace({
    String? cursor,
    int limit = 20,
    String? role,
  }) {
    calls.add({'cursor': cursor, 'limit': limit, 'role': role});
    return pages[calls.length - 1]();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tournamentRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrganizedTournamentsSection(
              rowBuilder: (t) => ListTile(
                key: ValueKey('org-row-${t.id}'),
                title: Text(t.name),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _loadMore = find.byKey(const ValueKey('profile-org-load-more'));

void main() {
  testWidgets('TC-PROFILE-ORG-01: shows the first 4 and asks backend for role=ORGANIZER limit=4', (
    tester,
  ) async {
    final repo = _FakeRepo([
      () async => _page(['a', 'b', 'c', 'd'], next: 'c1'),
    ]);
    await _pump(tester, repo);

    expect(find.byKey(const ValueKey('org-row-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('org-row-d')), findsOneWidget);
    expect(_loadMore, findsOneWidget);
    expect(repo.calls.single, {'cursor': null, 'limit': 4, 'role': 'ORGANIZER'});
  });

  testWidgets('TC-PROFILE-ORG-02: Xem thêm appends page 2 with the cursor, then hides when exhausted', (
    tester,
  ) async {
    final repo = _FakeRepo([
      () async => _page(['a', 'b', 'c', 'd'], next: 'c1'),
      () async => _page(['e', 'f']),
    ]);
    await _pump(tester, repo);

    await tester.tap(_loadMore);
    await tester.pumpAndSettle();

    expect(repo.calls[1]['cursor'], 'c1');
    expect(find.byKey(const ValueKey('org-row-f')), findsOneWidget);
    expect(find.byKey(const ValueKey('org-row-a')), findsOneWidget);
    expect(_loadMore, findsNothing);
  });

  testWidgets('TC-PROFILE-ORG-03: a single short page shows no Xem thêm', (tester) async {
    final repo = _FakeRepo([() async => _page(['a', 'b'])]);
    await _pump(tester, repo);

    expect(find.byKey(const ValueKey('org-row-b')), findsOneWidget);
    expect(_loadMore, findsNothing);
  });

  testWidgets('TC-PROFILE-ORG-04: a double tap while loading fires one request', (tester) async {
    final gate = Completer<TournamentWorkspace>();
    final repo = _FakeRepo([
      () async => _page(['a', 'b', 'c', 'd'], next: 'c1'),
      () => gate.future,
    ]);
    await _pump(tester, repo);

    await tester.tap(_loadMore);
    await tester.pump();
    await tester.tap(_loadMore, warnIfMissed: false);
    await tester.pump();
    expect(repo.calls.length, 2);

    gate.complete(_page(['e']));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('org-row-e')), findsOneWidget);
  });

  testWidgets('TC-PROFILE-ORG-05: a failed next page keeps rows and offers retry that succeeds', (
    tester,
  ) async {
    final repo = _FakeRepo([
      () async => _page(['a', 'b', 'c', 'd'], next: 'c1'),
      () async => throw Exception('offline'),
      () async => _page(['e']),
    ]);
    await _pump(tester, repo);

    await tester.tap(_loadMore);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('org-row-a')), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    await tester.tap(_loadMore);
    await tester.pumpAndSettle();
    expect(repo.calls[2]['cursor'], 'c1');
    expect(find.byKey(const ValueKey('org-row-e')), findsOneWidget);
    expect(_loadMore, findsNothing);
  });

  testWidgets('TC-PROFILE-ORG-06: no organized tournaments renders nothing', (tester) async {
    final repo = _FakeRepo([() async => _page([])]);
    await _pump(tester, repo);

    expect(find.text('GIẢI TÔI TỔ CHỨC'), findsNothing);
    expect(_loadMore, findsNothing);
  });
}
