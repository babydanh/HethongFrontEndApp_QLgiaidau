import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_repository.dart';
import 'package:app_quanly_giaidau/features/bracket/screens/swiss_pairing_screen.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ITournamentRepository {}

SwissPreviewParticipant _p(String id, {num points = 1}) =>
    SwissPreviewParticipant(
      id: id,
      teamName: 'Team $id',
      totalPoints: points,
      buchholz: 0,
      hadBye: false,
    );

/// [pairCount] pairs p0a/p0b ..., optional BYE, optional unplaced people.
SwissPreview _preview({
  int pairCount = 2,
  bool bye = true,
  List<String> pool = const [],
  List<SwissWarning> warnings = const [],
}) {
  final ids = <String>[];
  final pairs = <SwissPreviewPair>[];
  for (var i = 0; i < pairCount; i++) {
    ids
      ..add('a$i')
      ..add('b$i');
    pairs.add(
      SwissPreviewPair(
        board: i + 1,
        participant1Id: 'a$i',
        participant2Id: 'b$i',
      ),
    );
  }
  if (bye) ids.add('bye');
  ids.addAll(pool);
  return SwissPreview(
    roundNumber: 3,
    totalRounds: 5,
    pairs: pairs,
    byeParticipantId: bye ? 'bye' : null,
    sitOutParticipantIds: const [],
    participants: [for (final id in ids) _p(id)],
    warnings: warnings,
  );
}

late _MockRepo _repo;

Widget _host() => ProviderScope(
  overrides: [tournamentRepositoryProvider.overrideWithValue(_repo)],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    // Plain theme + InkRipple: AppTheme needs google_fonts/shader assets.
    theme: ThemeData.light().copyWith(splashFactory: InkRipple.splashFactory),
    home: const SwissPairingScreen(
      tournamentId: 't1',
      divisionId: 'd1',
      stageId: 's1',
      roundNumber: 3,
      totalRounds: 5,
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  double width = 360,
  double height = 3200,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_host());
  await tester.pump(); // microtask: load preview
  await tester.pump();
}

void _stubPreview(SwissPreview preview) => when(
  () => _repo.swissPreview(
    any(),
    divisionId: any(named: 'divisionId'),
    stageId: any(named: 'stageId'),
  ),
).thenAnswer((_) async => preview);

Finder _slotText(String slot, String text) =>
    find.descendant(of: find.byKey(Key(slot)), matching: find.text(text));

void main() {
  setUpAll(() {
    registerFallbackValue(
      const SwissRoundDraftRequest(divisionId: 'd', pairs: []),
    );
  });

  setUp(() {
    _repo = _MockRepo();
    _stubPreview(_preview());
    when(() => _repo.swissValidate(any(), any())).thenAnswer(
      (_) async =>
          const SwissValidateResult(valid: true, errors: [], warnings: []),
    );
    when(
      () => _repo.swissNextRound(
        any(),
        any(),
        confirmWarnings: any(named: 'confirmWarnings'),
      ),
    ).thenAnswer(
      (_) async => const SwissNextRoundResult(roundNumber: 3, matchIds: []),
    );
  });

  testWidgets('12 pairs at 360 dp: flat, no overflow, one icon kind', (
    tester,
  ) async {
    _stubPreview(_preview(pairCount: 12));
    await _pump(tester);

    expect(find.byKey(const Key('swiss-pair-row-11')), findsOneWidget);
    expect(find.byKey(const Key('swiss-confirm')), findsOneWidget);
    expect(find.text('Xác nhận vòng 3'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    final icons = tester
        .widgetList<Icon>(find.byType(Icon))
        .map((icon) => icon.icon)
        .toSet();
    expect(icons, {Icons.drag_indicator});
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide screen: pool and pairs sit in two columns', (tester) async {
    await _pump(tester, width: 800, height: 1200);

    final pool = tester.getTopLeft(find.byKey(const Key('swiss-pool')));
    final row = tester.getTopLeft(find.byKey(const Key('swiss-pair-row-0')));
    expect(row.dx, greaterThan(pool.dx + 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow screen: a single column', (tester) async {
    await _pump(tester);

    final pool = tester.getTopLeft(find.byKey(const Key('swiss-pool')));
    final row = tester.getTopLeft(find.byKey(const Key('swiss-pair-row-0')));
    expect(row.dx, pool.dx);
    expect(row.dy, greaterThan(pool.dy));
  });

  testWidgets('tap a name, choose "Đổi với…", the two swap places', (
    tester,
  ) async {
    await _pump(tester);
    expect(_slotText('swiss-slot-0-1', 'Team a0'), findsOneWidget);
    expect(_slotText('swiss-slot-1-2', 'Team b1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('swiss-chip-a0')));
    await tester.pumpAndSettle();
    expect(find.text('Đổi với…'), findsOneWidget);
    expect(find.text('Chuyển tới…'), findsOneWidget);

    await tester.tap(find.byKey(const Key('swiss-swap-b1')));
    await tester.pumpAndSettle();

    expect(_slotText('swiss-slot-0-1', 'Team b1'), findsOneWidget);
    expect(_slotText('swiss-slot-1-2', 'Team a0'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    verify(() => _repo.swissValidate('t1', any())).called(1);
  });

  testWidgets('long-press drag onto another name swaps them', (tester) async {
    await _pump(tester);

    final from = tester.getCenter(find.byKey(const Key('swiss-chip-a0')));
    final to = tester.getCenter(find.byKey(const Key('swiss-slot-1-2')));
    final gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(to);
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_slotText('swiss-slot-0-1', 'Team b1'), findsOneWidget);
    expect(_slotText('swiss-slot-1-2', 'Team a0'), findsOneWidget);
  });

  testWidgets('unplaced people disable Confirm and show the count', (
    tester,
  ) async {
    _stubPreview(_preview(pool: ['x', 'y']));
    await _pump(tester);

    expect(find.text('Còn 2 đội chưa có chỗ'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('swiss-confirm')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('moving a name to "Chưa ghép" leaves its slot empty', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('swiss-chip-b1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swiss-move-pool')));
    await tester.pumpAndSettle();

    expect(find.text('Còn 2 đội chưa có chỗ'), findsOneWidget);
    expect(_slotText('swiss-slot-1-2', 'Thả vào đây'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('swiss-confirm')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('a rematch warning shows as text and relabels Confirm', (
    tester,
  ) async {
    _stubPreview(
      _preview(
        warnings: const [
          SwissWarning(type: 'REMATCH', participantIds: ['a1', 'b1'], round: 2),
        ],
      ),
    );
    await _pump(tester);

    expect(find.text('Đã gặp ở vòng 2'), findsOneWidget);
    expect(find.text('Xác nhận dù có cảnh báo'), findsOneWidget);
    expect(find.text('Xác nhận vòng 3'), findsNothing);
  });

  testWidgets('a hard validation error is shown and Confirm stays off', (
    tester,
  ) async {
    when(() => _repo.swissValidate(any(), any())).thenAnswer(
      (_) async => const SwissValidateResult(
        valid: false,
        errors: [SwissError(code: 'MISSING_PARTICIPANT', participantIds: [])],
        warnings: [],
      ),
    );
    await _pump(tester);
    await tester.tap(find.byKey(const Key('swiss-chip-a0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swiss-swap-a1')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Còn đội chưa được xếp'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('swiss-confirm')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('Confirm creates the round and shows the success message', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('swiss-confirm')));
    await tester.pump();
    await tester.pump();

    verify(
      () => _repo.swissNextRound('t1', any(), confirmWarnings: false),
    ).called(1);
    expect(find.text('Đã tạo vòng 3.'), findsOneWidget);
  });

  testWidgets('preview failure shows the coded message and a retry button', (
    tester,
  ) async {
    when(
      () => _repo.swissPreview(
        any(),
        divisionId: any(named: 'divisionId'),
        stageId: any(named: 'stageId'),
      ),
    ).thenThrow(
      const SwissApiException(status: 409, code: 'SWISS_ROUND_INCOMPLETE'),
    );
    await _pump(tester);

    expect(find.text('Vòng hiện tại chưa kết thúc'), findsOneWidget);
    expect(find.byKey(const Key('swiss-retry')), findsOneWidget);
    expect(find.byKey(const Key('swiss-pair-row-0')), findsNothing);
    expect(find.byKey(const Key('swiss-confirm')), findsNothing);
  });

  testWidgets(
    'a pair left with one side and an empty pool counts as 1 unplaced',
    (tester) async {
      await _pump(tester);

      await tester.tap(find.byKey(const Key('swiss-chip-b1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('swiss-move-sitout')));
      await tester.pumpAndSettle();

      expect(find.text('Còn 1 đội chưa có chỗ'), findsOneWidget);
    },
  );

  testWidgets('SWISS_TOURNAMENT_CLOSED has its own message', (tester) async {
    when(
      () => _repo.swissPreview(
        any(),
        divisionId: any(named: 'divisionId'),
        stageId: any(named: 'stageId'),
      ),
    ).thenThrow(
      const SwissApiException(status: 409, code: 'SWISS_TOURNAMENT_CLOSED'),
    );
    await _pump(tester);

    expect(
      find.text('Giải đã kết thúc hoặc đã hủy, không thể đổi vòng'),
      findsOneWidget,
    );
  });

  testWidgets('an unknown error code falls back to the generic message', (
    tester,
  ) async {
    when(
      () => _repo.swissPreview(
        any(),
        divisionId: any(named: 'divisionId'),
        stageId: any(named: 'stageId'),
      ),
    ).thenThrow(const SwissApiException(status: 500, code: 'SOMETHING_NEW'));
    await _pump(tester);

    expect(find.text('Có lỗi xảy ra. Vui lòng thử lại'), findsOneWidget);
  });

  testWidgets('a validate network failure offers a retry that re-validates', (
    tester,
  ) async {
    var calls = 0;
    when(() => _repo.swissValidate(any(), any())).thenAnswer((_) async {
      if (calls++ == 0) throw const SwissApiException();
      return const SwissValidateResult(valid: true, errors: [], warnings: []);
    });
    await _pump(tester);
    await tester.tap(find.byKey(const Key('swiss-chip-a0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('swiss-swap-a1')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('swiss-revalidate')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('swiss-confirm')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('swiss-revalidate')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('swiss-revalidate')), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('swiss-confirm')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('the screen cannot be popped while the round is being created', (
    tester,
  ) async {
    final gate = Completer<SwissNextRoundResult>();
    when(
      () => _repo.swissNextRound(
        any(),
        any(),
        confirmWarnings: any(named: 'confirmWarnings'),
      ),
    ).thenAnswer((_) => gate.future);
    await _pump(tester);

    await tester.tap(find.byKey(const Key('swiss-confirm')));
    await tester.pump();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    final handled = await navigator.maybePop();
    await tester.pump();

    expect(handled, isTrue);
    expect(find.byKey(const Key('swiss-pairing-screen')), findsOneWidget);
  });
}
