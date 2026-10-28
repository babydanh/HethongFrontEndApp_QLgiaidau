import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/shared/widgets/search_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _VenuesRepository implements TournamentManagementRepository {
  @override
  Future<List<Map<String, dynamic>>> getVenues(String id) async => [
    {
      'id': 'venue-1',
      'name': 'Nhà thi đấu',
      'courts': [
        {'id': 'court-1', 'name': 'Sân 1'},
        {'id': 'court-2', 'name': 'Sân 2'},
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MatchModel _match(
  String id, {
  required String a,
  required String b,
  String? court,
  DateTime? at,
  String? aId,
  String? division,
}) => MatchModel.fromJson({
  'id': id,
  'tournamentId': 't-1',
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': a,
  'team2Name': b,
  'team1Id': ?aId,
  'courtName': ?court,
  if (court != null) 'courtId': court == 'Sân 1' ? 'court-1' : 'court-2',
  if (at != null) 'scheduledAt': at.toIso8601String(),
  'divisionId': ?division,
}, id);

final _day = DateTime(2026, 10, 24);

// m1 and m2 share participant p1 at the same time on two courts: a conflict.
final _matches = [
  _match(
    'm1',
    a: 'Nguyễn Văn A',
    b: 'Trần B',
    court: 'Sân 1',
    at: _day.add(const Duration(hours: 7, minutes: 30)),
    aId: 'p1',
    division: 'd1',
  ),
  _match(
    'm2',
    a: 'Nguyễn Văn A',
    b: 'Phạm D',
    court: 'Sân 2',
    at: _day.add(const Duration(hours: 7, minutes: 30)),
    aId: 'p1',
    division: 'd2',
  ),
  _match(
    'm3',
    a: 'Lê Văn C',
    b: 'Hoàng E',
    court: 'Sân 1',
    at: _day.add(const Duration(hours: 9)),
    aId: 'p3',
    division: 'd1',
  ),
  _match('m4', a: 'Vũ F', b: 'Đặng G', division: 'd1'),
  // Next day: not on the grid shown by default.
  _match(
    'm5',
    a: 'Nguyễn Hải',
    b: 'Bùi K',
    court: 'Sân 1',
    at: _day.add(const Duration(days: 1, hours: 8)),
    aId: 'p5',
    division: 'd1',
  ),
];

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  double width = 900,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tournamentManagementRepositoryProvider.overrideWithValue(
          _VenuesRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: TournamentScheduleCourtGrid(
              tournamentId: 't-1',
              matches: _matches,
              divisions: const [
                (id: 'd1', name: 'Đôi nam'),
                (id: 'd2', name: 'Đôi nữ'),
              ],
              scheduleSettings: const {
                'operatingStart': '07:00',
                'operatingEnd': '10:00',
                'minutesPerSet': 15,
              },
              onTapMatch: (_) {},
              onScheduleDrop: (_, _, _, _) {},
              onPrint: () async {},
              onOpenScheduleSettings: () {},
              onOpenFullscreen: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(Scaffold)));
}

const _key = 't-1:schedule';

/// A grid card is dimmed when its always-present AnimatedOpacity is below 1.
bool _dimmed(WidgetTester tester, String id) =>
    tester
        .widget<AnimatedOpacity>(
          find.byKey(ValueKey('schedule-card-opacity-$id')),
        )
        .opacity <
    1;

void main() {
  testWidgets('search icon opens the bar; no card is dimmed without a query', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('search-filter-toggle')), findsOneWidget);
    expect(find.byKey(const ValueKey('search-filter-input')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('search-filter-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('search-filter-input')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('search-filter-group-court')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('search-filter-group-division')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('search-filter-group-status')),
      findsOneWidget,
    );
    expect(_dimmed(tester, 'm1'), isFalse);
    expect(find.text('4 kết quả'), findsOneWidget);
  });

  testWidgets('print and export live in the more menu, not the toolbar', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('schedule-print-button')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('schedule-more-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schedule-print-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('schedule-export-button')),
      findsOneWidget,
    );
  });

  testWidgets('typing without accents dims non-matching cards in place', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('search-filter-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('search-filter-input')),
      'nguyen van',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(searchFilterProvider(_key)).query, 'nguyen van');
    await tester.pumpAndSettle();

    expect(_dimmed(tester, 'm1'), isFalse);
    expect(_dimmed(tester, 'm2'), isFalse);
    expect(_dimmed(tester, 'm3'), isTrue);
    expect(find.text('2 kết quả'), findsOneWidget);
    // Dimmed cards keep their place.
    expect(find.text('Lê Văn C'), findsOneWidget);
  });

  testWidgets('court filter keeps only that court highlighted', (tester) async {
    final container = await _pump(tester);
    container
        .read(searchFilterProvider(_key).notifier)
        .setFilter('court', 'Sân 2');
    await tester.pumpAndSettle();
    expect(_dimmed(tester, 'm2'), isFalse);
    expect(_dimmed(tester, 'm1'), isTrue);
    expect(_dimmed(tester, 'm3'), isTrue);
  });

  testWidgets('conflict status filter highlights the clashing pair', (
    tester,
  ) async {
    final container = await _pump(tester);
    container
        .read(searchFilterProvider(_key).notifier)
        .setFilter('status', 'conflict');
    await tester.pumpAndSettle();
    expect(_dimmed(tester, 'm1'), isFalse);
    expect(_dimmed(tester, 'm2'), isFalse);
    expect(_dimmed(tester, 'm3'), isTrue);
  });

  testWidgets('unscheduled filter dims the whole grid and keeps the tray row', (
    tester,
  ) async {
    final container = await _pump(tester);
    container
        .read(searchFilterProvider(_key).notifier)
        .setFilter('status', 'unscheduled');
    await tester.pumpAndSettle();
    expect(_dimmed(tester, 'm1'), isTrue);
    expect(_dimmed(tester, 'm3'), isTrue);
    expect(find.textContaining('Vũ F'), findsWidgets);
  });

  testWidgets('no match shows 0 results and clear resets the dimming', (
    tester,
  ) async {
    final container = await _pump(tester);
    container.read(searchFilterProvider(_key).notifier).setQuery('zzzz');
    container.read(searchFilterProvider(_key).notifier).setOpen(true);
    await tester.pumpAndSettle();
    expect(find.text('0 kết quả'), findsOneWidget);
    expect(_dimmed(tester, 'm1'), isTrue);

    await tester.tap(find.byKey(const ValueKey('search-filter-clear-all')));
    await tester.pumpAndSettle();
    expect(_dimmed(tester, 'm1'), isFalse);
  });

  testWidgets('toolbar and open bar do not overflow at 320dp', (tester) async {
    final container = await _pump(tester, width: 320);
    container.read(searchFilterProvider(_key).notifier)
      ..setQuery('nguyen')
      ..setFilter('court', 'Sân 2')
      ..setOpen(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a filter value that is no longer offered does not filter', (
    tester,
  ) async {
    final container = await _pump(tester);
    container
        .read(searchFilterProvider(_key).notifier)
        .setFilter('court', 'Sân 9');
    container.read(searchFilterProvider(_key).notifier).setOpen(true);
    await tester.pumpAndSettle();
    expect(_dimmed(tester, 'm1'), isFalse);
    expect(_dimmed(tester, 'm3'), isFalse);
    expect(find.byKey(const ValueKey('search-filter-clear-all')), findsNothing);
    expect(container.read(searchFilterProvider(_key)).selected, isEmpty);
  });

  testWidgets('result count covers what is on screen, rest is reported', (
    tester,
  ) async {
    final container = await _pump(tester);
    container.read(searchFilterProvider(_key).notifier)
      ..setQuery('nguyen')
      ..setOpen(true);
    await tester.pumpAndSettle();
    // m1 and m2 are on the shown day; m5 is on the next day.
    expect(find.text('2 kết quả'), findsOneWidget);
    expect(find.text('1 kết quả ở ngày hoặc sân đang ẩn'), findsOneWidget);
  });
}
