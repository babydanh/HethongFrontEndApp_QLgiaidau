import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/organizer_ops.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_management_athletes_tab.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/shared/widgets/search_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

OrganizerOpsParticipant _p(
  String id,
  String name,
  String status,
  bool paid,
  String division,
) => OrganizerOpsParticipant(
  id: id,
  teamName: name,
  teamStatus: status,
  isPaid: paid,
  members: [OrganizerOpsMember(userId: 'u-$id', fullName: name)],
  divisionId: division,
);

final _participants = [
  _p('p1', 'Nguyễn An', 'COMPLETE', true, 'd1'),
  _p('p2', 'Trần Bình', 'PENDING_APPROVAL', false, 'd1'),
  _p('p3', 'Lê Cường', 'COMPLETE', false, 'd2'),
  _p('p4', 'Phạm Dũng', 'REJECTED', true, 'd2'),
];

class _Repository implements ITournamentRepository {
  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) async => _participants;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Repository whose list stays pending until the test completes it: the same
/// state the tab shows while a reload (add, import, pairing) is running.
class _SlowRepository implements ITournamentRepository {
  _SlowRepository(this.completer);

  final Completer<List<OrganizerOpsParticipant>> completer;

  @override
  Future<List<OrganizerOpsParticipant>> getOrganizerParticipants(
    String tournamentId, {
    String? divisionId,
  }) => completer.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _tournament = Tournament.fromJson({
  'name': 'Cup',
  'sport': 'pickleball',
  'format': 'doubles',
  'bracketType': 'single_elimination',
  'status': 'in_progress',
  'maxTeams': 8,
  'maxPlayersPerTeam': 2,
  'divisions': [
    {'id': 'd1', 'name': 'Đôi nam', 'matchType': 'SINGLES'},
    {'id': 'd2', 'name': 'Đôi nữ', 'matchType': 'SINGLES'},
  ],
  'createdAt': '2026-01-01T00:00:00Z',
  'updatedAt': '2026-01-01T00:00:00Z',
}, 'tournament-1');

const _key = 'tournament-1:athletes';
final _row1 = find.byKey(const ValueKey('athlete-division-row-d1'));
final _row2 = find.byKey(const ValueKey('athlete-division-row-d2'));

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  double width = 390,
  ITournamentRepository? repository,
  bool settle = true,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentRepositoryProvider.overrideWithValue(
          repository ?? _Repository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TournamentManagementAthletesTab(tournament: _tournament),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
}

void main() {
  testWidgets('search icon opens the bar with approval and fee filters', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('search-filter-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('search-filter-input')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('search-filter-group-approval')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('search-filter-group-fee')),
      findsOneWidget,
    );
    expect(find.text('4 kết quả'), findsOneWidget);
    expect(_row1, findsOneWidget);
    expect(_row2, findsOneWidget);
  });

  testWidgets('name search ignores accents and hides divisions with no hit', (
    tester,
  ) async {
    final container = await _pump(tester);
    container.read(searchFilterProvider(_key).notifier)
      ..setQuery('nguyen')
      ..setOpen(true);
    await tester.pumpAndSettle();
    expect(_row1, findsOneWidget);
    expect(_row2, findsNothing);
    expect(find.text('1 kết quả'), findsOneWidget);
  });

  testWidgets('fee and approval filters combine', (tester) async {
    final container = await _pump(tester);
    final notifier = container.read(searchFilterProvider(_key).notifier);
    notifier.setFilter('fee', 'unpaid');
    await tester.pumpAndSettle();
    expect(_row1, findsOneWidget);
    expect(_row2, findsOneWidget);

    notifier.setFilter('approval', 'approved');
    await tester.pumpAndSettle();
    expect(_row1, findsNothing);
    expect(_row2, findsOneWidget);
  });

  testWidgets('an opened division lists only the matching people', (
    tester,
  ) async {
    final container = await _pump(tester);
    container.read(searchFilterProvider(_key).notifier).setQuery('tran');
    await tester.pumpAndSettle();
    await tester.tap(_row1);
    await tester.pumpAndSettle();
    expect(find.textContaining('Trần Bình'), findsWidgets);
    expect(find.textContaining('Nguyễn An'), findsNothing);
  });

  testWidgets('no match shows 0 results and clear brings every row back', (
    tester,
  ) async {
    final container = await _pump(tester);
    container.read(searchFilterProvider(_key).notifier)
      ..setQuery('zzzz')
      ..setOpen(true);
    await tester.pumpAndSettle();
    expect(find.text('0 kết quả'), findsOneWidget);
    expect(_row1, findsNothing);

    await tester.tap(find.byKey(const ValueKey('search-filter-clear-all')));
    await tester.pumpAndSettle();
    expect(_row1, findsOneWidget);
    expect(_row2, findsOneWidget);
  });

  testWidgets('no overflow at 320dp with filters on', (tester) async {
    final container = await _pump(tester, width: 320);
    container.read(searchFilterProvider(_key).notifier)
      ..setQuery('nguyen')
      ..setFilter('approval', 'approved')
      ..setFilter('fee', 'paid')
      ..setOpen(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('toolbar and bar survive the list loading and reloading', (
    tester,
  ) async {
    final completer = Completer<List<OrganizerOpsParticipant>>();
    await _pump(tester, repository: _SlowRepository(completer), settle: false);
    const toggle = ValueKey('search-filter-toggle');
    const input = ValueKey('search-filter-input');
    // The list is still loading but the toolbar is already there.
    expect(find.byKey(toggle), findsOneWidget);
    await tester.tap(find.byKey(toggle));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byKey(input), 'nguyen');
    await tester.pump(const Duration(milliseconds: 300));
    final before = tester.widget<TextField>(find.byKey(input)).focusNode;
    expect(before?.hasFocus, isTrue);
    before?.unfocus();
    await tester.pump();

    completer.complete(_participants);
    await tester.pumpAndSettle();

    expect(find.byKey(toggle), findsOneWidget);
    expect(find.byKey(input), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(input)).controller?.text,
      'nguyen',
    );
    // The bar was not rebuilt, so it did not grab focus again.
    expect(
      tester.widget<TextField>(find.byKey(input)).focusNode?.hasFocus,
      isFalse,
    );
    expect(_row1, findsOneWidget);
    expect(_row2, findsNothing);
  });
}
