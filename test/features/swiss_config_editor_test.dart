import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/swiss_config_editor.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = SwissConfig(
  totalRounds: 4,
  tiebreakOrder: [
    SwissTiebreak.buchholz,
    SwissTiebreak.pointDiff,
    SwissTiebreak.headToHead,
    SwissTiebreak.seed,
  ],
  firstRoundPairing: 'SEED',
);

Widget _host(
  List<SwissConfig> emitted, {
  SwissConfig value = _base,
  int teamCount = 16,
  int minPlayedRounds = 0,
  double width = 360,
}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('vi'),
  // Plain theme: AppTheme loads google_fonts assets, unavailable in tests.
  // InkRipple: the default InkSparkle needs a shader asset (--no-test-assets).
  theme: ThemeData.light().copyWith(splashFactory: InkRipple.splashFactory),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: SwissConfigEditor(
            value: value,
            teamCount: teamCount,
            minPlayedRounds: minPlayedRounds,
            onChanged: emitted.add,
          ),
        ),
      ),
    ),
  ),
);

Future<void> _pump(WidgetTester tester, Widget host) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(host);
}

Future<void> _enterRounds(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('swiss-config-rounds')), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  testWidgets('rounds above the allowed maximum are clamped down', (
    tester,
  ) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted, teamCount: 8));

    await _enterRounds(tester, '99');

    expect(emitted.last.totalRounds, 7); // max(1, teamCount - 1)
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('typing alone (no submit, no focus change) already emits', (
    tester,
  ) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted));

    await tester.enterText(find.byKey(const Key('swiss-config-rounds')), '6');
    await tester.pump();

    expect(emitted.last.totalRounds, 6);
  });

  testWidgets('typing a value below the played rounds emits the clamped one', (
    tester,
  ) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted, minPlayedRounds: 3));

    await tester.enterText(find.byKey(const Key('swiss-config-rounds')), '1');
    await tester.pump();

    expect(emitted.last.totalRounds, 3);
    // The field is not rewritten mid-typing, so "12" can still be typed.
    await tester.enterText(find.byKey(const Key('swiss-config-rounds')), '12');
    await tester.pump();
    expect(emitted.last.totalRounds, 12);
  });

  testWidgets('zero is clamped up to one round', (tester) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted));

    await _enterRounds(tester, '0');

    expect(emitted.last.totalRounds, 1);
  });

  testWidgets('empty input restores the previous value without emitting', (
    tester,
  ) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted));

    await _enterRounds(tester, '');

    expect(emitted, isEmpty);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('value below the played rounds is clamped up with a hint', (
    tester,
  ) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted, minPlayedRounds: 3));

    await _enterRounds(tester, '2');

    expect(emitted.every((c) => c.totalRounds != 2), isTrue);
    expect(emitted.last.totalRounds, 3);
    expect(find.text('Không thể giảm dưới 3 vòng đã ghép'), findsOneWidget);
  });

  testWidgets('first round pairing can be switched to random', (tester) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted));

    await tester.tap(find.byKey(const Key('swiss-config-first-random')));
    await tester.pump();

    expect(emitted.last.firstRoundPairing, 'RANDOM');
  });

  testWidgets('Down and Up buttons reorder the enabled tiebreaks', (
    tester,
  ) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted));

    await tester.tap(find.byKey(const Key('swiss-tiebreak-down-BUCHHOLZ')));
    await tester.pump();
    expect(emitted.last.tiebreakOrder, [
      SwissTiebreak.pointDiff,
      SwissTiebreak.buchholz,
      SwissTiebreak.headToHead,
      SwissTiebreak.seed,
    ]);

    await tester.tap(find.byKey(const Key('swiss-tiebreak-up-BUCHHOLZ')));
    await tester.pump();
    expect(emitted.last.tiebreakOrder, _base.tiebreakOrder);
  });

  testWidgets('dragging a handle reorders the list', (tester) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted));

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const Key('swiss-tiebreak-handle-POINT_DIFF')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, -25));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();

    expect(emitted.last.tiebreakOrder.first, SwissTiebreak.pointDiff);
    expect(emitted.last.tiebreakOrder, hasLength(4));
  });

  testWidgets('switching a criterion off removes it from the order', (
    tester,
  ) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted));

    await tester.tap(find.byKey(const Key('swiss-tiebreak-switch-BUCHHOLZ')));
    await tester.pump();

    expect(emitted.last.tiebreakOrder, isNot(contains(SwissTiebreak.buchholz)));
    expect(emitted.last.tiebreakOrder, hasLength(3));
  });

  testWidgets('a disabled criterion can be switched back on', (tester) async {
    final emitted = <SwissConfig>[];
    await _pump(tester, _host(emitted));

    await tester.tap(find.byKey(const Key('swiss-tiebreak-switch-WINS')));
    await tester.pump();

    expect(emitted.last.tiebreakOrder, contains(SwissTiebreak.wins));
  });

  testWidgets('flat: no Card, one icon kind, no overflow at 320 dp', (
    tester,
  ) async {
    await _pump(tester, _host(<SwissConfig>[], width: 320));

    expect(find.byType(Card), findsNothing);
    final icons = tester
        .widgetList<Icon>(find.byType(Icon))
        .map((icon) => icon.icon)
        .toSet();
    expect(icons, {Icons.drag_indicator});
    expect(tester.takeException(), isNull);
  });
}
