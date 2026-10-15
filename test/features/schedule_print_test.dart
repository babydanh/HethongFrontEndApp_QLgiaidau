import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
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
      ],
    },
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MatchModel _live() => MatchModel.fromJson({
  'id': 'm1',
  'tournamentId': 't-1',
  'round': 1,
  'matchNumber': 1,
  'status': 'ONGOING',
  'team1Name': 'Đội A',
  'team2Name': 'Đội B',
  'courtName': 'Sân 1',
  'scheduledAt': DateTime(2026, 10, 24, 7, 0).toIso8601String(),
}, 'm1');

Future<int> _pump(WidgetTester tester) async {
  var prints = 0;
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
              matches: [_live()],
              scheduleSettings: const {
                'operatingStart': '07:00',
                'operatingEnd': '08:00',
                'minutesPerSet': 15,
              },
              onTapMatch: (_) {},
              onPrint: () async => prints++,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return prints;
}

void main() {
  testWidgets('the toolbar has a print action wired to the injected printer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final before = await _pump(tester);
    expect(before, 0);

    final printButton = find.byKey(const ValueKey('schedule-print-button'));
    expect(printButton, findsOneWidget);
    expect(printButton.hitTestable(), findsOneWidget);

    await tester.tap(printButton);
    await tester.pumpAndSettle();
  });

  testWidgets('the print action runs once per tap', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var prints = 0;
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
                matches: [_live()],
                scheduleSettings: const {
                  'operatingStart': '07:00',
                  'operatingEnd': '08:00',
                },
                onTapMatch: (_) {},
                onPrint: () async => prints++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('schedule-print-button')));
    await tester.pumpAndSettle();
    expect(prints, 1);
  });
}
