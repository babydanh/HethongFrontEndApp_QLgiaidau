import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/schedule_grid.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MatchModel _match({String status = 'SCHEDULED', int duration = 30}) =>
    MatchModel.fromJson({
      'id': 'm-1',
      'tournamentId': 't-1',
      'round': 1,
      'matchNumber': 1,
      'status': status,
      'team1Name': 'Đội A',
      'team2Name': 'Đội B',
      'courtName': 'Sân 1',
      'durationMinutes': duration,
      'scheduledAt': DateTime(2026, 10, 24, 7, 0).toIso8601String(),
    }, 'm-1');

Future<void> _pump(
  WidgetTester tester, {
  List<MatchModel> matches = const [],
  bool selectMode = false,
  ScheduleRange? selectedRange,
  void Function(ScheduleRange range)? onRangeSelected,
  void Function(MatchModel match, int minutes)? onResizeMatch,
}) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      // The live dot pulses forever; keep it still so pumpAndSettle ends.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child ?? const SizedBox.shrink(),
      ),
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ScheduleGrid(
            courts: const ['Sân 1', 'Sân 2'],
            matches: matches,
            startHour: 7,
            endHour: 10,
            day: DateTime(2026, 10, 24),
            onTapMatch: (_) {},
            onDropMatch: (_, _, _) {},
            selectMode: selectMode,
            selectedRange: selectedRange,
            onRangeSelected: onRangeSelected,
            onResizeMatch: onResizeMatch,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('select mode: tapping a first and a last cell selects the box', (
    tester,
  ) async {
    final ranges = <ScheduleRange>[];
    await _pump(tester, selectMode: true, onRangeSelected: ranges.add);

    await tester.tap(find.byKey(const ValueKey('schedule-slot-Sân 1-1')));
    await tester.pump();
    // The first tap already marks that single cell.
    expect(ranges.last.firstSlot, 1);
    expect(ranges.last.lastSlot, 1);

    await tester.tap(find.byKey(const ValueKey('schedule-slot-Sân 2-3')));
    await tester.pump();
    expect(ranges.last.firstCourt, 0);
    expect(ranges.last.lastCourt, 1);
    expect(ranges.last.firstSlot, 1);
    expect(ranges.last.lastSlot, 3);

    // A third tap starts a new selection instead of extending the old one.
    await tester.tap(find.byKey(const ValueKey('schedule-slot-Sân 2-5')));
    await tester.pump();
    expect(ranges.last.firstSlot, 5);
    expect(ranges.last.lastSlot, 5);
    expect(ranges.last.firstCourt, 1);
  });

  testWidgets('without select mode a cell tap does not select', (tester) async {
    final ranges = <ScheduleRange>[];
    await _pump(tester, onRangeSelected: ranges.add);

    await tester.tap(find.byKey(const ValueKey('schedule-slot-Sân 1-1')));
    await tester.pump();
    expect(ranges, isEmpty);
  });

  testWidgets('the selected range is painted as a highlight', (tester) async {
    await _pump(tester);
    expect(
      find.byKey(const ValueKey('schedule-range-highlight')),
      findsNothing,
    );

    await _pump(
      tester,
      selectedRange: (firstCourt: 0, lastCourt: 1, firstSlot: 1, lastSlot: 2),
    );
    // One highlight per covered court column.
    expect(
      find.byKey(const ValueKey('schedule-range-highlight')),
      findsNWidgets(2),
    );
  });

  testWidgets('dragging the bottom handle of a card resizes by whole steps', (
    tester,
  ) async {
    final calls = <(String, int)>[];
    await _pump(
      tester,
      matches: [_match()],
      onResizeMatch: (match, minutes) => calls.add((match.id, minutes)),
    );

    final handle = find.byKey(const ValueKey('schedule-resize-handle-m-1'));
    expect(handle, findsOneWidget);

    // 112dp = one 15-minute step: 30 -> 45.
    await tester.drag(handle, const Offset(0, 112));
    await tester.pumpAndSettle();
    expect(calls, [('m-1', 45)]);
  });

  testWidgets('dragging the handle up shortens but never below one step', (
    tester,
  ) async {
    final calls = <(String, int)>[];
    await _pump(
      tester,
      matches: [_match()],
      onResizeMatch: (match, minutes) => calls.add((match.id, minutes)),
    );

    await tester.drag(
      find.byKey(const ValueKey('schedule-resize-handle-m-1')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(calls, [('m-1', 15)]);
  });

  testWidgets('a drag that rounds to the same duration reports nothing', (
    tester,
  ) async {
    final calls = <(String, int)>[];
    await _pump(
      tester,
      matches: [_match()],
      onResizeMatch: (match, minutes) => calls.add((match.id, minutes)),
    );

    await tester.drag(
      find.byKey(const ValueKey('schedule-resize-handle-m-1')),
      const Offset(0, 20),
    );
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
  });

  testWidgets('a live match has no resize handle', (tester) async {
    await _pump(
      tester,
      matches: [_match(status: 'ONGOING')],
      onResizeMatch: (_, _) {},
    );
    expect(
      find.byKey(const ValueKey('schedule-resize-handle-m-1')),
      findsNothing,
    );
  });
}
