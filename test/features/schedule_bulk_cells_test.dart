import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_schedule_court_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Cell = ({String courtId, String courtName, DateTime at});

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

MatchModel _placed({required int hour, required int minute, int? duration}) =>
    MatchModel.fromJson({
      'id': 'm-placed',
      'tournamentId': 't-1',
      'round': 1,
      'matchNumber': 1,
      'status': 'ONGOING',
      'team1Name': 'Đang đấu A',
      'team2Name': 'Đang đấu B',
      'courtName': 'Sân 1',
      'scheduledAt': DateTime(2026, 10, 24, hour, minute).toIso8601String(),
      if (duration != null) 'durationMinutes': duration,
    }, 'm-placed');

MatchModel _waiting(String id) => MatchModel.fromJson({
  'id': id,
  'tournamentId': 't-1',
  'round': 1,
  'matchNumber': 1,
  'status': 'SCHEDULED',
  'team1Name': 'Đội $id A',
  'team2Name': 'Đội $id B',
}, id);

/// Kéo chọn vùng từ ô [fromSlot] tới [toSlot] của Sân 1 rồi bấm nút xếp hàng loạt.
Future<({List<_Cell> cells, List<MatchModel> waiting})?> _selectRangeAndConfirm(
  WidgetTester tester, {
  required int fromSlot,
  required int toSlot,
  required int placedDuration,
}) async {
  ({List<_Cell> cells, List<MatchModel> waiting})? captured;

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
              matches: [
                _placed(hour: 7, minute: 0, duration: placedDuration),
                _waiting('w1'),
                _waiting('w2'),
              ],
              scheduleSettings: const {
                'operatingStart': '07:00',
                'operatingEnd': '08:00',
                'minutesPerSet': 15,
              },
              onTapMatch: (_) {},
              onScheduleDrop: (_, _, _, _) {},
              onBulkSchedule: (cells, waiting) =>
                  captured = (cells: cells, waiting: waiting),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final start = tester.getCenter(
    find.byKey(ValueKey('schedule-slot-Sân 1-$fromSlot')),
  );
  final end = tester.getCenter(
    find.byKey(ValueKey('schedule-slot-Sân 1-$toSlot')),
  );
  final gesture = await tester.startGesture(start);
  await tester.pump(const Duration(milliseconds: 700));
  await gesture.moveTo(end);
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.up();
  await tester.pumpAndSettle();

  final bulkFinder = find.byKey(
    const ValueKey('schedule-bulk-schedule-button'),
  );
  expect(bulkFinder, findsOneWidget);
  expect(
    tester.widget<FilledButton>(bulkFinder).onPressed,
    isNotNull,
    reason: 'vùng còn ô trống thì nút xếp lô phải bật',
  );
  await tester.tap(bulkFinder);
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  testWidgets('cells already covered by a long match are left out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Trận đang đấu 07:00 dài 45 phút, nên 07:15 và 07:30 vẫn bị chiếm.
    final captured = await _selectRangeAndConfirm(
      tester,
      fromSlot: 0,
      toSlot: 3,
      placedDuration: 45,
    );

    expect(captured, isNotNull);
    final times = [
      for (final cell in captured!.cells) '${cell.at.hour}:${cell.at.minute}',
    ];
    expect(times, ['7:45']);
    expect(captured.cells.single.courtName, 'Sân 1');
    expect(captured.cells.single.courtId, 'court-1');
    // Chỉ lấy đúng số trận vừa đủ cho số ô trống.
    expect(captured.waiting.map((m) => m.id), ['w1']);
  });

  testWidgets('a free range offers one cell per 15-minute slot', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Trận đang đấu 07:00 chỉ dài 15 phút -> 07:15 và 07:30 trống.
    final captured = await _selectRangeAndConfirm(
      tester,
      fromSlot: 0,
      toSlot: 2,
      placedDuration: 15,
    );

    expect(captured, isNotNull);
    final times = [
      for (final cell in captured!.cells) '${cell.at.hour}:${cell.at.minute}',
    ];
    expect(times, ['7:15', '7:30']);
    expect(captured.waiting.map((m) => m.id), ['w1', 'w2']);
  });
}
