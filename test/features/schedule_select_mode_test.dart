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

MatchModel _scheduled() => MatchModel.fromJson({
  'id': 'm1',
  'tournamentId': 't-1',
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': 'Đội A',
  'team2Name': 'Đội B',
  'courtName': 'Sân 1',
  'durationMinutes': 30,
  'scheduledAt': DateTime(2026, 10, 24, 7, 0).toIso8601String(),
}, 'm1');

/// Returns the recorded bulk-duration calls as "ids:minutes" strings.
Future<List<String>> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final bulk = <String>[];
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
              matches: [_scheduled()],
              scheduleSettings: const {
                'operatingStart': '07:00',
                'operatingEnd': '09:00',
              },
              onTapMatch: (_) {},
              onBulkDuration: (matches, minutes) =>
                  bulk.add('${matches.map((m) => m.id).join(',')}:$minutes'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bulk;
}

void main() {
  testWidgets(
    'select mode shows a hint, then the bulk bar right above the grid',
    (tester) async {
      await _pump(tester);
      expect(find.byKey(const ValueKey('schedule-select-hint')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('schedule-select-mode-button')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('schedule-select-hint')),
        findsOneWidget,
      );

      // Card start cell, then a later empty cell: the area covers the match.
      await tester.tap(find.byKey(const ValueKey('schedule-match-m1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('schedule-slot-Sân 1-3')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('schedule-select-hint')), findsNothing);
      expect(
        find.byKey(const ValueKey('schedule-bulk-duration-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('schedule-range-highlight')),
        findsOneWidget,
      );
      // The bar sits above the grid so it is always in view.
      final barTop = tester
          .getTopLeft(
            find.byKey(const ValueKey('schedule-bulk-duration-button')),
          )
          .dy;
      final gridTop = tester
          .getTopLeft(find.byKey(const ValueKey('schedule-match-m1')))
          .dy;
      expect(barTop, lessThan(gridTop));
    },
  );

  testWidgets('the clear button drops the selection and its highlight', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('schedule-select-mode-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedule-slot-Sân 1-3')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('schedule-range-highlight')),
      findsOneWidget,
    );

    // The ✕ now sits on the selection itself, not in the bulk bar.
    await tester.tap(find.byKey(const ValueKey('schedule-range-clear')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('schedule-range-highlight')),
      findsNothing,
    );
  });

  testWidgets('the clear button appears on the cell the finger lands on', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('schedule-select-mode-button')));
    await tester.pumpAndSettle();

    // Tap mode: the ✕ sits on the last tapped cell (row 3), not a fixed corner.
    await tester.tap(find.byKey(const ValueKey('schedule-slot-Sân 1-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('schedule-slot-Sân 1-4')));
    await tester.pumpAndSettle();
    final clear = find.byKey(const ValueKey('schedule-range-clear'));
    expect(
      tester
          .getRect(find.byKey(const ValueKey('schedule-slot-Sân 1-4')))
          .contains(tester.getCenter(clear)),
      isTrue,
    );
  });

  testWidgets('after a long-press drag the clear button follows the finger', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('schedule-select-mode-button')));
    await tester.pumpAndSettle();

    Future<void> hold(int from, int to) async {
      final start = tester.getCenter(
        find.byKey(ValueKey('schedule-slot-Sân 1-$from')),
      );
      final end = tester.getCenter(
        find.byKey(ValueKey('schedule-slot-Sân 1-$to')),
      );
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 700));
      await gesture.moveTo(end);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    final clear = find.byKey(const ValueKey('schedule-range-clear'));
    Rect slot(int i) =>
        tester.getRect(find.byKey(ValueKey('schedule-slot-Sân 1-$i')));

    // Dragging down ends on row 5: the ✕ is on row 5.
    await hold(2, 5);
    expect(slot(5).contains(tester.getCenter(clear)), isTrue);

    // Dragging back up ends on row 2: the ✕ moves to row 2 with the finger.
    await tester.tap(clear);
    await tester.pumpAndSettle();
    await hold(5, 2);
    expect(slot(2).contains(tester.getCenter(clear)), isTrue);
  });

  testWidgets('turning select mode off clears the selection', (tester) async {
    await _pump(tester);
    final toggle = find.byKey(const ValueKey('schedule-select-mode-button'));
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedule-slot-Sân 1-3')));
    await tester.pumpAndSettle();

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('schedule-range-highlight')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('schedule-select-hint')), findsNothing);
  });

  testWidgets('dragging a card handle sets that one match duration', (
    tester,
  ) async {
    final bulk = await _pump(tester);

    await tester.drag(
      find.byKey(const ValueKey('schedule-resize-handle-m1')),
      const Offset(0, 112),
    );
    await tester.pumpAndSettle();

    expect(bulk, ['m1:45']);
  });
}
