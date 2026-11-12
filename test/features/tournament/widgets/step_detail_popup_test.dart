import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/tournament_step_summary.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/results_match_board.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/step_detail_popup.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _lateTarget = StepTarget(
  StepHubTab.results,
  resultsFilter: ResultsBoardFilter.unfinished,
);

StepProgress _step(
  StepKey key,
  StepStatus state, {
  List<StepTodo> todos = const [],
  int percent = 40,
}) => StepProgress(key: key, state: state, percent: percent, todos: todos);

StepDivisionRow _division(String id, {bool missing = false}) => StepDivisionRow(
  id: id,
  name: 'Division $id',
  missing: missing,
  target: StepTarget(StepHubTab.bracket, divisionId: id),
);

class _Launcher extends StatelessWidget {
  const _Launcher({
    required this.step,
    required this.summary,
    this.onGo,
    this.onRetry,
  });

  final StepKey step;
  final StepSummary summary;
  final ValueChanged<StepTarget>? onGo;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        key: const ValueKey('launch'),
        onPressed: () => showStepDetailPopup(
          context,
          step: step,
          summary: summary,
          onGo: onGo ?? (_) {},
          onRetry: onRetry,
        ),
        child: const Text('open'),
      ),
    ),
  );
}

Future<void> _open(
  WidgetTester tester, {
  required StepKey step,
  required List<StepProgress> steps,
  List<StepDivisionRow> divisions = const [],
  ValueChanged<StepTarget>? onGo,
  VoidCallback? onRetry,
}) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: _Launcher(
        step: step,
        summary: StepSummary(steps: steps, divisions: divisions),
        onGo: onGo,
        onRetry: onRetry,
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('launch')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TC-STEP-09 lists the todos of the step with their counts', (
    tester,
  ) async {
    await _open(
      tester,
      step: StepKey.inProgress,
      steps: [
        _step(
          StepKey.inProgress,
          StepStatus.attention,
          todos: const [
            StepTodo(
              key: 'late',
              labelKey: 'late',
              count: 2,
              target: _lateTarget,
            ),
            StepTodo(
              key: 'disputed',
              labelKey: 'disputed',
              count: 1,
              target: StepTarget(StepHubTab.results),
            ),
          ],
        ),
      ],
    );

    expect(find.text('Đang thi đấu'), findsWidgets);
    expect(find.text('2 trận trễ giờ'), findsOneWidget);
    expect(find.text('1 trận tranh chấp'), findsOneWidget);
    expect(find.text('Cần chú ý · 2 việc cần làm'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
  });

  testWidgets('TC-STEP-10 "Đi tới" closes the popup and returns the target', (
    tester,
  ) async {
    StepTarget? went;
    await _open(
      tester,
      step: StepKey.inProgress,
      steps: [
        _step(
          StepKey.inProgress,
          StepStatus.attention,
          todos: const [
            StepTodo(
              key: 'late',
              labelKey: 'late',
              count: 2,
              target: _lateTarget,
            ),
          ],
        ),
      ],
      onGo: (target) => went = target,
    );

    await tester.tap(find.byKey(const ValueKey('step-popup-go-late')));
    await tester.pumpAndSettle();

    expect(went?.tab, StepHubTab.results);
    expect(went?.resultsFilter, ResultsBoardFilter.unfinished);
    expect(find.byKey(const ValueKey('step-popup-body')), findsNothing);
  });

  testWidgets('TC-STEP-11 a step with nothing to do says it is complete', (
    tester,
  ) async {
    await _open(
      tester,
      step: StepKey.registration,
      steps: [_step(StepKey.registration, StepStatus.done, percent: 100)],
    );

    expect(find.text('Đã đủ, không còn việc cần làm'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('TC-STEP-12 a step not reached yet has no action buttons', (
    tester,
  ) async {
    await _open(
      tester,
      step: StepKey.completed,
      steps: [_step(StepKey.completed, StepStatus.upcoming, percent: 0)],
    );

    expect(
      find.text('Chưa tới bước này, chưa có việc cần làm'),
      findsOneWidget,
    );
    expect(find.text('Đi tới'), findsNothing);
    expect(find.text('Tải lại'), findsNothing);
  });

  testWidgets('TC-STEP-13 "Chỉ hiện thiếu" filters long division lists', (
    tester,
  ) async {
    StepTarget? went;
    await _open(
      tester,
      step: StepKey.schedule,
      steps: [_step(StepKey.schedule, StepStatus.attention)],
      divisions: [
        _division('a', missing: true),
        for (final id in ['b', 'c', 'd', 'e', 'f']) _division(id),
      ],
      onGo: (target) => went = target,
    );

    // Something is missing, so the list opens filtered to it.
    expect(find.text('Division a'), findsOneWidget);
    expect(find.text('Division b'), findsNothing);

    await tester.tap(find.text('Tất cả (6)'));
    await tester.pumpAndSettle();
    expect(find.text('Division b'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('step-popup-search')),
      'division e',
    );
    await tester.pumpAndSettle();
    expect(find.text('Division e'), findsOneWidget);
    expect(find.text('Division b'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('step-popup-open-e')));
    await tester.pumpAndSettle();
    expect(went?.tab, StepHubTab.bracket);
    expect(went?.divisionId, 'e');
  });

  testWidgets('TC-STEP-13b loading shows the loading note, retry reloads', (
    tester,
  ) async {
    await _open(
      tester,
      step: StepKey.registration,
      steps: [_step(StepKey.registration, StepStatus.loading, percent: 0)],
    );
    expect(find.text('Đang tải số liệu'), findsOneWidget);
    expect(find.text('0%'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tournament-edit-sheet-close')));
    await tester.pumpAndSettle();

    var retried = 0;
    await _open(
      tester,
      step: StepKey.schedule,
      steps: [
        _step(
          StepKey.schedule,
          StepStatus.attention,
          percent: 0,
          todos: const [
            StepTodo(
              key: 'loadFailed',
              labelKey: 'loadFailed',
              retry: true,
              target: StepTarget(StepHubTab.overview),
            ),
          ],
        ),
      ],
      onRetry: () => retried++,
    );
    await tester.tap(find.byKey(const ValueKey('step-popup-go-loadFailed')));
    await tester.pumpAndSettle();
    expect(retried, 1);
    expect(find.byKey(const ValueKey('step-popup-body')), findsNothing);
  });
}
