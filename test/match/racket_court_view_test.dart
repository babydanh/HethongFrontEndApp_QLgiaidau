import 'package:app_quanly_giaidau/domain/services/racket_court_layout.dart';
import 'package:app_quanly_giaidau/features/match/utils/court_drag.dart';
import 'package:app_quanly_giaidau/features/match/utils/racket_court_drag.dart';
import 'package:app_quanly_giaidau/features/match/widgets/racket_court_view.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _team1 = ['Lan', 'Minh'];
const _team2 = ['Bao', 'Ha'];

class _Spy {
  final scores = <String>[];
  final drops = <CourtDropAction>[];
  final picks = <String>[];
  var undo = 0;
  var ends = 0;
  var menu = 0;
}

List<RacketCourtCell> _cells({bool doubles = true, int? server = 1}) =>
    racketCourtCells(
      serverTeam: server,
      serverRight: true,
      serverPlayerIndex: doubles && server != null ? 0 : null,
      doubles: doubles,
    );

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData.dark().copyWith(splashFactory: NoSplash.splashFactory),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

Widget _view(
  _Spy spy, {
  Axis axis = Axis.horizontal,
  bool interactive = true,
  bool doubles = true,
  bool flipped = false,
  bool canUndo = true,
  bool canPick = false,
  List<String> team1 = _team1,
  List<String> team2 = _team2,
}) {
  return RacketCourtView(
    cells: _cells(doubles: doubles),
    team1Players: team1,
    team2Players: team2,
    team1Name: 'Team One',
    team2Name: 'Team Two',
    endsFlipped: flipped,
    axis: axis,
    scoreText1: '15',
    scoreText2: '30',
    servingTeam: 1,
    call: '15-30',
    setText: 'Game 2-1',
    chips: const ['Set point'],
    canUndo: canUndo,
    onScore: interactive ? (team, inc) => spy.scores.add('$team:$inc') : null,
    onUndo: () => spy.undo++,
    onSwitchEnds: () => spy.ends++,
    onMenu: () => spy.menu++,
    onPickServer: canPick ? (t, p) => spy.picks.add('$t:$p') : null,
    resolve: (source, target) => racketResolveDrop(
      source: source,
      target: target,
      servingTeam: 1,
      isDoubles: doubles,
      isTennis: false,
      finished: false,
    ),
    onDrop: spy.drops.add,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget view, {
  Size size = const Size(900, 420),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(view));
  await tester.pump();
}

void main() {
  testWidgets('TC-RACKET-W-01 doubles shows four names', (tester) async {
    await _pump(tester, _view(_Spy()));
    for (final name in [..._team1, ..._team2]) {
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets('TC-RACKET-W-02 one GIAO tag and one NHAN outline', (
    tester,
  ) async {
    await _pump(tester, _view(_Spy()));
    expect(find.textContaining('SERVE'), findsOneWidget);
    expect(find.text('RECEIVE'), findsOneWidget);
  });

  testWidgets('TC-RACKET-W-03 singles shows two players on the diagonal', (
    tester,
  ) async {
    await _pump(
      tester,
      _view(_Spy(), doubles: false, team1: const ['Lan'], team2: const ['Bao']),
    );
    expect(find.text('Lan'), findsOneWidget);
    expect(find.text('Bao'), findsOneWidget);
    expect(find.text('Minh'), findsNothing);
    expect(find.text('RECEIVE'), findsOneWidget);
  });

  testWidgets('TC-RACKET-W-04 middle shows call and both scores', (
    tester,
  ) async {
    await _pump(tester, _view(_Spy()));
    expect(find.text('15-30'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('Game 2-1'), findsOneWidget);
    expect(find.text('Set point'), findsOneWidget);
  });

  testWidgets('TC-RACKET-W-05 plus and minus reach onScore per team', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final spy = _Spy();
    await _pump(tester, _view(spy));
    await tester.tap(find.bySemanticsLabel('Add point for team 1'));
    await tester.tap(find.bySemanticsLabel('Remove point for team 2'));
    expect(spy.scores, ['1:true', '2:false']);
    semantics.dispose();
  });

  testWidgets('TC-RACKET-W-06 undo is disabled when there is nothing to undo', (
    tester,
  ) async {
    final spy = _Spy();
    await _pump(tester, _view(spy, canUndo: false));
    await tester.tap(find.byKey(racketUndoKey));
    expect(spy.undo, 0);
    await _pump(tester, _view(spy));
    await tester.tap(find.byKey(racketUndoKey));
    expect(spy.undo, 1);
  });

  testWidgets('TC-RACKET-W-07 switch ends and menu buttons call back', (
    tester,
  ) async {
    final spy = _Spy();
    await _pump(tester, _view(spy));
    await tester.tap(find.byKey(racketEndsKey));
    await tester.tap(find.byKey(racketMenuKey));
    expect(spy.ends, 1);
    expect(spy.menu, 1);
  });

  testWidgets('TC-RACKET-W-08 tapping a player picks the first server', (
    tester,
  ) async {
    final spy = _Spy();
    await _pump(tester, _view(spy, canPick: true));
    await tester.tap(find.text('Ha'));
    await tester.pump();
    expect(spy.picks, ['2:1']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('TC-RACKET-W-09 tap offers swap places, then drops it', (
    tester,
  ) async {
    final spy = _Spy();
    await _pump(tester, _view(spy));
    await tester.tap(find.text('Ha'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    expect(spy.drops.single, isA<SwapPlaces>());
  });

  testWidgets('TC-RACKET-W-10 a viewer gets no buttons and no taps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final spy = _Spy();
    await _pump(tester, _view(spy, interactive: false));
    expect(find.byKey(racketUndoKey), findsNothing);
    expect(find.bySemanticsLabel('Add point for team 1'), findsNothing);
    await tester.tap(find.text('Ha'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(spy.drops, isEmpty);
    semantics.dispose();
  });

  testWidgets('TC-RACKET-W-11 flipped ends put team 2 on the first half', (
    tester,
  ) async {
    await _pump(tester, _view(_Spy()));
    final before = tester.getCenter(find.text('Lan')).dx;
    final beforeOther = tester.getCenter(find.text('Bao')).dx;
    expect(before, lessThan(beforeOther));
    await _pump(tester, _view(_Spy(), flipped: true));
    expect(
      tester.getCenter(find.text('Lan')).dx,
      greaterThan(tester.getCenter(find.text('Bao')).dx),
    );
  });

  testWidgets('TC-RACKET-W-12 team name shows when there is no player list', (
    tester,
  ) async {
    await _pump(
      tester,
      _view(_Spy(), team1: const [], team2: const [], doubles: false),
    );
    expect(find.text('Team One'), findsOneWidget);
    expect(find.text('Team Two'), findsOneWidget);
  });

  for (final entry in {
    'landscape 568x320': (const Size(568, 320), Axis.horizontal),
    'landscape 800x360': (const Size(800, 360), Axis.horizontal),
    'portrait 320x568': (const Size(320, 568), Axis.vertical),
    'portrait 390x700': (const Size(390, 700), Axis.vertical),
  }.entries) {
    testWidgets('TC-RACKET-W-13 no overflow at ${entry.key}', (tester) async {
      await _pump(
        tester,
        _view(_Spy(), axis: entry.value.$2),
        size: entry.value.$1,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
